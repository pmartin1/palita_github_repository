extends CharacterBody2D

# Modos principales
enum Modo { STANDING, CROUCHING, COPA }
var modo_actual: Modo = Modo.STANDING

# caracteristicas de movimiento
var speed := 0.0
var wspeedcount := 0.0
var speedmod := 20.0
var periodmod := 5.0
const phasemod = 1.5

# fisica de empuje
var external_push := Vector2.ZERO
var friction := 300.0
var pushing_planta := false
var push_dir: Vector2
var tossing := false
signal toss_triggered(jugador_ref)

# coordenadas de movimiento
var mov_target = Vector2.ZERO
var mov_direction = Vector2.ZERO
var prev_cardinal: String = get_direction_cardinal()
var new_cardinal: String = get_direction_cardinal()
var dir_cardinal: String = get_direction_cardinal()
var distance = position.distance_to(mov_target)

# estados/flags
var is_clicking := false
var mouse_en_jugador = false
var walking := false
var watering := false
var handling := false

# agua
var agua_counter := 0

# diccionarios
var collshape_original_positions := {}

# camara
@onready var main_camera: Camera2D = $Camera2D
var click_der_pressed := false
var camera_look_active := false
var click_start_time := 0.0
var time_since_click_der := 0.0
var required_hold_time := 1.0 # Seconds
var initial_click_world_pos: Vector2
var initial_click_viewport_pos: Vector2
var initial_player_world_pos: Vector2

# inicialización
func _ready():
	main_camera.make_current()
	collshape_original_positions = {
	"crouchN": $collpol_crouchN.position,
	"crouchS": $collpol_crouchS.position,
	"crouchE": $collpol_crouchE.position,
	"crouchO": $collpol_crouchO.position,
	"modo_copa": $collpol_modo_copa.position,
	"standing": $collsh_standing,
	}
	$collsh_standing.set_deferred("disabled", false)
	$standing_push_area.set_deferred("monitoring", true)
	$area_copa.set_deferred("monitoring", true)
	modo_actual = Modo.STANDING
	apply_modo_settings()
	animacion_idle()


#================================

# INPUT

#================================
# Eventos del input (project/project settings/input map)
# _unhandled_input: recomendado para gameplay (son acciones pisadas por UI)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("click_izq"):
		is_clicking = true
		if not watering or tossing:
			walk_start()

	elif event.is_action_released("click_izq"):
		is_clicking = false
		walk_stop()

	if event.is_action_pressed("click_der"):
		click_der_pressed = true
		click_start_time = Time.get_ticks_msec() / 1000.0
		initial_click_world_pos = get_global_mouse_position()
		initial_click_viewport_pos = main_camera.get_viewport().get_mouse_position()
		initial_player_world_pos = global_position

	if event.is_action_released("click_der"):
		click_der_pressed = false
		time_since_click_der = 0.0
		if not camera_look_active and not watering:
			toggle_crouch()

	if event.is_action_pressed("press_F_to_FLIP"):
		if modo_actual != Modo.CROUCHING:
			return
		tossing = true
		if is_clicking:
			walk_stop()
		var animacion_toss = "toss" + dir_cardinal
		$AnimatedSprite2D.play(animacion_toss)
		update_coll_mode("tossing")
		perform_toss()
	
	if event.is_action_released("press_F_to_FLIP"):
		if modo_actual != Modo.CROUCHING:
			return
		tossing = false
		var crouch_dir_cardinal = "crouch_idle_" + dir_cardinal
		$AnimatedSprite2D.play(crouch_dir_cardinal)
		# crouching coll mode
		update_coll_mode(dir_cardinal)
		if is_clicking:
			walk_start()
	
	if event.is_action_pressed("modo_riego"):
		if modo_actual != Modo.COPA:
			return
		walk_stop()
		watering = true
	
	if event.is_action_released("modo_riego"):
		if is_clicking and modo_actual == Modo.STANDING:
			walk_start()
		watering = false
		rotation = 0
	
	# zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			change_zoom(1)  # Zoom in
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			change_zoom(-1)   # Zoom out


#================================

# TRIGGERS MOVIMIENTO

#================================


func walk_start():
	walking = true
	mov_target = get_global_mouse_position()
	mov_direction = position.direction_to(mov_target)


func walk_stop():
	walking = false
	mov_target = global_position
	mov_direction = Vector2.ZERO
	speed = 0
	wspeedcount = 0
	animacion_idle()

# area que rodea al jugador
func _on_area_click_jugador_mouse_entered() -> void:
	mouse_en_jugador = true
	if not tossing or not watering:
		walk_stop()


