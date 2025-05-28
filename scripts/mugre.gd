extends RigidBody2D
class_name mugre

var in_toss_area := false


func _ready():
	randomize()
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

var initial_y_pos := 0.0
var player_initial_y_pos := 0.0
var distance_from_floor := 0.0
var tossed := false
var landing_threshold: float
var height_tolerance: float
var max_height := 0.0
var toss_vector: Vector2

func on_toss_triggered(jugador_ref):
	if not in_toss_area:
		return
	initial_y_pos = global_position.y
	player_initial_y_pos = jugador_ref.global_position.y
	distance_from_floor = 0
	set_collision_layer_bit(2, false)
	set_collision_mask_bit(2, false)
	set_collision_mask_bit(1, false)
	set_collision_layer_bit(7, true)
	set_collision_mask_bit(7, true)
	gravity_scale = 1.0
	var dir_cardinal_jugador = jugador_ref.dir_cardinal
	toss_vector = toss_vector_calculator(dir_cardinal_jugador)
	var offset = Vector2(randf_range(-0.5, 0.5), randf_range(0.1, 0.5))
	apply_impulse(toss_vector, offset)
	tossed = true
	
	await monitor_airtime()  # Replaces _physics_process

func monitor_airtime() -> void:
	var has_risen := false
	
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
			landing()
			break
		
		# emergency landing
		var distance_from_player = player_initial_y_pos - global_position.y
		if not has_risen and distance_from_player < randf_range(0.0, -10):
			landing()
			break

		await get_tree().physics_frame

func landing():
	tossed = false
	gravity_scale = 0
	linear_velocity = Vector2.ZERO
	var f_potencial_y = randi_range(-1, 1) * -toss_vector.y / 12
	var f_potencial_x = randi_range(0, 1) * toss_vector.x / 5
	var landing_hit: Vector2 = Vector2(f_potencial_x, f_potencial_y)
	apply_impulse(landing_hit)
	set_collision_layer_bit(7, false)
	set_collision_mask_bit(7, false)
	set_collision_layer_bit(2, true)
	set_collision_mask_bit(2, true)
	set_collision_mask_bit(1, true)

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
			toss_range_y = randf_range(0.7, 1) * -250
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
