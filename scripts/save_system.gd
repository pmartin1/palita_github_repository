extends Node

var save_path_template := "user://save_slot_{0}.save"
var current_save_slot := 1  # Change as needed

func save_game(slot: int = current_save_slot):
	var data = {
		"player_position": get_tree().get_root().get_node("Main").player.global_position,
		"custom_vars": {
			"min_spawn_radius": 35.0,
			"max_spawn_radius": 220.0,
			# Add more game state vars here
		}
	}
	var file = FileAccess.open(save_path_template.format([slot]), FileAccess.WRITE)
	file.store_var(data)
	file.close()

func load_game(slot: int = current_save_slot):
	var path = save_path_template.format([slot])
	if not FileAccess.file_exists(path):
		print("No save found.")
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var data = file.get_var()
	file.close()

	var main = get_tree().get_root().get_node("mundo")
	main.player.global_position = data["player_position"]
	# Restore other data as needed
