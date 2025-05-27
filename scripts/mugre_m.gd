extends mugre

func _ready() -> void:
	randomize()
	var nmugre = randi_range(1, 12)
	var mugre_sel: String = "mugre_" + str(nmugre)
	$mugre_m.play(mugre_sel) # off by default
