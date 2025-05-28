extends Node2D



var planta_m = preload("res://scenes/planta.tscn")
var area_limpia_checker_scene = preload("res://scenes/area_limpia_checker.tscn")
var planta_counter := 0
@export var cant_max_plantas := 100
@export var cant_max_mugres_s := 10000
@export var cant_max_mugres_m := 1000
var rand_x: float
var rand_y: float

# donut_spawner.gd
@export var min_spawn_radius: float = 35.0  # The inner radius of the donut hole
@export var max_spawn_radius: float = 200.0 # The outer radius of the donut
@export var spawn_center: Vector2 = Vector2.ZERO # The center point of the donut

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

	x = x * 1.75 # isometric fix

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
	while planta_counter < cant_max_plantas:
		await get_tree().create_timer(1.0).timeout
		var area_limpia_checker = area_limpia_checker_scene.instantiate()
		area_limpia_checker.global_position = get_random_donut_spawn_position()
		var saved_checker_pos = area_limpia_checker.global_position
		add_child(area_limpia_checker)
		await get_tree().create_timer(1.0).timeout

		# spawnear planta
		if area_limpia_checker.area_limpia == true:
			remove_child(area_limpia_checker)
			planta_child = planta_m.instantiate()
			planta_child.global_position = saved_checker_pos
			# Connect the signal
			planta_child.planta_muerta_signal.connect(_on_planta_muerta)
			add_child(planta_child)
			planta_counter += 1
			await get_tree().create_timer(100.0).timeout
		else:
			remove_child(area_limpia_checker)

func _on_planta_muerta(planta_ref):
	print("Received death signal from:", planta_ref.name)

	# Start a fade-out animation
	var tween = create_tween()
	tween.tween_property(planta_ref, "modulate:a", 0.0, 2.0)  # Fade out alpha over 2 seconds

	# After 100 seconds, queue free
	await get_tree().create_timer(100.0).timeout
	if planta_ref and planta_ref.is_inside_tree():
		planta_ref.queue_free()

func _on_tossing(toss):
	print('recieved signal from', toss.body)
	pass

func _ready() -> void:
	randomize()
	planta_spawn()
	mugre_spawn()
