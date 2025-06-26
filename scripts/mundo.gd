extends Node2D

#================================

#         DEFINICIONES

# COLLISION LAYERS:
# 1: jugador, corazon
# 2: mugres y plantas
# 3: pastos y plantas
# 4: agua
# 5: staticbodies
# 7: objetos en el aire (tossed, no en orbita)
# 8: area checker

# Z INDEX relativo a Y enabled
# todo cuerpo que esté en z_index = 3 sera relativo al jugador
#================================

# preloads
var planta_scene = preload("res://scenes/planta.tscn")
var pasto_scene = preload("res://scenes/pasto.tscn")
var area_limpia_checker_scene = preload("res://scenes/area_limpia_checker.tscn")
var mugre_scene = preload("res://scenes/mugre.tscn")
var aguas = preload("res://scenes/agua.tscn")


# boundary fisiks
var world_center: Vector2 = Vector2.ZERO
var max_radius: float = 450.0
var pull_strength: float = 10.0

# contadores y cantidades
@export var cant_max_plantas := 100
@export var cant_max_mugres_s := 9000
@export var cant_max_mugres_m := 1000
var planta_counter := 0
var pasto_counter := 0
var agua_counter := 0
var mugre_reciclada_counter := 0
var rand_x: float
var rand_y: float

# donut_spawner.gd
@export var min_spawn_radius: float = 45.0 # The inner radius of the donut hole
@export var max_spawn_radius: float = 220.0 # The outer radius of the donut
var spawn_center: Vector2 = Vector2.ZERO # The center point of the donut

# timers
@export var spawn_check := 1.0
@export var spawn_cooldown := 60.0
@export var muerte_fadeout := 120.0
@export var agua_fadeout := 10.0
@export var suelo_regado := 30.0


func _ready() -> void:
	#Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	randomize()
	planta_spawn()
	mugre_spawn()
	intro()


func get_random_donut_spawn_position() -> Vector2:
	# 1. Generate a random angle (0 to 2*PI radians)
	var angle = randf_range(0, TAU) # TAU is 2*PI in Godot, for full circle

	# 2. Generate a random distance from the center
	# This is the tricky part for uniform distribution.
	# We need to consider the area, not just linear distance.
	# A common trick is to square the radii and then take the square root.
	# Explained below in "Important Note on Uniform Distribution".
	var r_squared_min = min_spawn_radius * min_spawn_radius
	var r_squared_max = max_spawn_radius * max_spawn_radius
	var random_r_squared = randf_range(r_squared_min, r_squared_max)
	var distance = sqrt(random_r_squared)

	# 3. Convert polar coordinates (angle, distance) to Cartesian (x, y)
	var x = spawn_center.x + distance * cos(angle)
	var y = spawn_center.y + distance * sin(angle)

	x = x * 2 # isometric fix

	return Vector2(x, y)


