extends Node
# TossComponent.gd
signal toss_triggered(force_vector: Vector2)

func perform_toss(force: Vector2):
	emit_signal("toss_triggered", force)
