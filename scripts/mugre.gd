extends RigidBody2D
class_name mugre

enum MugreMode { PASSIVE, ACTIVE, RIGID, ORBITING }

var current_mode := MugreMode.PASSIVE

var orbit_data = {
	"entry_time": 0.0,
	"entry_pos": Vector2.ZERO,
	"center": Vector2.ZERO,
	"a": 0.0,
	"b": 0.0,
	"speed": 0.0,
	"duration": randf_range(5.0, 6.0),
	"t": 0.0,
	"t0": 0.0,
	"t_cross_x": 0.0,
	"wiggle_vector": Vector2.ZERO,
	"wiggle_damping": 3.0,
}


var sprite: AnimatedSprite2D
var collsh: CollisionShape2D
@export var nmugre := 1

var orbit_enter_y_threshold := 0.0
var orbit_start_time := 0.0
var in_top_side = true
var awoken := false
var tossed := false
var is_falling := false
var is_in_corazon_mundo := false
var phase := 0.0


func setup(type: String):
	if type == "small":
		mass = 0.25
		$sprite_mugre_s.visible = true
		sprite = $sprite_mugre_s
		$collmugre_s.set_deferred("disabled", false)
		collsh = $collmugre_s
		# desactivar la otra opcion
		$sprite_mugre_m.visible = false
		$collmugre_m.set_deferred("disabled", true)
		
	elif type == "medium":
		mass = 0.5
		$sprite_mugre_m.visible = true
		sprite = $sprite_mugre_m
		$collmugre_m.set_deferred("disabled", false)
		collsh = $collmugre_m
		# desactivar la otra opcion
		$sprite_mugre_s.visible = false
		$collmugre_s.set_deferred("disabled", true)

func _ready():
	randomize()
	nmugre = randi_range(1, 12)
	rotation = randf_range(0, TAU)
	sprite.play("mugre_" + str(nmugre))
	set_rigid_mode()
	await get_tree().create_timer(0.5).timeout
	set_passive_mode()

# --- Mode switching ---


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


func set_passive_mode():
	current_mode = MugreMode.PASSIVE
	awoken = false
	collsh.set_deferred("disabled", false)
	set_deferred('freeze_mode', 0)
	set_deferred("freeze", true)
	set_process(false)
	set_physics_process(false)

func set_active_mode():
	current_mode = MugreMode.ACTIVE
	awoken = true
	collsh.set_deferred("disabled", false)
	set_deferred('freeze_mode', 1)
	set_deferred("freeze", true)
	set_process(false)
	set_physics_process(true)

func set_rigid_mode():
	current_mode = MugreMode.RIGID
	collsh.set_deferred("disabled", false)
	set_deferred("freeze", false)
	set_process(false)
	set_physics_process(true)

func set_orbit_mode():
	current_mode = MugreMode.ORBITING
	collsh.set_deferred("disabled", true)
	set_deferred('freeze_mode', 0)
	set_deferred("freeze", true)
	set_process(true)
	set_physics_process(false)

# --- Orbit simulation ---

func wrap_angle_to_pi(a: float, entry_pos_x: float) -> float:
	return fmod((-sign(entry_pos_x) * a + PI + phase), TAU) - PI

var time_now := 0.0
var frame_count := 0
var throw_dice := 0
var dice := 9999
var fall_chance := 9999
var bodies_in_orbit := 0

func _process(delta):
	frame_count += 1
	throw_dice += 1
	if frame_count >= 2:
		frame_count = 0
		if is_in_pre_orbit:
			pre_orbit_timer += delta
			var t = clamp(pre_orbit_timer / launch_time, 0.0, 1.0)
			global_position = entry_pos.lerp(snap_pos, t)
			if t >= 1.0:
				# Orbit entry happens now
				enter_orbit_from_snap()
		elif is_in_orbit:
			time_now = Time.get_ticks_msec() / 1000.0
			update_orbit(delta)
			if not defined_half_cycle_time:
				return
			if dice == 0 and time_now - last_cycle_time > half_cycle_time * randf_range(0.3, 0.95):
				fall_to_ground()
				return
			if in_top_side and throw_dice >= 10:
				dice = randi_range(0, fall_chance)
				throw_dice = 0

var pre_orbit_timer := 0.0
var launch_time := 0.4
var entry_pos := Vector2.ZERO
var snap_pos := Vector2.ZERO
var velocity := Vector2.ZERO
var wiggle_vector := Vector2.ZERO
var is_in_pre_orbit := false
var is_in_orbit := false

func start_pre_orbit(data: Dictionary):
	current_mode = MugreMode.ORBITING
	orbit_data = data
	collsh.set_deferred("disabled", true)
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	set_deferred("freeze", true)
	set_process(true)
	set_physics_process(false)
	
	entry_pos = data.entry_pos
	velocity = data.velocity
	snap_pos = data.snap_pos
	launch_time = data.launch_time
	pre_orbit_timer = 0.0
	is_in_pre_orbit = true

