extends Node2D

var PlantaScene = preload("res://scenes/planta.tscn")
var area_limpia_checker_scene = preload("res://scenes/area_limpia_checker.tscn")
var planta_counter := 0
var rand_x: float
var rand_y: float

func mugre_spawn():
	var MugreScene = preload("res://scenes/mugres.tscn")

	for i in range(100):
		var mugre = MugreScene.instantiate()  # ✅ Create an instance
		var rand_x = randf_range(-350, 350)
		var rand_y = randf_range(-150, 150)
		mugre.global_position = Vector2(rand_x, rand_y)
		add_child(mugre)

func planta_spawn():
	while planta_counter <= 100:
		await get_tree().create_timer(4.0).timeout
		var area_limpia_checker = area_limpia_checker_scene.instantiate()
		rand_x = randf_range(-50, 50)
		rand_y = randf_range(-50, 50)
		area_limpia_checker.global_position = Vector2(rand_x, rand_y)
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
		
		remove_child(area_limpia_checker)


func _ready() -> void:
	randomize()
	planta_spawn()
	mugre_spawn()
