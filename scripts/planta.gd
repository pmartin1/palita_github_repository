extends RigidBody2D
class_name planta

var nplanta := 1
var level := 0
var levelup := 1
var final_seed_level := 4
var origin_position: Vector2
var planta_arrancada := false
var planta_crecida := false
var animacion: String
const SPRING_STIFFNESS = 20.0

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
	origin_position = global_position
	randomize()
	nplanta = randi_range(1, 4)
	animacion = "p" + str(nplanta) + "_lvl" + str(level)
	$sprite.play(animacion)
	crecimiento()
	lock_rotation = true
	# Move to layer 2
	set_collision_layer_bit(2, true)
	set_collision_mask_bit(1, true)
	# Turn off planted layer
	set_collision_layer_bit(3, false)
	set_collision_mask_bit(3, false)


func crecimiento():
		while level < final_seed_level:
			await get_tree().create_timer(5.0).timeout
			level += levelup
			animacion = "p" + str(nplanta) + "_lvl" + str(level)
			$sprite.play(animacion)
			if level == final_seed_level:
				planta_crecida = true
				# Is on layer 3
				set_collision_layer_bit(3, true)
				set_collision_mask_bit(1, true)  # Detects player
				freeze = true

func _physics_process(_delta):
	var to_origin = origin_position - global_position # calcula el desplazamiento desde el origen
	var distance_to_origin = to_origin.length()

	# Normalize the direction and scale the force based on distance
	var spring_force = to_origin.normalized() * pow(distance_to_origin, 2) * SPRING_STIFFNESS

	# arrancasión
	if level < final_seed_level and distance_to_origin > 4:
		spring_force = 0
		levelup = 0
		planta_arrancada = true
		lock_rotation = false
		# Move to layer 2
		set_collision_layer_bit(2, true)
		set_collision_mask_bit(1, true)
		# Turn off planted layer
		set_collision_layer_bit(3, false)
		set_collision_mask_bit(3, false)


	elif planta_arrancada != true:
	# Apply the force to return to center
		apply_force(spring_force)