func enter_orbit_from_snap():
	is_in_pre_orbit = false
	var entry_time = Time.get_ticks_msec() / 1000.0
	orbit_start_time = entry_time
	# Compute orbit using snap_pos as entry
	# We'll generate orbit params here, simplified:
	var center = (snap_pos + Vector2.ZERO) / 2.0
	var entry_x = abs(snap_pos.x)
	var a = clamp(entry_x / 900.0, 0.001, 1.0) * 450.0
	var b = 350.0

	var dx = snap_pos.x - center.x
	var dy = snap_pos.y - center.y
	var cos_t0 = clamp(dx / a, -1.0, 1.0)
	var sin_t0 = clamp(dy / b, -1.0, 1.0)
	var t0 = atan2(sin_t0, cos_t0)
	
	var direction = -sign(snap_pos.x)
	var speed = randf_range(0.1, 0.4) * direction
	var t_cross_x = acos(clamp(-center.x / a, -1.0, 1.0))

	# ✅ Wiggle vector matches the initial velocity direction
	wiggle_vector = velocity.normalized() * randf_range(12.0, 24.0)

	orbit_data = {
		"entry_time": entry_time,
		"center": center,
		"a": a,
		"b": b,
		"t": 0.0,
		"t0": t0,
		"speed": speed,
		"duration": randf_range(120.0, 160.0),
		"entry_pos": snap_pos,
		"t_cross_x": t_cross_x,
		"wiggle_vector": wiggle_vector,
		"wiggle_damping": 3.0
	}
	is_in_orbit = true

# NOTA: esta funcion es un bardo. no tengo idea como funciona, pero funciona
# los -sign(orbit_data.entry_pos.x) son un fix para que las mugres desaparezcan en el (0,0)
# sin importar si estan del lado positivo o negativo de X
# (el angulo empieza en 0 si x<0 pero empieza en 3,8 si x>0, no tengo idea de por qué

var defined_half_cycle_time := false
var half_cycle_time := 0.0
var registered_cycle_start := false
var last_cycle_time := 0.0

func update_orbit(delta):
	orbit_data.t += delta * orbit_data.speed
	var angle = orbit_data.t + orbit_data.t0
	var a = orbit_data.a
	var b = orbit_data.b
	var c = orbit_data.center
	
	var base_pos = Vector2(
		c.x + a * cos(angle + phase),
		c.y + b * sin(angle + phase)
	)

	# Wiggle animation (damped sinusoid)
	var t_fraction = clamp(abs(orbit_data.t)*3 / 1.0, 0.0, 1.0)
	var damping = exp(-orbit_data.wiggle_damping * t_fraction)
	var wiggle = orbit_data.wiggle_vector * sin(t_fraction * PI * 4) * damping

	global_position = base_pos + wiggle

	# Use X-crossing as a z-flip point
	var flip_angle = fmod(orbit_data.t0 + orbit_data.t_cross_x, TAU)
	# Normalize the difference between current angle and flip_angle to range [-PI, PI]
	var orbit_relative_angle = wrap_angle_to_pi(angle - flip_angle, orbit_data.entry_pos.x)
	
	# Flip z_index when mugre is "behind" world center
	if -sign(orbit_data.entry_pos.x) * orbit_relative_angle < 0:
		z_index = -1  # Behind
		in_top_side = false
		registered_cycle_start = false
		if half_cycle_time > 10.0 and defined_half_cycle_time == false:
			defined_half_cycle_time = true
	else:
		z_index = 10  # In front
		in_top_side = true
		if not defined_half_cycle_time:
			half_cycle_time = time_now - orbit_start_time
		elif not registered_cycle_start:
			last_cycle_time = time_now
			registered_cycle_start = true
	
	#var distance_from_orbit_start = global_position.y - orbit_data.entry_pos.y
	#var time_from_orbit_start = time_now - orbit_data.entry_time
	#if time_from_orbit_start > orbit_data.duration:
		#if distance_from_orbit_start < 30:
			#fall_to_ground()
		#else:
			#orbit_data.duration += 30.0

var y_ground_threshold := 0.0

func fall_to_ground():
	is_falling = true
	is_in_orbit = false
	y_ground_threshold = randf_range(0, entry_pos.y)
	gravity_scale = 1
	set_collision_mask_bit(1, false)
	set_collision_mask_bit(2, false)
	set_rigid_mode()

var softcoll_velocity := Vector2.ZERO
var repel_force := 5.0
var friction := 0.9

func _physics_process(delta: float) -> void:
	if current_mode == MugreMode.RIGID:
		if global_position.y > 1000.0: #rescate
			print(self, ' rescatada')
			global_position = Vector2.ZERO
			phase = PI
			var rand_angle = randf_range(0, TAU)
			snap_pos = Vector2.from_angle(rand_angle) * Vector2(500, 250)
			set_orbit_mode()
			enter_orbit_from_snap()
		if is_falling and global_position.y > y_ground_threshold:
			z_index = 2
			is_falling = false
			set_collision_mask_bit(1, true)
			set_collision_mask_bit(2, true)
			gravity_scale = 0
			var rand_angle = randf_range(0, TAU)
			apply_impulse(Vector2.from_angle(rand_angle) * randf_range(10, 100))
			await get_tree().create_timer(1.0).timeout
			set_passive_mode()

func fall_chance_update():
	fall_chance = max(0, 2500 - bodies_in_orbit)
