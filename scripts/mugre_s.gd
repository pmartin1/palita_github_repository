extends mugre

func _ready() -> void:
	randomize()
	var nmugre = randi_range(1, 12)
	var mugre_sel: String = "mugre_" + str(nmugre)
	$mugre_s.play(mugre_sel)

func set_collision_layer_bit(layer: int, enabled: bool) -> void:
	if enabled:
		collision_layer |= 1 << (layer - 1)  # Turn ON bit
	else:
		collision_layer &= ~(1 << (layer - 1))  # Turn OFF bit

func set_collision_mask_bit(layer: int, enabled: bool) -> void:
	if enabled:
		collision_mask |= 1 << (layer - 1)
	else:
		collision_mask &= ~(1 << (layer - 1))
