extends Area2D

var area_limpia := true
var mugre_counter := 0
var planta_counter := 0
var pasto_counter := 0
var spawn_planta := false
var spawn_pasto := false

func _ready() -> void:
	mugre_counter = 0

func _on_body_entered(body: Node2D) -> void:
	
	if body is planta:
		if global_position.distance_to(body.global_position) < 3:
			global_position += Vector2.from_angle(randf_range(0, TAU)) * randf_range(3, 6)
	
	if body is pasto:
		pasto_counter += 1
	
	if body is mugre:
		mugre_counter += 1
		if mugre_counter > 10:
			area_limpia = false
		else:
			area_limpia = true
			spawn_check()

func _on_body_exited(body: Node2D) -> void:
	if body is mugre:
		mugre_counter -= 1

	if body is pasto:
		pasto_counter -= 1

func spawn_check():
	if pasto_counter > 1:
		spawn_planta = true
	else:
		spawn_pasto = true
