extends Area2D

var area_limpia = true
var mugre_counter = 0

func _ready() -> void:
	mugre_counter = 0

func _on_body_entered(body: Node2D) -> void:
	if body is mugre:
		mugre_counter += 1
		if mugre_counter > 5:
			area_limpia = false
			print('dale loko, tenes que limpiar ', mugre_counter,' mugres')
		else:
			area_limpia = true
			print('yay')