func _on_spawn_boundary_area_shape_entered(_area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	if area is area_checker:
		area.inside_spawn_boundary = true


func mugre_spawn():
	for i in range(cant_max_mugres_s):

		var mugres = mugre_scene.instantiate()
		mugres.setup("small")
		mugres.global_position = get_random_donut_spawn_position()
		randomize()
		mugres.nmugre = randi_range(1, 12)
		add_child(mugres)
		mugres.add_to_group("mugres")

	for j in range(cant_max_mugres_m):
		var mugres = mugre_scene.instantiate()
		mugres.setup("medium")
		mugres.global_position = get_random_donut_spawn_position()
		randomize()
		mugres.nmugre = randi_range(1, 12)
		add_child(mugres)
		mugres.add_to_group("mugres")


func planta_spawn():
	if planta_counter >= cant_max_plantas:
		return
	elif planta_counter - 1 > pasto_counter:
		await get_tree().create_timer(spawn_cooldown).timeout
		planta_spawn()
	else:
		var area_limpia_checker := area_limpia_checker_scene.instantiate()
		area_limpia_checker.global_position = get_random_donut_spawn_position()
		var saved_checker_pos = area_limpia_checker.global_position
		add_child(area_limpia_checker)
		await get_tree().create_timer(spawn_check).timeout
		
		if area_limpia_checker.inside_spawn_boundary == false:
			remove_child(area_limpia_checker)
			planta_spawn()
		# spawnear planta
		elif area_limpia_checker.spawn_planta == true and area_limpia_checker.area_limpia == true:
			remove_child(area_limpia_checker)
			var planta_child := planta_scene.instantiate()
			planta_child.global_position = saved_checker_pos
			# Connect the signal
			planta_child.planta_muerta_signal.connect(_on_planta_muerta)
			add_child(planta_child)
			planta_counter += 1
			await get_tree().create_timer(spawn_cooldown).timeout
			planta_spawn()
		
		elif area_limpia_checker.spawn_pasto == true and area_limpia_checker.area_limpia == true:
			remove_child(area_limpia_checker)
			var pasto_child := pasto_scene.instantiate()
			pasto_child.global_position = saved_checker_pos
			# Connect the signal
			pasto_child.pasto_muerto_signal.connect(_on_pasto_muerto)
			pasto_child.reproducir_pasto_signal.connect(_on_reproducir_pasto)
			add_child(pasto_child)
			pasto_counter += 1
			await get_tree().create_timer(spawn_cooldown).timeout
			planta_spawn()
		
		else:
			remove_child(area_limpia_checker)
			planta_spawn()


func _on_reproducir_pasto(ref):
	# calculo del area de spawn
	randomize()
	var angle := randf_range(0.0, TAU)
	var min_pasto_hijo_r = 45.0
	var max_pasto_hijo_r = 75.0
	var r_squared_min = pow(min_pasto_hijo_r, 2)
	var r_squared_max = pow(max_pasto_hijo_r, 2)
	var random_r_squared = randf_range(r_squared_min, r_squared_max)
	var distance = sqrt(random_r_squared)
	if ref is agua:
		distance = 0
	var x = ref.global_position.x + distance * cos(angle) * 2
	var y = ref.global_position.y + distance * sin(angle)
	if ref is agua:
		await get_tree().create_timer(suelo_regado).timeout
	var nuevo_pasto_pos = Vector2(x, y)
	
	var area_limpia_checker = area_limpia_checker_scene.instantiate()
	area_limpia_checker.global_position = nuevo_pasto_pos
	add_child(area_limpia_checker)
	await get_tree().create_timer(spawn_check).timeout
	if area_limpia_checker.inside_spawn_boundary == false:
		remove_child(area_limpia_checker)
	elif area_limpia_checker.spawn_pasto == true and area_limpia_checker.area_limpia == true:
		remove_child(area_limpia_checker)
		var pasto_child = pasto_scene.instantiate()
		pasto_child.global_position = nuevo_pasto_pos
		pasto_child.pasto_muerto_signal.connect(_on_pasto_muerto)
		pasto_child.reproducir_pasto_signal.connect(_on_reproducir_pasto)
		add_child(pasto_child)
		pasto_counter += 1
	else:
		remove_child(area_limpia_checker)


func _on_planta_muerta(planta_ref):
	# Start a fade-out animation
	var tween = create_tween()
	tween.tween_property(planta_ref, "modulate:a", 0.0, muerte_fadeout)  # Fade out alpha over 2 seconds
	await get_tree().create_timer(muerte_fadeout).timeout
	# After 100 seconds, queue free
	if planta_ref and planta_ref.is_inside_tree():
		planta_ref.queue_free()
		planta_counter -= 1
		planta_spawn()


func _on_pasto_muerto(pasto_ref):
	# Start a fade-out animation
	var tween = create_tween()
	tween.tween_property(pasto_ref, "modulate:a", 0.0, muerte_fadeout)  # Fade out alpha over 2 seconds
	await get_tree().create_timer(muerte_fadeout).timeout
	# After 100 seconds, queue free
	if pasto_ref and pasto_ref.is_inside_tree():
		pasto_ref.queue_free()
		pasto_counter -= 1
		planta_spawn()


func _on_reciclar(mugre_ref):
	mugre_ref.queue_free()
	mugre_reciclada_counter += 1
	print(mugre_reciclada_counter)


var modo_cine := false
func _input(event): # reemplazar por bomba de agua
	if event.is_action_pressed("letra_a"):
		#agua_spawn(get_global_mouse_position())
		$world_boundary.set_deferred("monitoring", false)
		$mundo.visible = false
		$corazon_mundo.visible = false
		$bomba_de_agua.visible = false
		modo_cine = true
		await get_tree().create_timer(2.5).timeout
		$palita_boceto_1.play()

func _on_palita_boceto_1_finished() -> void:
	$palita_boceto_1.play()


func _on_spawn_agua(bomba_ref):
	agua_spawn(bomba_ref.spawn_area)


func agua_spawn(spawn_pos):
	var agua_child = aguas.instantiate()
	agua_counter += 1
	agua_child.global_position = spawn_pos
	agua_child.agua_toco_piso_signal.connect(_on_agua_toco_piso)
	agua_child.reproducir_pasto_signal.connect(_on_reproducir_pasto)
	agua_child.z_index = 7
	add_child(agua_child)


func _on_agua_toco_piso(agua_ref):
	# Start a fade-out animation
	var tween = create_tween()
	tween.tween_property(agua_ref, "modulate:a", 0.0, agua_fadeout)  # Fade out alpha over 2 seconds
	await get_tree().create_timer(agua_fadeout).timeout
	# After 100 seconds, queue free
	if agua_ref and agua_ref.is_inside_tree():
		agua_ref.queue_free()
		agua_counter -= 1

var bodies_in_orbit_count := 0
func _on_world_boundary_body_exited(body: Node2D) -> void:


func intro():
	
	var zoom_final = 5
	var zoom_inicial = 0.2
	$jugador/Camera2D.set ("zoom", Vector2(0.2,0.2) )
	
	var current_zoom = $jugador/Camera2D.zoom.x  # assuming uniform scaling (x = y)
	#while (current_zoom < zoom_final):
		#
	#
		## Compute zoom step: smaller step when close in, bigger when zoomed out
		#var zoom_step = current_zoom * 0.1  # 10% of current zoom
#
		#var new_zoom_value = current_zoom + (zoom_step * 1)
		#new_zoom_value = clamp(new_zoom_value, 0.2, 5)

		# Tween = easing
	var tween := create_tween()
	tween.tween_property($jugador/Camera2D, "zoom", Vector2(5.0, 5.0), 10) \
		 .set_trans(Tween.TRANS_SINE) \
		 .set_ease(Tween.EASE_IN_OUT)
		
		#current_zoom = $jugador/Camera2D.zoom.x


	if body is mugre:
		if body.entered_through_corazon_mundo:
			return
		var velocity : Vector2 = body.linear_velocity
		var min_speed := 100.0
		var max_speed := 400.0
		var clamped_speed : float = clamp(velocity.length(), min_speed, max_speed)

		velocity = velocity.normalized() * clamped_speed

		var entry_pos := body.global_position
		var launch_time := 1/(clamped_speed/100)  # time to reach snap point
		var snap_pos := entry_pos + velocity * launch_time
		
		body.start_pre_orbit({
			"entry_pos": entry_pos,
			"velocity": velocity,
			"snap_pos": snap_pos,
			"launch_time": launch_time
			})
		
		if modo_cine:
			return
		
		bodies_in_orbit_count = max(0, bodies_in_orbit_count + 1)
		body.add_to_group('bodies in orbit')
		for orbiter in get_tree().get_nodes_in_group('bodies in orbit'):
			orbiter.bodies_in_orbit = bodies_in_orbit_count
			orbiter.fall_chance_update()


func _on_world_boundary_body_entered(body: Node2D) -> void:
	if modo_cine:
		return
	if body is mugre:
		bodies_in_orbit_count = max(0, bodies_in_orbit_count - 1)
		body.remove_from_group('bodies in orbit')
		for orbiter in get_tree().get_nodes_in_group('bodies in orbit'):
			orbiter.bodies_in_orbit = bodies_in_orbit_count
			orbiter.fall_chance_update()
