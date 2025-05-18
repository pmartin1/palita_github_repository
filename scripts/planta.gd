extends AnimatedSprite2D

var rand
var nplanta = 1
var level = 0

func _ready() -> void:
	randomize()
	nplanta = randi_range(1, 2)
	var animacion = "p" + nplanta + "_lvl" + level # Esto funciona pq las variables nplanta y level son dinamicas


func crecimiento():
	self.play("animacion")
	pass
