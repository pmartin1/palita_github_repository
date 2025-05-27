extends RigidBody2D
class_name mugre

var in_toss_area := false
var initial_y_pos := 0.0
var distance_from_floor := 0.0
var tossed := false

func _ready():
	sleeping = true
	can_sleep = true
	initial_y_pos = global_position.y
	gravity_scale = 0

func set_collision_layer_bit(layer: int, enabled: bool) -> void:
	if enabled:
		collision_layer |= 1 << (layer - 1)
	else:
		collision_layer &= ~(1 << (layer - 1))

func set_collision_mask_bit(layer: int, enabled: bool) -> void:
	if enabled:
		collision_mask |= 1 << (layer - 1)
	else:
		collision_mask &= ~(1 << (layer - 1))

func on_toss_triggered(force: Vector2):
	if not in_toss_area:
		return
	initial_y_pos = global_position.y
	distance_from_floor = 0
	set_collision_layer_bit(2, false)
	set_collision_mask_bit(2, false)
	set_collision_mask_bit(1, false)
	set_collision_layer_bit(7, true)
	set_collision_mask_bit(7, true)
	gravity_scale = 1.0
	apply_impulse(force)
	tossed = true
	
	await monitor_airtime()  # Replaces _physics_process

func monitor_airtime() -> void:
	var has_risen := false
	var max_height := 0.0
	var height_tolerance := 5.0  # Minimum Y difference to confirm it actually rose
	randomize()
	var landing_threshold := randi_range(-10, 10)   # Allow mugres to land within ±10px of initial Y

	while tossed:
		var current_height := global_position.y - initial_y_pos

		# Track max height reached
		if current_height < max_height:
			max_height = current_height

		# Wait until the mugre has clearly risen
		if not has_risen and current_height < -height_tolerance:
			has_risen = true

		# Once it has risen and is now falling back down...
		if has_risen and current_height >= landing_threshold:
			# Land
			tossed = false
			gravity_scale = 0
			linear_velocity = Vector2.ZERO
			var f_potencial_y = randi_range(-1, 1) * max_height /5
			var f_potencial_x = randi_range(-1, 1) * max_height /5
			var landing_hit: Vector2 = Vector2(f_potencial_x, f_potencial_y)
			apply_impulse(landing_hit)
			set_collision_layer_bit(7, false)
			set_collision_mask_bit(7, false)
			set_collision_layer_bit(2, true)
			set_collision_mask_bit(2, true)
			set_collision_mask_bit(1, true)
			break

		await get_tree().physics_frame
