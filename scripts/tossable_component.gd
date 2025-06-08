extends Node2D
class_name tossable_component

# --- Configuration variables ---
@export var toss_layer: int = 6
var original_layer_bits := []
var original_mask_bits := []


# --- State variables ---
var gravity_scale_on_toss: float = 1.0
var in_toss_area: bool = false
var tossed := false
var toss_vector := Vector2.ZERO
var max_height := 0.0
var height_tolerance := 5.0
var landing_threshold := 0.0
var initial_y_pos := 0.0
var player_initial_y_pos := 0.0

# --- Internal ---
# Cache parent
var body: RigidBody2D
var jugador_ref: Node = null

#func get_layer_bit(layer: int) -> bool:
	#return (body.collision_layer & (1 << (layer - 1))) != 0
#
#func get_mask_bit(mask: int) -> bool:
	#return (body.collision_mask & (1 << (mask - 1))) != 0

func _ready():
	body = get_parent()
	assert(body is RigidBody2D, "tossable_component must be child of RigidBody2D")
	
	# Cache all active layer and mask bits
	for i in range(32):
		if body.collision_layer & (1 << i):
			original_layer_bits.append(i)
		if body.collision_mask & (1 << i):
			original_mask_bits.append(i)

# Called via signal: toss_triggered(jugador_ref)
func on_toss_triggered(player_ref: Node):
	if not in_toss_area:
		return
	body.z_index = 7
	jugador_ref = player_ref
	initial_y_pos = body.global_position.y
	player_initial_y_pos = jugador_ref.global_position.y
	max_height = 0.0

	# Disable all original layers/masks
	for bit in original_layer_bits:
		body.collision_layer &= ~(1 << bit)  # Turn OFF bit

	for bit in original_mask_bits:
		body.collision_mask &= ~(1 << bit)  # Turn OFF bit

	# Enable toss layer
	body.collision_layer |= 1 << toss_layer  # Turn ON bit
	body.collision_mask |= 1 << toss_layer  # Turn ON bit

	body.gravity_scale = gravity_scale_on_toss

	var dir_cardinal_jugador = jugador_ref.dir_cardinal
	toss_vector = toss_vector_calculator(dir_cardinal_jugador)

	var offset = Vector2(randf_range(-0.5, 0.5), randf_range(0.1, 0.5))
	body.apply_impulse(toss_vector, offset)

	tossed = true
	await monitor_airtime()

func monitor_airtime() -> void:
	var has_risen := false

	while tossed:
		var current_height := body.global_position.y - initial_y_pos

		if current_height < max_height:
			max_height = current_height

		if not has_risen and current_height < -height_tolerance:
			has_risen = true

		if has_risen and current_height >= landing_threshold:
			landing()
			break

		# emergency landing
		var distance_from_player = player_initial_y_pos - body.global_position.y
		if not has_risen and distance_from_player < randf_range(0.0, -10):
			landing()
			break

		await get_tree().physics_frame

func landing():
	tossed = false
	body.gravity_scale = 0
	body.z_index = 2
	body.linear_velocity = Vector2.ZERO

	var f_potencial_y = randi_range(-1, 1) * -toss_vector.y / 12
	var f_potencial_x = randi_range(0, 1) * toss_vector.x / 5
	var landing_hit = Vector2(f_potencial_x, f_potencial_y)
	body.apply_impulse(landing_hit)

	# Restore all original layers/masks
	for bit in original_layer_bits:
		body.collision_layer |= 1 << bit  # Turn ON bit

	for bit in original_mask_bits:
		body.collision_mask |= 1 << bit  # Turn ON bit

	# Disable toss layer again
	body.collision_layer &= ~(1 << toss_layer)  # Turn OFF bit
	body.collision_mask &= ~(1 << toss_layer)  # Turn OFF bit

func toss_vector_calculator(dir_cardinal_jugador: String) -> Vector2:
	var toss_range_x: float
	var toss_range_y: float

	match dir_cardinal_jugador:
		'N':
			toss_range_x = randf_range(-1.0, 1.0)
			toss_range_y = randf_range(0.7, 1.0) * -100
			landing_threshold = randf_range(0, 90)
			height_tolerance = 5
		'S':
			toss_range_x = randf_range(-1.0, 1.0)
			toss_range_y = randf_range(0.7, 1.0) * -250
			landing_threshold = randf_range(-80, 0)
			height_tolerance = -landing_threshold - 1
		'E':
			toss_range_x = -randf() * 150
			toss_range_y = randf_range(0.7, 1.0) * -200
			landing_threshold = randf_range(-10, 10)
			height_tolerance = 5
		'O':
			toss_range_x = randf() * 150
			toss_range_y = randf_range(0.7, 1.0) * -200
			landing_threshold = randf_range(-10, 10)
			height_tolerance = 5

	return Vector2(toss_range_x, toss_range_y)
