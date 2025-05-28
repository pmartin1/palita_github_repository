extends StaticBody2D

class_name corazon_mundo

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is RigidBody2D:
		var push_dir = (body.global_position - global_position).normalized()
		body.apply_impulse(push_dir * 100.0)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