func _on_area_click_jugador_mouse_exited() -> void:
	mouse_en_jugador = false
	if not tossing or not watering:
		if is_clicking:
			walk_start()

# señales de objetos interaccionables con el mouse (not GUI)
func _on_stop_player_movement():
	handling = true
	walk_stop()
	set_process_unhandled_input(false)


func _on_restore_player_movement():
	handling = false
	set_process_unhandled_input(true)


#================================

# MODOS

#================================


func modo_riego_tilt(delta):
	if not watering:
		return
	
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	var angle_from_up = Vector2.UP.angle_to(direction)  # relative to downward vector
	
	# Clamp the angle to a 180° arc centered on down (i.e., -PI/2 to PI/2)
	var clamped_angle = clamp(angle_from_up, -PI / 2, PI / 2)
	
	const DRAG_STRENGTH := 10
	rotation = lerp_angle(rotation, clamped_angle, delta * DRAG_STRENGTH)


func toggle_crouch():
	if watering:
		return
	
	if modo_actual != Modo.CROUCHING:
		modo_actual = Modo.CROUCHING
		apply_modo_settings()
		$area_base_pala.monitoring = true
	else:
		modo_actual = Modo.STANDING # revisar si no se buguea con el area copa
		apply_modo_settings()
		$area_base_pala.monitoring = false
	if not walking:
		animacion_idle()


#================================

# SEÑALES DEL CUERPO

#================================


func _on_standing_push_area_body_entered(body: Node2D) -> void:
	if modo_actual != Modo.STANDING:
		return
	if body is mugre:
		push_dir = (body.global_position - global_position).normalized()
		body.apply_impulse(push_dir * 0.2)
	

	if body is planta and not body.planta_arrancada:
		push_dir = (body.global_position - global_position).normalized()
		body.apply_impulse(push_dir * 10.0)
		# Optional: If you want recoil, push the player too
		if body.planta_crecida:
			push(-push_dir * 45.0)
		else:
			push(-push_dir * 35.0)


func _on_soft_coll_body_entered(body: Node2D) -> void:
	if body is corazon_mundo:
		push_dir = (body.global_position - global_position).normalized()
		push(-push_dir * 100)


func _on_area_copa_body_entered(body: Node2D) -> void:
	if body is agua: # agregar la logica de item pickup
		body.in_copa = true
		agua_counter += 1
		if agua_counter > 0 and modo_actual != Modo.COPA:
			modo_actual = Modo.COPA
			apply_modo_settings()
			$AnimatedSprite2D.play("copa")


func _on_area_copa_body_exited(body: Node2D) -> void:
	if body is agua:
		agua_counter -= 1
		body.in_copa = false
		body.origin_position_y = body.global_position.y
		body.piso_threshold = randf_range(1.0, 4.0)
		if agua_counter <= 0 and modo_actual != Modo.CROUCHING: # se puede tirar el agua yendo a modo crouch
			modo_actual = Modo.STANDING
			apply_modo_settings()


func _on_area_base_pala_body_entered(body: Node2D) -> void:
	if body is planta and not body.planta_arrancada:
		push_dir = (body.global_position - global_position).normalized()
		body.apply_impulse(push_dir * 10.0)
		# Optional: If you want recoil, push the player too
		if body.planta_crecida:
			push(-push_dir * 35.0)
		else:
			push(-push_dir * 30.0)
	
	if body is corazon_mundo:
		push_dir = (body.global_position - global_position).normalized()
		push(-push_dir * 100)
	# toss
	if body is RigidBody2D:
		var toss_component = body.get_node_or_null("tossable_component")  # Match name or path
		if toss_component and toss_component.has_method("on_toss_triggered"):
			connect("toss_triggered", Callable(toss_component, "on_toss_triggered"))
			toss_component.in_toss_area = true


func _on_area_base_pala_body_exited(body: Node2D) -> void:
	var toss_component = body.get_node_or_null("tossable_component")
	if toss_component and toss_component.has_method("on_toss_triggered"):
		disconnect("toss_triggered", Callable(toss_component, "on_toss_triggered"))
		toss_component.in_toss_area = false


#================================

# FUNCIONES DE FISICA

#================================


func perform_toss():
	emit_signal("toss_triggered", self)


func push(force: Vector2):
	external_push += force


func empuje_externo(delta):
	if external_push.length() > 0:
		external_push.x = clamp(external_push.x, -100, 100)
		external_push.y = clamp(external_push.y, -100, 100)
		velocity = external_push
		external_push = external_push.move_toward(Vector2.ZERO, friction * delta)
		move_and_slide()


#================================

# SETTERS

#================================


