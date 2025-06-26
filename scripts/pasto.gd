extends StaticBody2D
class_name pasto

signal pasto_muerto_signal(pasto_ref)
signal reproducir_pasto_signal(ref)

# Core states - exclusive
enum Estado { SANO, INTOXICADO, MUERTO }
var estado_pasto: Estado = Estado.SANO

# Additional independent flags
var particles_exploding := false

# Growth
var creciendo := false
var npasto := 1
var level := 0
var levelup := 1
var max_level := 1
var hijo_pos : Vector2

# Decay and death counters
var mugre_counter := 0
var mugre_counter_reproduccion := 0
var pasto_counter := 0
var decay_counter := 0

# Timers
@export var tiempo_crecimiento := 60.0
@export var tiempo_reproduccion := 120.0
@export var tiempo_curacion := 10.0
@export var tiempo_intoxicacion := 10.0
@export var tiempo_decay_intox := 10.0

# Particles
var last_intoxicacion_particle_mode: Array
var last_curacion_particle_mode: Array
var frame_counter := 0
const FRAME_UPDATE_INTERVAL := 10

func _ready():
	$timer_crecimiento.set("wait_time", tiempo_crecimiento)
	$timer_reproduccion.set("wait_time", tiempo_reproduccion)
	$timer_curacion.set("wait_time", tiempo_curacion)
	$timer_intoxicacion.set("wait_time", tiempo_intoxicacion)
	$decay_intoxicacion.set("wait_time", tiempo_decay_intox)
	randomize()
	level = 0
	npasto = randi_range(1, 4)
	clamp(level, 0, max_level)
	if randf() > 0.5:
		$sprite.flip_h = true
	actualizar_sprite()
	particulas_intoxicacion()
	particulas_curacion()
	crecimiento()


func _on_area_a_limpiar_body_entered(body: Node2D):
	if estado_pasto == Estado.MUERTO:
		return
	if body is mugre:
		mugre_counter += 1
		body.add_to_group("mugre_in_area_planta")
		if mugre_counter >= 1:
			mugres_particles.emitting = true
		if mugre_counter >= 15:
			if estado_pasto != Estado.INTOXICADO:
				$timer_intoxicacion.start()
				set_particles('intoxicacion', 'buildup')
			if estado_pasto == Estado.INTOXICADO:
				$timer_curacion.stop()  # Cancel cure if it was running
				set_particles('curacion', 'off')


func _on_area_a_limpiar_body_exited(body: Node2D):
	if estado_pasto == Estado.MUERTO:
		return
	if body is mugre:
		mugre_counter = max(0, mugre_counter - 1)
		body.remove_from_group("mugre_in_area_planta")
		if mugre_counter <= 0:
			mugres_particles.emitting = false
		if mugre_counter < 15:
			$timer_intoxicacion.stop()  # Cancel intox if not enough mugres
			set_particles('intoxicacion', 'off')
			if estado_pasto == Estado.INTOXICADO:
				$timer_curacion.start()
				set_particles('curacion', 'buildup')


@onready var mugres_particles := $particulas_intoxicacion_m

func particulas_intoxicacion_mugres():
	
	var points: PackedVector2Array = []
	var normals: PackedVector2Array = []
	
	for body in get_tree().get_nodes_in_group("mugre_in_area_planta"):
		var mugre_pos = body.global_position
		var local_pos = mugres_particles.to_local(mugre_pos)
		var dir = Vector2.DOWN
		points.append(local_pos)
		normals.append(dir)
	
	mugres_particles.emission_points = points
	mugres_particles.emission_normals = normals


@onready var intox_particles := $particulas_intoxicacion_p

