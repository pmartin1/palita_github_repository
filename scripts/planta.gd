extends RigidBody2D
class_name planta

enum Estado { SANA, ARRANCADA, INTOXICADA, MUERTA }
var estado_planta := Estado.SANA
var planta_arrancada := false
var planta_crecida := false

var nplanta := 1
var level := 0
var levelup := 1
var final_seed_level := 4

var area_limpiada := true
var mugre_counter := 0
var intoxicacion_counter := 0
var decay_counter := 0
var waiting := false

var animacion: String

var origin_position: Vector2
const SPRING_STIFFNESS = 20.0
var to_origin := Vector2.ZERO
var spring_force := Vector2.ZERO
var distance_to_origin := 0.0


func _on_area_a_limpiar_body_entered(body: Node2D) -> void:
	if body is mugre:
		mugre_counter += 1
		area_limpiada = false
		print('ensuciao, quedan ', mugre_counter, ' mugres')
		if mugre_counter < 5 and not waiting:
			intoxicacion_counter += 1
			waiting = true
			await get_tree().create_timer(10.0).timeout
			waiting = false


func _on_area_a_limpiar_body_exited(body: Node2D) -> void:
	if body is mugre:
		mugre_counter -= 1
		print('mispiado, quedan ', mugre_counter, ' mugres')
		if mugre_counter == 0:
			area_limpiada = true
			if not waiting:
				intoxicacion_counter = 0
				waiting = true
				await get_tree().create_timer(10.0).timeout
				waiting = false


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
		while level < final_seed_level and estado_planta == Estado.SANA:
			await get_tree().create_timer(30.0).timeout
			level += levelup
			animacion = "p" + str(nplanta) + "_lvl" + str(level)
			$sprite.play(animacion)
			if level == final_seed_level:
				planta_crecida = true
				# Is on layer 3
				set_collision_layer_bit(3, true)
				set_collision_mask_bit(1, true)  # Detects player
				freeze = true

func ciclo_de_vida():
	if estado_planta == Estado.ARRANCADA:
		planta_arrancada = true
		print('arrancada')
		spring_force = Vector2.ZERO
		levelup = 0
		lock_rotation = false
		# Move to layer 2
		set_collision_layer_bit(2, true)
		set_collision_mask_bit(1, true)
		# Turn off planted layer
		set_collision_layer_bit(3, false)
		set_collision_mask_bit(3, false)
		
		$area_a_limpiar.monitoring = false

	if intoxicacion_counter == 5:
		estado_planta = Estado.INTOXICADA
		print('intoxicada')
		levelup = 0
		# insertar animacion planta intoxicada
		if not waiting:
			decay_counter += 1
			waiting = true
			await get_tree().create_timer(10.0).timeout
			waiting = false

	if estado_planta == Estado.SANA and planta_crecida:
		await get_tree().create_timer(100.0).timeout
		decay_counter += 1

	if decay_counter >= 5:
		print('muerta')
		# insertar animacion planta muerta
		estado_planta = Estado.MUERTA

func _physics_process(_delta):
	to_origin = origin_position - global_position # calcula el desplazamiento desde el origen
	distance_to_origin = to_origin.length()

	# Normalize the direction and scale the force based on distance
	spring_force = to_origin.normalized() * pow(distance_to_origin, 2) * SPRING_STIFFNESS

	# arrancasión
	if distance_to_origin > 4:
		estado_planta = Estado.ARRANCADA

	elif estado_planta != Estado.ARRANCADA:
	# Apply the force to return to center
		apply_force(spring_force)

func _process(_delta: float) -> void:
	if estado_planta == Estado.MUERTA:
		return

	ciclo_de_vida()
