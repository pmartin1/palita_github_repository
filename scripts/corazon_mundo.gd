extends StaticBody2D
class_name corazon_mundo

func _on_area_teleport_body_entered(body: Node2D) -> void:

	if body is mugre:
		body.add_to_group("mugre_teleport")
		particulas_intoxicacion_mugres()
		body.entered_through_corazon_mundo = true
		body.phase = PI
		body.snap_pos = body.global_position.normalized() * Vector2(500, 250)
		body.set_orbit_mode()
		body.enter_orbit_from_snap()

func _on_area_teleport_body_exited(body: Node2D) -> void:
	if body is mugre:
		body.remove_from_group("mugre_teleport")
		await get_tree().create_timer(5.0).timeout
		body.entered_through_corazon_mundo = false


@onready var mugres_particles := $mugre_teleport

func particulas_intoxicacion_mugres():
	
	var points: PackedVector2Array = []
	
	for body in get_tree().get_nodes_in_group("mugre_teleport"):
		var mugre_pos = body.global_position
		var local_pos = mugres_particles.to_local(mugre_pos)
		points.append(local_pos)
	
	mugres_particles.emission_points = points
	mugres_particles.emitting = true


func _on_area_repulsion_body_entered(body: Node2D) -> void:
	if body is mugre:
		if not body.entered_through_corazon_mundo:
			body.set_rigid_mode()
			body.add_to_group("atraer")


func _on_area_repulsion_body_exited(body: Node2D) -> void:
	if body is mugre:
		body.remove_from_group("atraer")

var frame_count := 0
var actualizar : mugre
func _process(_delta: float) -> void:
	frame_count += 1
	if frame_count >= 10:
		for body in get_tree().get_nodes_in_group("atraer"):
			if body.current_mode != body.MugreMode.RIGID and not body.entered_through_corazon_mundo:
				body.set_rigid_mode()
			var direction = body.global_position.direction_to(global_position).normalized()
			body.apply_impulse(direction * 10)
