extends RigidBody2D
class_name mugre

func _ready():
	randomize()
	sleeping = true
	can_sleep = true
	gravity_scale = 0
