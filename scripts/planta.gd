extends RigidBody2D

var rand
var nplanta = 1
var level = 0
var final_seed_level = 4

func _ready() -> void:
	randomize()
	nplanta = randi_range(1, 2)

func crecimiento():
	if level == final_seed_level:
		return
	while level <= final_seed_level:
		await get_tree().create_timer(5.0).timeout
		level += 1
		var animacion = "p" + nplanta + "_lvl" + level # Esto funciona pq las variables nplanta y level son dinamicas
		$sprite.play("animacion")
