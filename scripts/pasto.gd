extends StaticBody2D
class_name pasto

signal pasto_muerto_signal(pasto_ref)
signal reproducir_pasto_signal(pasto_ref)

# Core states - exclusive
enum Estado { SANO, INTOXICADO, MUERTO }
var estado_pasto: Estado = Estado.SANO

# Additional independent flags
var pasto_muerto := false

# Growth
var creciendo := false
var npasto := 1
var level := 0
var levelup := 1
var final_seed_level := 1
var hijo_pos : Vector2
@export var timer_crecimiento := 60

# Decay and death counters
var mugre_counter := 0
var mugre_counter_reproduccion := 0
var pasto_counter := 0
var decay_counter := 0
var intoxicacion_start_time := 0.0
var start_proceso_intoxicacion := 0
var start_proceso_curacion := 0

# Animation
var animacion: String

# Constants
const TIEMPO_INTOXICACION := 10.0

func _ready():
	randomize()
	level = 0
	npasto = randi_range(1, 4)
	animacion = "p" + str(npasto) + "_" + str(level)
	actualizar_sprite()
	if randf() > 0.5:
		$sprite.flip_h = true
	if not creciendo:
		crecimiento()

func _on_area_a_limpiar_body_entered(body: Node2D):
	if pasto_muerto:
		return
	if body is mugre:
		mugre_counter += 1
		print(mugre_counter)
		body.add_to_group("mugre_in_area_planta")
		if mugre_counter > 1:
			mugres_particles.emitting = true
	if mugre_counter >= 15 and estado_pasto != Estado.INTOXICADO:
			$timer_intoxicacion.start()
			$timer_curacion.stop()  # Cancel cure if it was running
			$particulas_intoxicacion_p.explosiveness = 0
			$particulas_intoxicacion_p.one_shot = false
			$particulas_intoxicacion_p.emitting = true

func _on_area_a_limpiar_body_exited(body: Node2D):
	if pasto_muerto:
		return
	if body is mugre:
		mugre_counter = max(0, mugre_counter - 1)
		print(mugre_counter)
		body.remove_from_group("mugre_in_area_planta")
		if mugre_counter <= 0:
			mugres_particles.emitting = false
		if mugre_counter < 15:
			$timer_intoxicacion.stop()  # Cancel intox if not enough mugres
			$particulas_intoxicacion_p.emitting = false
			if estado_pasto == Estado.INTOXICADO:
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
		var dir = Vector2.DOWN
		points.append(local_pos)
		normals.append(dir) 
	
	mugres_particles.emission_points = points
	mugres_particles.emission_normals = normals

@onready var intox_particles := $particulas_intoxicacion_p

func particulas_intoxicacion():
	
	var points: PackedVector2Array = []
	var normals: PackedVector2Array = []
	var cant_origenes = 10
	
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
	var cant_origenes = 10
	
	for i in cant_origenes:
		randomize()
		var pos = global_position + Vector2(randf_range(-40, 40), randf_range(-20, 20))
		var local_pos = mugres_particles.to_local(pos)
		var dir = Vector2.UP
		points.append(local_pos)
		normals.append(dir)
	
	curacion_particles.emission_points = points
	curacion_particles.emission_normals = normals

func _on_timer_intoxicacion_timeout():
	$particulas_intoxicacion_p.explosiveness = 1.0
	await get_tree().create_timer(2.1).timeout
	$particulas_intoxicacion_p.one_shot = true
	estado_pasto = Estado.INTOXICADO
	intoxicacion_start_time = Time.get_ticks_msec() / 1000.0
	levelup = 0
	actualizar_sprite()
	print("pasto INTOXICADO")

func _on_timer_curacion_timeout():
	$particulas_curacion_p.explosiveness = 1.0
	await get_tree().create_timer(2.1).timeout
	$particulas_curacion_p.one_shot = true
	estado_pasto = Estado.SANO
	levelup = 1
	decay_counter = 0
	actualizar_sprite()
	print("pasto SANO")
	if not creciendo:
		crecimiento()


func _on_area_reproduccion_body_entered(body: Node2D) -> void:
	if body is mugre:
		mugre_counter_reproduccion += 1
	if body is pasto:
		pasto_counter = min(4, pasto_counter + 1)
		final_seed_level = pasto_counter + 1
		if not creciendo:
			crecimiento()


func _on_area_reproduccion_body_exited(body: Node2D) -> void:
	if body is mugre:
		mugre_counter_reproduccion -= 1
	if body is pasto:
		pasto_counter = max(0, pasto_counter - 1)


func crecimiento():
	if level >= final_seed_level or pasto_muerto or creciendo:
		return
	
	creciendo = true
	await get_tree().create_timer(timer_crecimiento).timeout
	if estado_pasto == Estado.SANO:
		level += levelup
		animacion = "p" + str(npasto) + "_" + str(level)
		actualizar_sprite()
		if level >= final_seed_level:
			return
		else:
			creciendo = false
			crecimiento()
			emit_signal("reproducir_pasto_signal", self)

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
	var time_now = Time.get_ticks_msec() / 1000.0
	
	if pasto_muerto:
		return
	
	particulas_intoxicacion_mugres()
	particulas_intoxicacion()
	particulas_curacion()
	
	if estado_pasto == Estado.INTOXICADO and time_now - intoxicacion_start_time > TIEMPO_INTOXICACION:
		decay_counter += 1
		intoxicacion_start_time = time_now
	
	
	if decay_counter >= 5:
		estado_pasto = Estado.MUERTO
		pasto_muerto = true
		actualizar_sprite()

		emit_signal("pasto_muerto_signal", self)
