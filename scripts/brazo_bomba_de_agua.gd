extends Sprite2D

signal stop_player_movement_signal()
signal restore_player_movement_signal()

var dragging := false
var drag_strength := 8.0

func _process(delta):
	if dragging:
		var mouse_pos := get_global_mouse_position()
		var to_mouse := mouse_pos - global_position
		var rotation_target := to_mouse.angle() - PI/2
		rotation = lerp_angle(rotation, rotation_target, delta * drag_strength)
	else:
		rotation = lerp_angle(rotation, 0.0, delta * drag_strength)
		if rotation == 0.0:
			set_process(false)

func _on_manija_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_action_pressed('click_izq'):
		dragging = true
		set_process(true)
		emit_signal("stop_player_movement_signal")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released('click_izq'):
		dragging = false
		emit_signal("restore_player_movement_signal")
