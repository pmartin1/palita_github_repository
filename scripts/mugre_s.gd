extends mugre

var nmugre := 1

func _ready() -> void:
	randomize()
	nmugre = randi_range(1, 12)
	var mugre_sel: String = "mugre_" + str(nmugre)
	$mugre_s.play(mugre_sel)
