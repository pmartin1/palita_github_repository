extends CharacterBody2D

# caracteristicas de movimiento
var speed := 0.0
var wspeedcount := 0.0
var speedmod := 20.0
var periodmod := 5.0
const phasemod = 1.5

# coordenadas de movimiento
var mov_target = Vector2.ZERO
var mov_direction = Vector2.ZERO
var prev_cardinal: String = get_direction_cardinal()
var new_cardinal: String = get_direction_cardinal()
var dir_cardinal: String = get_direction_cardinal()

# estados
var is_clicking := false
var crouching := false

# Eventos del input (project/project settings/input map)
func _input(event):
	if event.is_action_pressed("walk"):
		walk_start()

	elif event.is_action_released("walk"):
		walk_stop()

	if event.is_action_pressed("toggle_crouch"):
		toggle_crouch()

# Acciones que no son prioritarias (son pisadas por UI)
func _unhandled_input(event):
	# Por ejemplo el zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			change_zoom(1)  # Zoom in
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			change_zoom(-1)   # Zoom out

# Funciones del zoom
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

# Física con respecto a objetos cuando el jugador esta parado
# La función es triggereada por una señal (puerta verde), por ello no hay que llamarla en process
func _on_push_area_body_entered(body: Node2D) -> void:
	if body is RigidBody2D:
		var push_dir = (body.global_position - global_position).normalized()
		body.apply_impulse(push_dir * 0.1)

# Called when the node enters the scene tree for the first time (inicialización)
func _ready():
	mov_target = position
	update_coll_mode("standing")
	$push_area.monitoring = true
	$push_area/collsh_standing.disabled = false
	$AnimatedSprite2D.z_index = 3

func walk_start():
	is_clicking = true
	mov_target = get_global_mouse_position()
	mov_direction = position.direction_to(mov_target)

func walk_stop():
	is_clicking = false
	mov_target = position
	mov_direction = Vector2.ZERO
	speed = 0
	wspeedcount = 0
	if not crouching:
		if $AnimatedSprite2D.animation != "idle":
			$AnimatedSprite2D.play("idle")

func toggle_crouch():
	wspeedcount = 0 #reset phase
	if crouching != true:
		crouching = true #toggle
		# Set caracteristicas de movimiento
		speedmod = 15
		periodmod = 2.1

		# Animación
		if not is_clicking:
			if $AnimatedSprite2D.animation != "crouch_idle":
				$AnimatedSprite2D.play("crouch_idle")

	else:
		crouching = false
		speedmod = 20
		periodmod = 5

		# Animación
		if not is_clicking:
			if $AnimatedSprite2D.animation != "idle":
				$AnimatedSprite2D.play("idle")

func movimiento_jugador(delta):
	# Dirección
	mov_target = get_global_mouse_position()
	mov_direction = position.direction_to(mov_target)

	# Carácter de movimiento: bobbing (sinusoide)
	wspeedcount += delta * periodmod
	speed = abs(sin(wspeedcount)) * speedmod + phasemod

	# Modo de colision
	if crouching:
		update_coll_mode(get_direction_cardinal())
	else:
		update_coll_mode("standing")

	# Ejecutar movimiento
	var distance = position.distance_to(mov_target)
	if distance > 8: # Para evitar que el personaje se mueva raro cuando el mouse esta muy cerca
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


func animacion_jugador_walking():
	if crouching:
		var crouch_dir = "crouch" + dir_cardinal
		if $AnimatedSprite2D.animation != crouch_dir:
			$AnimatedSprite2D.play(crouch_dir)
		$AnimatedSprite2D.z_index = 0 # Show sprite below objects

	else:
		# Selección de sprite según dirección cardinal
		var walk_dir = "walk" + dir_cardinal
		if $AnimatedSprite2D.animation != walk_dir:
			$AnimatedSprite2D.play(walk_dir)
		$AnimatedSprite2D.z_index = 3 # Show sprite above objects


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

# Seleccionar modo de colisión
func update_coll_mode(coll_mode: String):
	# Disable all collision shapes first
	$collpol_crouchN.disabled = true
	$collpol_crouchS.disabled = true
	$collpol_crouchE.disabled = true
	$collpol_crouchO.disabled = true
	$push_area.monitoring = false

	# Enable only the one corresponding to current mode
	match coll_mode:
		"N":
			$collpol_crouchN.disabled = false
		"S":
			$collpol_crouchS.disabled = false
		"E":
			$collpol_crouchE.disabled = false
		"O":
			$collpol_crouchO.disabled = false
		"standing":
			$push_area.monitoring = true

func _physics_process(delta: float) -> void:

	if is_clicking:
		movimiento_jugador(delta)
		animacion_jugador_walking()