func set_collision_layer_bit(layer: int, enabled: bool) -> void:
	if enabled:
		collision_layer |= 1 << (layer - 1)  # Turn ON bit
	else:
		collision_layer &= ~(1 << (layer - 1))  # Turn OFF bit


func set_collision_mask_bit(layer: int, enabled: bool) -> void:
	if enabled:
		collision_mask |= 1 << (layer - 1)
	else:
		collision_mask &= ~(1 << (layer - 1))


func apply_modo_settings():
	wspeedcount = 0 #resetear movimiento
	match modo_actual:
		Modo.STANDING:
			speedmod = 20
			periodmod = 5
			set_collision_layer_bit(1, false)
			set_collision_mask_bit(1, false)
			set_collision_layer_bit(5, true)
			set_collision_mask_bit(5, true)
			set_collision_layer_bit(4, false)
			$AnimatedSprite2D.z_index = 3
			update_coll_mode("standing")
		
		Modo.CROUCHING:
			speedmod = 15
			periodmod = 2.1
			set_collision_layer_bit(1, true)
			set_collision_mask_bit(1, true)
			set_collision_layer_bit(5, false)
			set_collision_mask_bit(5, false)
			set_collision_layer_bit(4, false)
			$AnimatedSprite2D.z_index = 1
			update_coll_mode(dir_cardinal)
		
		Modo.COPA:
			speedmod = 10
			periodmod = 7.0
			set_collision_layer_bit(1, false)
			set_collision_mask_bit(1, true)
			set_collision_layer_bit(5, false)
			set_collision_mask_bit(5, false)
			set_collision_layer_bit(4, true)
			$AnimatedSprite2D.z_index = 3
			update_coll_mode("modo_copa")

func set_coll_shape_visibility(collsh_name: String, collsh: Node2D, collsh_visible: bool) -> void:
	if collsh is CollisionShape2D:
		# CollisionShape2D has no position or scale, use `disabled`
		collsh.set_deferred("disabled", not collsh_visible)
	elif collsh is CollisionPolygon2D:
		# CollisionPolygon2D inherits from Node2D, so we can move and scale it
		if collsh_visible:
			collsh.scale = Vector2.ONE
			collsh.position = collshape_original_positions.get(collsh_name, Vector2.ZERO)
		else:
			collsh.scale = Vector2.ZERO
			collsh.position = Vector2(9999, 9999)

# Seleccionar modo de colisión
func update_coll_mode(coll_mode: String) -> void:
	set_coll_shape_visibility("crouchN", $collpol_crouchN, false)
	set_coll_shape_visibility("crouchS", $collpol_crouchS, false)
	set_coll_shape_visibility("crouchE", $collpol_crouchE, false)
	set_coll_shape_visibility("crouchO", $collpol_crouchO, false)
	set_coll_shape_visibility("modo_copa", $collpol_modo_copa, false)
	set_coll_shape_visibility("standing", $collsh_standing, false)
	
	match coll_mode:
		"N":
			set_coll_shape_visibility("crouchN", $collpol_crouchN, true)
		"S":
			set_coll_shape_visibility("crouchS", $collpol_crouchS, true)
		"E":
			set_coll_shape_visibility("crouchE", $collpol_crouchE, true)
		"O":
			set_coll_shape_visibility("crouchO", $collpol_crouchO, true)
		"modo_copa":
			set_coll_shape_visibility("modo_copa", $collpol_modo_copa, true)
		"standing":
			set_coll_shape_visibility("standing", $collsh_standing, true)
			#$collsh_standing.set_deferred("disabled", false)
			#$standing_push_area.set_deferred("monitoring", true)
			#$area_copa.set_deferred("monitoring", true)
		"tossing":
			pass


#================================

# GETTERS

#================================

#detectar el cuadrante en el que se encuentra el puntero
func get_direction_cardinal() -> String:
	var angle = mov_direction.angle()
	if angle < 0:
		angle += PI * 2  # Normalize to 0–2π
	
	var direction_index = int(round(angle / (PI / 2))) % 4
	match direction_index:
		0:
			return "E"
		1:
			return "S"
		2:
			return "O"
		3:
			return "N"
	return "0"


#================================

# ANIMACION

#================================


func animacion_idle():
	if walking or watering or tossing:
		return
	if modo_actual == Modo.STANDING:
		$AnimatedSprite2D.play("idle")
	if modo_actual == Modo.CROUCHING:
		var crouch_dir_cardinal = "crouch_idle_" + dir_cardinal
		$AnimatedSprite2D.play(crouch_dir_cardinal)
	if modo_actual == Modo.COPA:
		$AnimatedSprite2D.play("copa")


