extends Node2D

var planta_m = preload("res://scenes/planta.tscn")
var pastos = preload("res://scenes/pasto.tscn")
var area_limpia_checker_scene = preload("res://scenes/area_limpia_checker.tscn")
var planta_counter := 0
@export var cant_max_plantas := 100
@export var cant_max_mugres_s := 10000
@export var cant_max_mugres_m := 1000
var agua_counter := 0
var rand_x: float
var rand_y: float

# donut_spawner.gd
@export var min_spawn_radius: float = 35.0  # The inner radius of the donut hole
@export var max_spawn_radius: float = 220.0 # The outer radius of the donut
@export var spawn_center: Vector2 = Vector2.ZERO # The center point of the donut

#func _process(_delta: float) -> void:
	#$puntero.scale = Vector2(1, 1)
	#$puntero.skew = 0.0
	#
	#var mouse_pos: Vector2 = get_global_mouse_position()
	#$puntero.global_position = mouse_pos
	#
	#var direction_to_player: Vector2 = $jugador.global_position - mouse_pos
	#$puntero.rotation = direction_to_player.angle()
	#
	#if direction_to_player.length() < 8.0:
		#if not $jugador.crouching:
			#$puntero.global_position.x = $jugador.global_position.x
			#$puntero.global_position.y = $jugador.global_position.y - 15
			#$puntero.rotation_degrees = 90
			#$puntero.skew = 0.0
		#else:
			#match $jugador.dir_cardinal:
				#"N":
					#$puntero.global_position.x = $jugador.global_position.x
					#$puntero.global_position.y = $jugador.global_position.y - 3
					#$puntero.rotation_degrees = 90.0
					#$puntero.scale = Vector2(0.75, 1.25)
					#$puntero.skew = 0.0
				#"S":
					#$puntero.global_position.x = $jugador.global_position.x
					#$puntero.global_position.y = $jugador.global_position.y - 3
					#$puntero.rotation_degrees = -90.0
					#$puntero.scale = Vector2(0.75, 1.25)
					#$puntero.skew = 0.0
				#"E":
					#$puntero.global_position.x = $jugador.global_position.x
					#$puntero.global_position.y = $jugador.global_position.y - 3
					#$puntero.rotation_degrees = 180.0
					#$puntero.scale = Vector2(1, 0.75)
					#$puntero.skew = -40.0
					#
				#"O":
					#$puntero.global_position.x = $jugador.global_position.x
					#$puntero.global_position.y = $jugador.global_position.y - 3
					#$puntero.rotation_degrees = 0.0
					#$puntero.scale = Vector2(1, 0.75)
					#$puntero.skew = 40.0

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

func mugre_spawn():
	var mugre_s = preload("res://scenes/mugre_s.tscn")
	var mugre_m = preload("res://scenes/mugre_m.tscn")
	
	for i in range(cant_max_mugres_s):
		var mugre_child = mugre_s.instantiate()
		mugre_child.global_position = get_random_donut_spawn_position()
		add_child(mugre_child)

	for j in range(cant_max_mugres_m):
		var mugre_child = mugre_m.instantiate() 
		mugre_child.global_position = get_random_donut_spawn_position()
		add_child(mugre_child)

func planta_spawn():
	var planta_child
	var pasto_child
	while planta_counter < cant_max_plantas:
		await get_tree().create_timer(1.0).timeout
		var area_limpia_checker = area_limpia_checker_scene.instantiate()
		area_limpia_checker.global_position = get_random_donut_spawn_position()
		var saved_checker_pos = area_limpia_checker.global_position
		add_child(area_limpia_checker)
		await get_tree().create_timer(1.0).timeout

		# spawnear planta
		if area_limpia_checker.spawn_planta == true:
			remove_child(area_limpia_checker)
			planta_child = planta_m.instantiate()
			planta_child.global_position = saved_checker_pos
			# Connect the signal
			planta_child.planta_muerta_signal.connect(_on_planta_muerta)
			add_child(planta_child)
			planta_counter += 1
			await get_tree().create_timer(10.0).timeout
		elif area_limpia_checker.spawn_pasto == true:
			remove_child(area_limpia_checker)
			pasto_child = pastos.instantiate()
			pasto_child.global_position = saved_checker_pos
			# Connect the signal
			pasto_child.pasto_muerto_signal.connect(_on_pasto_muerto)
			add_child(pasto_child)
			await get_tree().create_timer(10.0).timeout
		else:
			remove_child(area_limpia_checker)

func _input(event):
	if event.is_action_pressed("spawn_agua"):
		agua_spawn()

func agua_spawn():
	var aguas = preload("res://scenes/agua.tscn")
	var agua_child = aguas.instantiate()
	agua_child.global_position = get_global_mouse_position()
	agua_child.agua_toco_piso_signal.connect(_on_agua_toco_piso)
	agua_child.z_index = 10
	add_child(agua_child)

func _on_agua_toco_piso(agua_ref):
	# Start a fade-out animation
	var tween = create_tween()
	tween.tween_property(agua_ref, "modulate:a", 0.0, 8.0)  # Fade out alpha over 2 seconds
	await get_tree().create_timer(10.0).timeout
	# After 100 seconds, queue free
	if agua_ref and agua_ref.is_inside_tree():
		agua_ref.queue_free()

func _on_planta_muerta(planta_ref):
	# Start a fade-out animation
	var tween = create_tween()
	tween.tween_property(planta_ref, "modulate:a", 0.0, 10.0)  # Fade out alpha over 2 seconds
	await get_tree().create_timer(10.0).timeout
	# After 100 seconds, queue free
	if planta_ref and planta_ref.is_inside_tree():
		planta_ref.queue_free()

func _on_pasto_muerto(pasto_ref):
	# Start a fade-out animation
	var tween = create_tween()
	tween.tween_property(pasto_ref, "modulate:a", 0.0, 10.0)  # Fade out alpha over 2 seconds
	await get_tree().create_timer(10.0).timeout
	# After 100 seconds, queue free
	if pasto_ref and pasto_ref.is_inside_tree():
		pasto_ref.queue_free()

func _ready() -> void:
	#Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	randomize()
	planta_spawn()
	mugre_spawn()


func _on_world_boundary_body_exited(body: Node2D) -> void:
	if body is RigidBody2D:
		body.add_to_group("fugitivos")

var world_center: Vector2 = Vector2.ZERO
var max_radius: float = 450.0
var pull_strength: float = 10.0

func _physics_process(_delta: float) -> void:
	var bodies = get_tree().get_nodes_in_group("fugitivos")
	for body in bodies:
		var pos_x = body.global_position.x
		var pos_y = body.global_position.y * 2
		var pos = Vector2(pos_x, pos_y)
		var to_center = world_center - pos
		var distance = to_center.length()

		if distance > max_radius:
			var excess = distance - max_radius
			var dir = to_center.normalized()
			var force = dir * excess * pull_strength
			body.apply_central_force(force)
