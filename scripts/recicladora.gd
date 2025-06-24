extends StaticBody2D

signal reciclar_signal(mugre_ref)

func _ready() -> void:
	var mundo = get_parent()
	connect("reciclar_signal", Callable(mundo, "_on_reciclar"))

func _on_hueco_body_entered(body: Node2D) -> void:
	if body is mugre:
		body.set_rigid_mode()
		body.gravity_scale = 1


func _on_hueco_body_exited(body: Node2D) -> void:
	if body is mugre:
		emit_signal("reciclar_signal", body)
