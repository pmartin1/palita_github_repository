extends Node2D

func _ready() -> void:
	randomize()
	
	# Load the scene once outside the loop for efficiency
	var MugreScene = preload("res://scenes/mugres.tscn")

	for i in range(10000):
		var mugre = MugreScene.instantiate()  # ✅ Create an instance
		var rand_x = randf_range(-350, 350)
		var rand_y = randf_range(-150, 150)
		mugre.global_position = Vector2(rand_x, rand_y)
		add_child(mugre)

	var PlantaScene = preload("res://scenes/planta.tscn")

	for i in range(1):
		var planta = PlantaScene.instantiate()  # ✅ Create an instance
		var rand_x = randf_range(-10, 10)
		var rand_y = randf_range(-10, 10)
		planta.global_position = Vector2(rand_x, rand_y)
		add_child(planta)
