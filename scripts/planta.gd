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
var start_proceso_intoxicacion := 0
var start_proceso_curacion := 0

# Animation
var animacion: String

# Constants
const TIEMPO_INTOXICACION := 10.0
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

func _on_area_a_limpiar_body_entered(body: Node2D):
	if planta_muerta:
		return
	if body is mugre:
		mugre_counter += 1
		body.add_to_group("mugre_in_area_planta")
		if mugre_counter > 1:
			mugres_particles.emitting = true
		print(mugre_counter)
	if mugre_counter >= 5 and estado_planta != Estado.INTOXICADA:
			$timer_intoxicacion.start()
			$timer_curacion.stop()  # Cancel cure if it was running
			$particulas_intoxicacion_p.explosiveness = 0
			$particulas_intoxicacion_p.one_shot = false
			$particulas_intoxicacion_p.emitting = true


func _on_area_a_limpiar_body_exited(body: Node2D):
	if planta_muerta:
		return
	if body is mugre:
		mugre_counter = max(0, mugre_counter - 1)
		if mugre_counter <= 0:
			mugres_particles.emitting = false
		body.remove_from_group("mugre_in_area_planta")
		print(mugre_counter)
		if mugre_counter < 5:
			$timer_intoxicacion.stop()  # Cancel intox if not enough mugres
			$particulas_intoxicacion_p.emitting = false
			if estado_planta == Estado.INTOXICADA and not planta_arrancada:
				$timer_curacion.start()
				$particulas_curacion_p.explosiveness = 0
				$particulas_curacion_p.one_shot = false
				$particulas_curacion_p.emitting = true
		else:
			$particulas_curacion_p.emitting = false

@onready var mugres_particles := $particulas_intoxicacion_m

func particulas_intoxicacion_mugres():
	
	var points: PackedVector2Array = []
	var normals: PackedVector2Array = []
	
	for body in get_tree().get_nodes_in_group("mugre_in_area_planta"):
		var mugre_pos = body.global_position
		var local_pos = mugres_particles.to_local(mugre_pos)
		var dir = mugre_pos.direction_to(global_position)
		points.append(local_pos)
		normals.append(dir) 
	
	mugres_particles.emission_points = points
	mugres_particles.emission_normals = normals

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

func _on_timer_intoxicacion_timeout():
	$particulas_intoxicacion_p.explosiveness = 1.0
	await get_tree().create_timer(2.1).timeout
	$particulas_intoxicacion_p.one_shot = true
	estado_planta = Estado.INTOXICADA
	intoxicacion_start_time = Time.get_ticks_msec() / 1000.0
	levelup = 0
	$sprite.play(animacion + "_i")
	print("Planta intoxicada")

func _on_timer_curacion_timeout():
	$particulas_curacion_p.explosiveness = 1.0
	await get_tree().create_timer(2.1).timeout
	$particulas_curacion_p.one_shot = true
	estado_planta = Estado.SANA
	levelup = 1
	$sprite.play(animacion)
	print("Planta sana")
	crecimiento()

func crecimiento():
	if level >= final_seed_level or planta_muerta:
		return
	
	await get_tree().create_timer(30.0).timeout
	
	if estado_planta == Estado.SANA and not planta_arrancada:
		level += levelup
		animacion = "p%d_lvl%d" % [nplanta, level]
		$sprite.play(animacion)
		#if estado_planta == Estado.INTOXICADA:
			#$sprite.play(animacion + "_i")
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
	
	particulas_intoxicacion_mugres()
	
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
		$particulas_intoxicacion_p.emitting = false
		$particulas_curacion_p.emitting = false
		$area_a_limpiar.monitoring = false
		if arrancada_start_time == 0: #agregar last planta arrancada time para transplante
			arrancada_start_time = Time.get_ticks_msec() / 1000.0
	else:
		if not planta_arrancada:
			apply_force(force)
			apply_torque(torque)
