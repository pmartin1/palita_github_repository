extends RigidBody2D
class_name planta

signal planta_muerta_signal(planta_ref)

# Core states - exclusive
enum Estado { SANA, INTOXICADA, MUERTA }
var estado_planta: Estado = Estado.SANA

# Additional independent flags
var planta_arrancada := false
var planta_crecida := false
var da_frutos := false
var planta_muerta := false
var planta_regada := false
var intoxicada := false
var plantada := true

# Growth
var nplanta := 1
var level := 0
var levelup := 1
var final_seed_level := 4

# Decay and timers
var mugre_counter := 0
var decay_counter := 0
var arrancada_start_time := 0.0
var intoxicacion_start_time := 0.0
var vejez_start_time := 0.0
var last_watered_time := -9999.0
var start_proceso_intoxicacion : float
var start_proceso_curacion : float

# Animation
var animacion: String

# Constants
const TIEMPO_INTOXICACION := 10.0
const TIEMPO_CAMBIO_DE_ESTADO := 30.0
const TIEMPO_ARRANCADA := 10.0
const TIEMPO_VEJEZ := 100.0
const TIEMPO_ENTRE_RIEGO := 60.0


# Movement
var origin_position: Vector2
var origin_rotation: float
const SPRING_STIFFNESS := 200.0

func _ready():
	origin_position = global_position
	origin_rotation = rotation
	randomize()
	nplanta = 1
	animacion = "p%d_lvl%d" % [nplanta, level]
	$sprite.play(animacion)
	crecimiento()

func crecimiento():
	if level >= final_seed_level or planta_muerta:
		return

	if estado_planta == Estado.SANA and not planta_arrancada:
		await get_tree().create_timer(30.0).timeout
		level += levelup
		animacion = "p%d_lvl%d" % [nplanta, level]
		$sprite.play(animacion)
		if estado_planta == Estado.INTOXICADA:
			$sprite.play(animacion + "_i")
		if level == final_seed_level:
			planta_crecida = true
			da_frutos = true
			vejez_start_time = Time.get_ticks_msec() / 1000.0
			print("Planta crecida")
		else:
			crecimiento()

func _process(_delta):
	var time_now = Time.get_ticks_msec() / 1000.0
	
	if planta_muerta:
		return
	
	if estado_planta != Estado.INTOXICADA and time_now - start_proceso_intoxicacion > TIEMPO_CAMBIO_DE_ESTADO:
		intoxicada = true
	
	if estado_planta == Estado.INTOXICADA and time_now - start_proceso_curacion > TIEMPO_CAMBIO_DE_ESTADO:
		intoxicada = false

	if estado_planta == Estado.INTOXICADA and time_now - intoxicacion_start_time > TIEMPO_INTOXICACION:
		decay_counter += 1
		print ('decay ', decay_counter)
		intoxicacion_start_time = time_now

	if planta_arrancada and time_now - arrancada_start_time > TIEMPO_ARRANCADA:
		decay_counter += 1
		print ('decay ', decay_counter)
		arrancada_start_time = time_now

	if planta_crecida and time_now - vejez_start_time > TIEMPO_VEJEZ:
		decay_counter += 1
		print ('decay ', decay_counter)
		vejez_start_time = time_now

	if decay_counter >= 5:
		estado_planta = Estado.MUERTA
		planta_muerta = true
		$sprite.play(animacion + "_m")
		emit_signal("planta_muerta_signal", self)
		set_process(false)

func _on_area_a_limpiar_body_entered(body: Node2D):
	if planta_muerta:
		return

	if body is mugre:
		mugre_counter += 1
		if mugre_counter >= 5 and estado_planta != Estado.INTOXICADA:
			start_proceso_intoxicacion = Time.get_ticks_msec() / 1000
			if intoxicada:
				estado_planta = Estado.INTOXICADA
				intoxicacion_start_time = Time.get_ticks_msec() / 1000.0
				levelup = 0
				$sprite.play(animacion + "_i")
				print("Planta intoxicada")

func _on_area_a_limpiar_body_exited(body: Node2D):
	if planta_muerta:
		return
	
	if planta_arrancada:
		mugre_counter = 0
		return
	
	if body is mugre:
		mugre_counter = max(0, mugre_counter - 1)
		if mugre_counter < 5 and estado_planta == Estado.INTOXICADA:
			start_proceso_curacion = Time.get_ticks_msec() / 1000
			if not intoxicada:
				estado_planta = Estado.SANA
				levelup = 1
				$sprite.play(animacion)
				print("Planta sana")
				crecimiento()

func _on_area_a_regar_body_entered(body: Node2D):
	pass
	#if body is water
		#var time_now = Time.get_ticks_msec() / 1000.0
		#if time_now - last_watered_time >= TIEMPO_ENTRE_RIEGO:
			#last_watered_time = time_now
			#planta_regada = true
			#if decay_counter > 0:
				#decay_counter -= 1
				#print("Decay counter reduced to ", decay_counter)
			## Speed growth here later
			#await get_tree().create_timer(3.0).timeout
			#planta_regada = false

func _physics_process(_delta):
	var to_origin = origin_position - global_position
	var distance_to_origin = to_origin.length()
	var force = to_origin.normalized() * pow(distance_to_origin, 2) * SPRING_STIFFNESS

	var angle_diff := wrapf(origin_rotation - rotation, -PI, PI)
	var torque_strength := 20.0
	var damping := 2.0
	var torque := torque_strength * angle_diff - damping * angular_velocity

	if distance_to_origin > 3.0 or planta_arrancada:
		planta_arrancada = true
		levelup = 0
		lock_rotation = false
		$area_a_limpiar.monitoring = false
		if arrancada_start_time == 0: #agregar last planta arrancada time para transplante
			arrancada_start_time = Time.get_ticks_msec() / 1000.0
	else:
		if not planta_arrancada:
			apply_force(force)
			apply_torque(torque)
