extends Node2D



var PlantaScene = preload("res://scenes/planta.tscn")
var area_limpia_checker_scene = preload("res://scenes/area_limpia_checker.tscn")
var planta_counter := 0
@export var cant_max_plantas := 100
@export var cant_max_mugres := 10000
var rand_x: float
var rand_y: float

# donut_spawner.gd
@export var min_spawn_radius: float = 50.0  # The inner radius of the donut hole
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
	var MugreScene = preload("res://scenes/mugres.tscn")

	for i in range(cant_max_mugres):
		var mugre_child = MugreScene.instantiate()  # ✅ Create an instance
		mugre_child.global_position = get_random_donut_spawn_position()
		add_child(mugre_child)

func planta_spawn():
	while planta_counter <= cant_max_plantas:
		await get_tree().create_timer(4.0).timeout
		var area_limpia_checker = area_limpia_checker_scene.instantiate()
		area_limpia_checker.global_position = get_random_donut_spawn_position()
		add_child(area_limpia_checker)
		await get_tree().create_timer(1).timeout

		# spawnear planta
		if area_limpia_checker.area_limpia == true:
			remove_child(area_limpia_checker)
			var planta_child = PlantaScene.instantiate()
			planta_child.global_position = Vector2(rand_x, rand_y)
			add_child(planta_child)
			planta_counter += 1
			await get_tree().create_timer(100.0).timeout
		else:
			remove_child(area_limpia_checker)


func _ready() -> void:
	randomize()
	planta_spawn()
	mugre_spawn()
