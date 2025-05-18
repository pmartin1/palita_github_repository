extends RigidBody2D

var rand
var nmugre = 1

func sel_mugre():
	# Disable all collision shapes first
	$mugre_1.visible = false
	$collmugre_1.disabled = true
	$mugre_2.visible = false
	$collmugre_2.disabled = true
	$mugre_3.visible = false
	$collmugre_3.disabled = true
	$mugre_4.visible = false
	$collmugre_4.disabled = true
	$mugre_5.visible = false
	$collmugre_5.disabled = true
	$mugre_6.visible = false
	$collmugre_6.disabled = true
	
	# Enable only the one corresponding to current mode
	match nmugre:
		1:
			$mugre_1.visible = true
			$collmugre_1.disabled = false
		2:
			$mugre_2.visible = true
			$collmugre_2.disabled = false
		3:
			$mugre_3.visible = true
			$collmugre_3.disabled = false
		4:
			$mugre_4.visible = true
			$collmugre_4.disabled = false
		5:
			$mugre_5.visible = true
			$collmugre_5.disabled = false
		6:
			$mugre_6.visible = true
			$collmugre_6.disabled = false

func _ready() -> void:
	randomize()
	nmugre = randi_range(1, 6)  # ✅ Use the class-level variable
	sel_mugre()