func animacion_walking():
	if not walking:
		return
	
	if  modo_actual == Modo.STANDING:
		var walk_dir = "walk" + dir_cardinal
		if $AnimatedSprite2D.animation != walk_dir:
			$AnimatedSprite2D.play(walk_dir)
	
	if modo_actual == Modo.CROUCHING:
		var crouch_dir = "crouch" + dir_cardinal
		if $AnimatedSprite2D.animation != crouch_dir:
			$AnimatedSprite2D.play(crouch_dir)
	
	if  modo_actual == Modo.COPA:
		$AnimatedSprite2D.play("copa")


#================================

# PROCESO: FISICA

#================================


func movimiento_jugador(delta):
	# Dirección
	mov_target = get_global_mouse_position()
	mov_direction = position.direction_to(mov_target)

	# Carácter de movimiento: bobbing (sinusoide)
	wspeedcount += delta * periodmod
	speed = abs(sin(wspeedcount)) * speedmod + phasemod
	
	# caminar
	distance = position.distance_to(mov_target)
	
	# velocidad normal
	velocity.x = mov_direction.x * speed * 1.5 # por vista isométrica
	velocity.y = mov_direction.y * speed
	move_and_slide()
	
	# Cache direction once
	dir_cardinal = get_direction_cardinal()
	new_cardinal = dir_cardinal
	# Reset phase on cardinal change
	if new_cardinal != prev_cardinal:
		wspeedcount = 0
		prev_cardinal = new_cardinal
		# Modo de colision
		if modo_actual == Modo.CROUCHING:
			update_coll_mode(dir_cardinal)


func world_boundaries():
	var pos_jugador_x = global_position.x
	var pos_jugador_y = global_position.y * 2
	var pos_jugador = Vector2(pos_jugador_x, pos_jugador_y)
	if pos_jugador.length() > 450:
		push(global_position.direction_to(Vector2.ZERO) * 10)


func _physics_process(delta: float) -> void:
	
	empuje_externo(delta)
	
	if handling:
		return
	
	modo_riego_tilt(delta)
	
	if walking:
		world_boundaries()
		movimiento_jugador(delta)
		animacion_walking()


#================================

# PROCESO: FUNCIONES DE CAMARA

#================================

func change_zoom(zoom_direction: int):  # direction is +1 (out) or -1 (in)
	var current_zoom = $Camera2D.zoom.x  # assuming uniform scaling (x = y)

	# Compute zoom step: smaller step when close in, bigger when zoomed out
	var zoom_step = current_zoom * 0.1  # 10% of current zoom

	var new_zoom_value = current_zoom + (zoom_step * zoom_direction)
	new_zoom_value = clamp(new_zoom_value, 0.2, 5)

	# Tween = easing
	var tween := create_tween()
	tween.tween_property($Camera2D, "zoom", Vector2(new_zoom_value, new_zoom_value), 0.3) \
		 .set_trans(Tween.TRANS_SINE) \
		 .set_ease(Tween.EASE_OUT)


func _process(delta):
	if click_der_pressed:
		time_since_click_der = Time.get_ticks_msec() / 1000.0 - click_start_time
		if time_since_click_der >= required_hold_time:
			camera_look_active = true
			
			var first_target_offset = initial_click_world_pos - initial_player_world_pos
			var smooth_speed = 10.0 # Adjust for desired camera follow speed
			# calculo segundo target (activo)
			var active_mouse_viewport_pos = main_camera.get_viewport().get_mouse_position()
			var distance_from_first_target = active_mouse_viewport_pos.distance_to(initial_click_viewport_pos) / 10
			if distance_from_first_target > 1:
				var vector_distance_from_initial_click = active_mouse_viewport_pos - initial_click_viewport_pos
				var active_target_offset = first_target_offset + vector_distance_from_initial_click * 0.2 # sensibilidad
				smooth_speed = 10.0 # Adjust for desired camera follow speed
				main_camera.offset = main_camera.offset.lerp(active_target_offset, smooth_speed * delta)
			else:
				# ir al primer target de la camara
				main_camera.offset = main_camera.offset.lerp(first_target_offset, smooth_speed * delta)


	elif main_camera.offset.length() > 0.1: # Only smooth back if not already at zero
		# Smoothly return camera offset to Vector2.ZERO (player center)
		var smooth_return_speed = 5.0 # Adjust for desired camera return speed
		main_camera.offset = main_camera.offset.lerp(Vector2.ZERO, smooth_return_speed * delta)
		# Optional: If the offset is very small, snap it to zero to prevent tiny residual movement
		if main_camera.offset.length() < 0.1:
			main_camera.offset = Vector2.ZERO
			camera_look_active = false





#================================
