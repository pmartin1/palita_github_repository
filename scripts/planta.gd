extends RigidBody2D
class_name planta

signal planta_muerta_signal(planta_ref)

# Core states - exclusive
enum Estado { SANA, INTOXICADA, MUERTA }
var estado_planta: Estado = Estado.SANA

# Additional independent flags
var planta_arrancada := false
var planta_creciendo := false
var planta_crecida := false
var da_frutos := false
var planta_regada := false
var plantada := true

# Growth
var nplanta := 1
var level := 0
var levelup := 1
var max_level := 4

# Decay and timers
var mugre_counter := 0
var decay_counter := 0

# Particulas
@onready var mugres_particles := $particulas_intoxicacion_m
var last_intoxicacion_particle_mode: Array
var last_curacion_particle_mode: Array
var frame_counter := 0
const FRAME_UPDATE_INTERVAL := 10 

# Movement
var origin_position: Vector2
var origin_rotation: float
const SPRING_STIFFNESS := 200.0



func _ready():
	origin_position = global_position
	origin_rotation = rotation
	randomize()
	nplanta = randi_range(1, 4)
	actualizar_sprite()
	crecimiento()

func _on_area_a_limpiar_body_entered(body: Node2D):
	if estado_planta == Estado.MUERTA:
		return
	if body is mugre:
		mugre_counter += 1
		body.add_to_group("mugre_in_area_planta")
		if mugre_counter >= 1:
			mugres_particles.emitting = true
		if mugre_counter >= 5:
			if estado_planta != Estado.INTOXICADA:
				$timer_intoxicacion.start()
				set_particles('intoxicacion', 'buildup')
			if estado_planta == Estado.INTOXICADA:
				$timer_curacion.stop()  # Cancel cure if it was running
				set_particles('curacion', 'off')


func _on_area_a_limpiar_body_exited(body: Node2D):
	if estado_planta == Estado.MUERTA:
		return
	if body is mugre:
		mugre_counter = max(0, mugre_counter - 1)
		if mugre_counter <= 0:
			mugres_particles.emitting = false
		body.remove_from_group("mugre_in_area_planta")
		if mugre_counter < 5:
			$timer_intoxicacion.stop()  # Cancel intox if not enough mugres
			set_particles('intoxicacion', 'off')
			if estado_planta == Estado.INTOXICADA and not planta_arrancada:
				$timer_curacion.start()
				set_particles('curacion', 'buildup')

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

func set_particles(particles: String, mode: String) -> void:
	if [particles, mode] == last_intoxicacion_particle_mode or [particles, mode] == last_curacion_particle_mode:
		return
	var p: CPUParticles2D
	
	match particles:
		"intoxicacion":
			p = $particulas_intoxicacion_p
			last_intoxicacion_particle_mode = [particles, mode]
		"curacion":
			p = $particulas_curacion_p
			last_curacion_particle_mode = [particles, mode]
		_:
			push_error("Unknown particle type: %s" % particles)
			return
	
	var tween := create_tween()
	tween.tween_property(p, "lifetime", 0.01, 1.0) \
		 .set_trans(Tween.TRANS_SINE) \
		 .set_ease(Tween.EASE_IN)
	await get_tree().create_timer(1.1).timeout
	p.lifetime = 2.0
	
	match mode:
		"off":
			p.emitting = false
			p.one_shot = false
			p.explosiveness = 0.0
		
		"buildup":
			p.emitting = true
			p.one_shot = false
			p.amount = 30
			p.explosiveness = 0.0
		
		"continuous":
			p.emitting = true
			p.one_shot = false
			p.amount = 2
			p.explosiveness = 0.0
		
		"burst":
			await get_tree().create_timer(0.1).timeout
			p.emitting = false
			p.one_shot = true
			p.amount = 30
			p.explosiveness = 1.0
			await get_tree().create_timer(0.1).timeout
			p.emitting = true
		
		_:
			push_error("Unknown mode: %s" % mode)
			return

func _on_area_a_regar_body_exited(body: Node2D):
	if body is agua and body.toco_piso:
		if planta_arrancada:
			set_planta_arrancada(false)
		if estado_planta == Estado.MUERTA:
			return
		if not planta_regada and not estado_planta == Estado.INTOXICADA:
			print('yay awita uwu')
			planta_regada = true
			$timer_regada.start()
			print('humedilla')
			await get_tree().create_timer(3.0).timeout
			set_particles('curacion', 'continuous')
			

func _on_timer_regada_timeout() -> void:
	if estado_planta == Estado.MUERTA:
		return
	print('sequilla')
	planta_regada = false
	set_particles('curacion', 'off')
	if decay_counter > 0:
		decay_counter = max(decay_counter - 1, 0)
		print("Decay counter reduced to ", decay_counter)
	if estado_planta == Estado.SANA and level < max_level:
		$timer_crecimiento.stop()
		planta_creciendo = false
		level += levelup # instant lvlup
		crecimiento()
	if da_frutos:
		pass

