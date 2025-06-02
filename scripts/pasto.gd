extends StaticBody2D
class_name pasto

signal pasto_muerto_signal(pasto_ref)

# Core states - exclusive
enum Estado { SANO, INTOXICADO, MUERTO }
var estado_pasto: Estado = Estado.SANO

# Additional independent flags
var pasto_crecido := false
var pasto_muerto := false

# Growth
var npasto := 1
var level := 0
var levelup := 1
var final_seed_level := 3

# Decay and timers
var mugre_counter := 0
var decay_counter := 0
var intoxicacion_start_time := 0.0
var start_proceso_intoxicacion := 0
var start_proceso_curacion := 0

# Animation
var animacion: String

# Constants
const TIEMPO_INTOXICACION := 10.0

func _ready():
	#randomize()
	level = 0
	animacion = "p_" + str(level)
	$sprite.play(animacion)
	crecimiento()

func _on_area_a_limpiar_body_entered(body: Node2D):
	if pasto_muerto:
		return
	if body is mugre:
		mugre_counter += 1
		print(mugre_counter)
	if mugre_counter >= 5 and estado_pasto != Estado.INTOXICADO:
			$timer_intoxicacion.start()
			$timer_curacion.stop()  # Cancel cure if it was running



func _on_area_a_limpiar_body_exited(body: Node2D):
	if pasto_muerto:
		return
	if body is mugre:
		mugre_counter = max(0, mugre_counter - 1)
		print(mugre_counter)
		if mugre_counter < 5:
			$timer_intoxicacion.stop()  # Cancel intox if not enough mugres
			if estado_pasto == Estado.INTOXICADO:
				$timer_curacion.start()

func _on_timer_intoxicacion_timeout():
	estado_pasto = Estado.INTOXICADO
	intoxicacion_start_time = Time.get_ticks_msec() / 1000.0
	levelup = 0
	$sprite.play(animacion + "_i")
	print("pasto INTOXICADO")

func _on_timer_curacion_timeout():
	estado_pasto = Estado.SANO
	levelup = 1
	decay_counter = 0
	$sprite.play(animacion)
	print("pasto SANO")
	crecimiento()

func crecimiento():
	if level >= final_seed_level or pasto_muerto:
		return
	
	await get_tree().create_timer(30.0).timeout
	
	if estado_pasto == Estado.SANO:
		level += levelup
		animacion = "p_" + str(level)
		$sprite.play(animacion)
		#if estado_pasto == Estado.INTOXICADO:
			#$sprite.play(animacion + "_i")
		if level == final_seed_level:
			pasto_crecido = true
			print("pasto crecido")
		else:
			crecimiento()

func _process(_delta):
	var time_now = Time.get_ticks_msec() / 1000.0
	
	if pasto_muerto:
		return
	
	if estado_pasto == Estado.INTOXICADO and time_now - intoxicacion_start_time > TIEMPO_INTOXICACION:
		decay_counter += 1
		print ('decay ', decay_counter)
		intoxicacion_start_time = time_now
	
	
	if decay_counter >= 5:
		estado_pasto = Estado.MUERTO
		pasto_muerto = true
		$sprite.play(animacion + "_m")

		emit_signal("pasto_muerto_signal", self)
