extends Area2D
class_name area_checker

var mugre_counter := 0
var area_limpia := true
var pasto_detected := false
var spawn_planta := false
var spawn_pasto := false
var none_detected := true
var inside_spawn_boundary := false #reproduccion pasto

func _ready() -> void:
	mugre_counter = 0
	await get_tree().create_timer(0.5).timeout
	spawn_check()

func _on_body_entered(body: Node2D) -> void:
	none_detected = false
	
	var distance_x = abs(global_position.x - body.global_position.x)
	var distance_y_iso = abs(global_position.y - body.global_position.y) *2
	var distance_to_body = Vector2(distance_x, distance_y_iso).length()
	
	if body is planta:
		if distance_to_body < 7.0:
			area_limpia = false
	
	elif body is corazon_mundo:
		area_limpia = false
	
	elif body is mugre:
		mugre_counter += 1
		if mugre_counter > 15:
			area_limpia = false
	
	elif body is pasto:
		pasto_detected = true
		spawn_check()
	
	else:
		none_detected = true
		spawn_check()

func _on_area_shape_entered(_area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	if area is area_checker:
		area_limpia = false


func spawn_check():
	if not area_limpia:
		return
	if pasto_detected:
		spawn_planta = true
	elif none_detected:
		spawn_pasto = true
