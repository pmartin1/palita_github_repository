extends RigidBody2D
class_name agua

signal agua_toco_piso_signal(agua_ref)

var origin_position_y : float
var piso_threshold : float
var toco_piso := false
var in_copa := false

func _ready() -> void:
	randomize()
	origin_position_y = global_position.y
	piso_threshold = 15.0
	var nagua = randi_range(1, 7)
	var agua_sel: String = "agua_" + str(nagua)
	$agua_anim.play(agua_sel)

func cuando_toca_piso():
	var actual_position_y = global_position.y
	if actual_position_y - origin_position_y > piso_threshold and not in_copa:
		toco_piso = true
		freeze = true
		$agua_anim.play('agua_splash')
		$collsh_agua.disabled = true
		gravity_scale = 0.0
		rotation_degrees = -16
		skew = -45.0
		scale = Vector2(2, 2)
		emit_signal("agua_toco_piso_signal", self)
		
func _physics_process(_delta: float):
	if not toco_piso:
		cuando_toca_piso()
	else:
		set_physics_process(false)