func _on_timer_intoxicacion_timeout():
	if estado_planta == Estado.MUERTA:
		return
	estado_planta = Estado.INTOXICADA
	levelup = 0
	$decay_intoxicacion.start()
	actualizar_sprite()
	set_particles('curacion', 'off')
	set_particles('intoxicacion', 'burst')
	await get_tree().create_timer(3.0).timeout
	set_particles('intoxicacion', 'continuous')

func _on_timer_curacion_timeout():
	if estado_planta == Estado.MUERTA:
		return
	estado_planta = Estado.SANA
	levelup = 1
	$decay_intoxicacion.stop()
	actualizar_sprite()
	set_particles('intoxicacion', 'off')
	set_particles('curacion', 'burst')
	crecimiento()

func crecimiento():
	if level >= max_level or estado_planta == Estado.MUERTA:
		return
	
	if not planta_creciendo:
		$timer_crecimiento.start()
		planta_creciendo = true

func _on_timer_crecimiento_timeout():
	if estado_planta == Estado.MUERTA:
		return
	if estado_planta == Estado.SANA and not planta_arrancada:
		planta_creciendo = false
		level = min(level + levelup, max_level)
		actualizar_sprite()
		if level == max_level:
			planta_crecida = true
			da_frutos = true
			$decay_vejez.start()
		else:
			crecimiento()

func actualizar_sprite():
	var sprite: String
	if estado_planta == Estado.SANA:
		if planta_arrancada:
			sprite = "p%d_a_%d" % [nplanta, level]
		else:
			sprite = "p%d_%d" % [nplanta, level]
	if estado_planta == Estado.INTOXICADA:
		if planta_arrancada:
			sprite = "p%d_i_a_%d" % [nplanta, level]
		else:
			sprite = "p%d_i_%d" % [nplanta, level]
	if estado_planta == Estado.MUERTA:
		if planta_arrancada:
			sprite = "p%d_m_a_%d" % [nplanta, level]
		else:
			sprite = "p%d_m_%d" % [nplanta, level]
	$sprite.play(sprite)

func _process(_delta):
	if estado_planta == Estado.MUERTA:
		set_process(false)
		return
	frame_counter += 1
	if frame_counter >= FRAME_UPDATE_INTERVAL:
		frame_counter = 0
		particulas_intoxicacion_mugres()

func _on_decay_intoxicacion_timeout() -> void:
	if estado_planta == Estado.MUERTA:
		return
	decay_counter = min(decay_counter + 1, 5)
	check_death()
	if estado_planta == Estado.INTOXICADA:
		$decay_intoxicacion.start()

func _on_decay_arrancada_timeout() -> void:
	if estado_planta == Estado.MUERTA:
		return
	decay_counter = min(decay_counter + 1, 5)
	check_death()
	if planta_arrancada:
		$decay_arrancada.start()

func _on_decay_vejez_timeout() -> void:
	if estado_planta == Estado.MUERTA:
		return
	decay_counter = min(decay_counter + 1, 5)
	check_death()
	if planta_crecida:
		$decay_vejez.start()

func check_death():
	print(decay_counter)
	if decay_counter >= 5:
		estado_planta = Estado.MUERTA
		actualizar_sprite()
		set_particles('intoxicacion', 'off')
		set_particles('curacion', 'off')
		mugres_particles.emitting = false
		var timers := [
		$timer_crecimiento, 
		$timer_regada, 
		$decay_intoxicacion, 
		$decay_arrancada, 
		$decay_vejez, 
		$timer_intoxicacion, 
		$timer_curacion,
		]
		for i in timers:
			i.stop()
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
	
	if not planta_arrancada:
		apply_force(force)
		apply_torque(torque)
		if distance_to_origin > 3.0:
			set_planta_arrancada(true)

func set_planta_arrancada(value: bool) -> void:
	if planta_arrancada == value:
		return  # No change, skip

	planta_arrancada = value
	levelup = 0 if value else 1
	actualizar_sprite()

	if value:
		$decay_arrancada.start()
		$area_a_limpiar.monitoring = false
		$timer_curacion.stop()
		$timer_intoxicacion.stop()
		planta_regada = false
		set_particles("curacion", "off")
		if estado_planta == Estado.INTOXICADA:
			set_particles("intoxicacion", "continuous")
		# Play arrancada sound
		$sfx_arrancada.stop()
		$sfx_arrancada.play()
	else:
		origin_position = global_position
		$decay_arrancada.stop()
		$area_a_limpiar.monitoring = true
		if mugre_counter < 5 and estado_planta == Estado.INTOXICADA:
			$timer_curacion.start()
			set_particles('curacion', 'buildup')
