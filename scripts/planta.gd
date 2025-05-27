extends RigidBody2D
class_name planta

enum Estado { SANA, ARRANCADA, INTOXICADA, MUERTA }
var estado_planta := Estado.SANA
var planta_arrancada := false
var planta_crecida := false
var planta_muerta := false
signal planta_muerta_signal(planta_ref)

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


func _on_area_a_limpiar_body_entered(body: Node2D) -> void:
	if body is mugre:
		mugre_counter += 1
		area_limpiada = false
		print('ensuciao, quedan ', mugre_counter, ' mugres')
		while mugre_counter >= 5 and estado_planta != Estado.INTOXICADA:
			if not waiting:
				intoxicacion_counter += 1
				print('intoxicacion: ', intoxicacion_counter)
				waiting = true
				await get_tree().create_timer(10.0).timeout
				waiting = false
			if intoxicacion_counter >= 5:
				estado_planta = Estado.INTOXICADA
				print('planta intoxicada')
				levelup = 0
				var animacion_i = animacion + '_i'
				$sprite.play(animacion_i)
			if planta_muerta:
				break

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
				estado_planta = Estado.SANA
				print('planta sana')
				levelup = 1
				waiting = false


func _ready() -> void:
	origin_position = global_position
	randomize()
	nplanta = 1
	animacion = "p" + str(nplanta) + "_lvl" + str(level)
	$sprite.play(animacion)

	lock_rotation = true

	set_collision_layer_bit(2, true)
	set_collision_mask_bit(1, true)
	set_collision_layer_bit(3, false)
	set_collision_mask_bit(3, false)

	ciclo_de_vida()


func crecimiento():
	while level < final_seed_level and estado_planta == Estado.SANA:
		if estado_planta == Estado.INTOXICADA:
			break
		else:
			await get_tree().create_timer(30.0).timeout
			level += levelup
			animacion = "p" + str(nplanta) + "_lvl" + str(level)
			$sprite.play(animacion)
			if level == final_seed_level:
				planta_crecida = true
				print('planta crecida')
				# Is on layer 3
				set_collision_layer_bit(3, true)
				set_collision_mask_bit(1, true)  # Detects player
				freeze = true

func ciclo_de_vida():
	while estado_planta != Estado.MUERTA:
		var did_yield := false
		
		if estado_planta == Estado.SANA:
			print('planta sana')
			$sprite.play(animacion)
			await crecimiento()
			#vejez
			if planta_crecida:
				await get_tree().create_timer(100.0).timeout
				decay_counter += 1
				print('morision: ', decay_counter)
				did_yield = true
		
		if planta_arrancada:
			if not waiting:
				decay_counter += 1
				print('morision: ', decay_counter)
				waiting = true
				await get_tree().create_timer(10.0).timeout
				waiting = false
				did_yield = true
		
		if estado_planta == Estado.INTOXICADA:
			if not waiting:
				decay_counter += 1
				waiting = true
				await get_tree().create_timer(10.0).timeout
				waiting = false
				did_yield = true

		if decay_counter > 5:
			var animacion_m = animacion + '_m'
			$sprite.play(animacion_m)
			estado_planta = Estado.MUERTA
			planta_muerta = true
			print('planta muerta')
			emit_signal("planta_muerta_signal", self)
			$area_a_limpiar.monitoring = false
		
		if not did_yield:
			await get_tree().create_timer(0.5).timeout

func _physics_process(_delta):
	to_origin = origin_position - global_position # calcula el desplazamiento desde el origen
	distance_to_origin = to_origin.length()

	# Normalize the direction and scale the force based on distance
	spring_force = to_origin.normalized() * pow(distance_to_origin, 2) * SPRING_STIFFNESS

	# arrancasión
	if distance_to_origin > 4:
		planta_arrancada = true
		spring_force = Vector2.ZERO
		lock_rotation = false
		# Move to layer 2
		set_collision_layer_bit(2, true)
		set_collision_mask_bit(1, true)
		# Turn off planted layer
		set_collision_layer_bit(3, false)
		set_collision_mask_bit(3, false)
		
		$area_a_limpiar.monitoring = false

	elif not planta_arrancada:
	# Apply the force to return to center
		apply_force(spring_force)
