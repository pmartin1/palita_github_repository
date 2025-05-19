extends RigidBody2D

var nplanta := 1
var level := 0
var levelup := 1
var final_seed_level := 4
var home_position: Vector2
var planta_arrancada := false
var animacion: String
const SPRING_STIFFNESS = 100.0

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

func _ready() -> void:
	home_position = global_position
	randomize()
	nplanta = randi_range(1, 4)
	animacion = "p" + str(nplanta) + "_lvl" + str(level)
	$sprite.play(animacion)
	crecimiento()
	lock_rotation = true
	set_collision_layer_bit(2, true)
	set_collision_layer_bit(1, true)


func crecimiento():
	if level == final_seed_level:
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
		return
	else:
		while level < final_seed_level:
			await get_tree().create_timer(5.0).timeout
			level += levelup
			animacion = "p" + str(nplanta) + "_lvl" + str(level)
			$sprite.play(animacion)

func _physics_process(_delta):
	var to_center = home_position - global_position
	var distance = to_center.length()

	# Normalize the direction and scale the force based on distance
	var spring_force = to_center.normalized() * pow(distance, 4) * SPRING_STIFFNESS

	if level == 0 and distance > 2:
		spring_force = 0
		levelup = 0
		planta_arrancada = true
		lock_rotation = false
		set_collision_layer_bit(2, true)
		set_collision_layer_bit(1, false)
	elif planta_arrancada != true:
	# Apply the force to return to center
		apply_force(spring_force)
