extends Area2D
class_name area_checker

var area_limpia := true #creo que se puede prescindir de este flag
var mugre_counter := 0
var planta_counter := 0
var pasto_counter := 0
var spawn_planta := false
var spawn_pasto := false
var none_detected := true
var inside_spawn_boundary : bool

func _ready() -> void:
	mugre_counter = 0
	await get_tree().create_timer(0.5).timeout
	if none_detected:
		spawn_pasto = true

func _on_body_entered(body: Node2D) -> void:
	none_detected = false
	
	# cambiar por funcion match?
	if body is planta:
		if global_position.distance_to(body.global_position) < 7:
			area_limpia = false
	
	if body is corazon_mundo:
		area_limpia = false
	
	if body is pasto:
		pasto_counter += 1
	
	if body is mugre:
		mugre_counter += 1
		if mugre_counter > 10:
			area_limpia = false
		else:
			area_limpia = true
			spawn_check()
	else:
		spawn_check()

func _on_body_exited(body: Node2D) -> void:
	if body is mugre:
		mugre_counter -= 1

	if body is pasto:
		pasto_counter -= 1

func spawn_check():
	if pasto_counter >= 1:
		spawn_planta = true
	else:
		spawn_pasto = true