func particulas_intoxicacion():
	
	var points: PackedVector2Array = []
	var normals: PackedVector2Array = []
	var cant_origenes = 20
	
	for i in cant_origenes:
		randomize()
		var pos = global_position + Vector2(randf_range(-40, 40), randf_range(-20, 20))
		var local_pos = mugres_particles.to_local(pos)
		var dir = Vector2.UP
		points.append(local_pos)
		normals.append(dir)
	
	intox_particles.emission_points = points
	intox_particles.emission_normals = normals


@onready var curacion_particles := $particulas_curacion_p

func particulas_curacion():
	
	var points: PackedVector2Array = []
	var normals: PackedVector2Array = []
	var cant_origenes = 20
	
	for i in cant_origenes:
		randomize()
		var pos = global_position + Vector2(randf_range(-40, 40), randf_range(-20, 20))
		var local_pos = mugres_particles.to_local(pos)
		var dir = Vector2.UP
		points.append(local_pos)
		normals.append(dir)
	
	curacion_particles.emission_points = points
	curacion_particles.emission_normals = normals


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


func _on_timer_intoxicacion_timeout():
	estado_pasto = Estado.INTOXICADO
	levelup = 0
	actualizar_sprite()
	set_particles('intoxicacion', 'burst')
	await get_tree().create_timer(3.0).timeout
	set_particles('intoxicacion', 'continuous')


func _on_timer_curacion_timeout():
	set_particles('curacion', 'burst')
	estado_pasto = Estado.SANO
	levelup = 1
	actualizar_sprite()
	if not creciendo:
		crecimiento()


func _on_area_reproduccion_body_entered(body: Node2D) -> void:
	if body is mugre:
		mugre_counter_reproduccion += 1
	if body is pasto:
		pasto_counter = min(10, pasto_counter + 1)
		max_level = min(5, pasto_counter + 1)
		if not creciendo:
			crecimiento()


func _on_area_reproduccion_body_exited(body: Node2D) -> void:
	if body is mugre:
		mugre_counter_reproduccion -= 1
	if body is pasto:
		pasto_counter = max(0, pasto_counter - 1)


func crecimiento():
	if level >= max_level or estado_pasto == Estado.MUERTO:
		return
	
	if not creciendo:
		creciendo = true
		$timer_crecimiento.start()


func _on_timer_crecimiento_timeout():
	if estado_pasto == Estado.SANO:
		level += levelup
		actualizar_sprite()
		if level >= max_level:
			return
		else:
			creciendo = false
			crecimiento()
			emit_signal("reproducir_pasto_signal", self)
			$timer_reproduccion.stop()
			$timer_reproduccion.start()


func actualizar_sprite():
	var sprite: String
	if estado_pasto == Estado.SANO:
		sprite = "p%d_%d" % [npasto, level]
	if estado_pasto == Estado.INTOXICADO:
		sprite = "p%d_i_%d" % [npasto, level]
	if estado_pasto == Estado.MUERTO:
		sprite = "p%d_m_%d" % [npasto, level]
	$sprite.play(sprite)


func _process(_delta):
	if estado_pasto == Estado.MUERTO:
		set_process(false)
		return
	frame_counter += 1
	if frame_counter >= FRAME_UPDATE_INTERVAL:
		frame_counter = 0
		particulas_intoxicacion_mugres()


func _on_timer_reproduccion_timeout():
	if pasto_counter <= 10:
		emit_signal("reproducir_pasto_signal", self)
		$timer_reproduccion.start()


func _on_decay_intoxicacion_timeout():
	decay_counter = min(decay_counter + 1, 5)
	check_death()
	if estado_pasto == Estado.INTOXICADO:
		$decay_intoxicacion.start()


func check_death():
	if decay_counter >= 5:
		estado_pasto = Estado.MUERTO
		actualizar_sprite()
		var timers := [
			$timer_crecimiento,
			$timer_reproduccion,
			$decay_intoxicacion,
			$timer_intoxicacion,
			$timer_curacion,
			]
		for i in timers:
			i.stop()
		emit_signal("pasto_muerto_signal", self)
		set_process(false)
