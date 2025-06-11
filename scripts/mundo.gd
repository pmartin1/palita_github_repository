extends Node2D

# preloads
var planta_scene = preload("res://scenes/planta.tscn")
var pasto_scene = preload("res://scenes/pasto.tscn")
var area_limpia_checker_scene = preload("res://scenes/area_limpia_checker.tscn")
var mugre_s = preload("res://scenes/mugre_s.tscn")
var mugre_m = preload("res://scenes/mugre_m.tscn")
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
var rand_x: float
var rand_y: float

# donut_spawner.gd
@export var min_spawn_radius: float = 50.0 # The inner radius of the donut hole
@export var max_spawn_radius: float = 220.0 # The outer radius of the donut
var spawn_center: Vector2 = Vector2.ZERO # The center point of the donut

# timers
@export var spawn_check := 1.0
@export var spawn_cooldown := 60.0
@export var muerte_fadeout := 120.0
@export var agua_fadeout := 10.0


func _ready() -> void:
	#Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	randomize()
	planta_spawn()
	mugre_spawn()

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
		var mugre_child = mugre_s.instantiate()
		mugre_child.global_position = get_random_donut_spawn_position()
		add_child(mugre_child)

	for j in range(cant_max_mugres_m):
		var mugre_child = mugre_m.instantiate() 
		mugre_child.global_position = get_random_donut_spawn_position()
		add_child(mugre_child)

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

func _on_reproducir_pasto(pasto_ref):
	# calculo del area de spawn
	randomize()
	var angle := randf_range(0, TAU)
	var min_pasto_hijo_r = 30
	var max_pasto_hijo_r = 40
	var r_squared_min = pow(min_pasto_hijo_r, 2)
	var r_squared_max = pow(max_pasto_hijo_r, 2)
	var random_r_squared = randf_range(r_squared_min, r_squared_max)
	var distance = sqrt(random_r_squared)
	var x = pasto_ref.global_position.x + distance * cos(angle) * 2
	var y = pasto_ref.global_position.y + distance * sin(angle)
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

func _input(event): # reemplazar por bomba de agua
	if event.is_action_pressed("spawn_agua"):
		agua_spawn(get_global_mouse_position())

func _on_spawn_agua(bomba_ref):
	agua_spawn(bomba_ref.spawn_area)

func agua_spawn(spawn_pos):
	var agua_child = aguas.instantiate()
	agua_counter += 1
	agua_child.global_position = spawn_pos
	agua_child.agua_toco_piso_signal.connect(_on_agua_toco_piso)
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

func _on_world_boundary_body_exited(body: Node2D) -> void:
	if body is RigidBody2D:
		body.add_to_group("fugitivos")

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
