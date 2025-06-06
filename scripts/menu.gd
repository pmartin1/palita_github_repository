extends CanvasLayer

@onready var panel = $Panel
@onready var vbox = $VBoxContainer
@onready var btn_continue = vbox.get_node("Continue")
@onready var btn_start = vbox.get_node("Start")
@onready var btn_save = vbox.get_node("Save")
@onready var btn_load = vbox.get_node("Load")
@onready var btn_restart = vbox.get_node("Restart")
@onready var btn_controls = vbox.get_node("Controls")
@onready var btn_options = vbox.get_node("Options")
#@onready var controls_screen = $ControlsScreen
#@onready var options_menu = $OptionsMenu

var game_started = false

func _ready():
	hide()
	btn_continue.visible = false

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		visible = not visible

func _on_Start_pressed():
	game_started = true
	btn_continue.visible = true
	visible = false
	get_tree().call_group("game", "start_game")

func _on_Continue_pressed():
	visible = false

#func _on_Save_pressed():
	#SaveSystem.save_game()
#
#func _on_Load_pressed():
	#SaveSystem.load_game()

func _on_Restart_pressed():
	get_tree().reload_current_scene()

#func _on_Controls_pressed():
	#controls_screen.show()
#
#func _on_Options_pressed():
	#options_menu.show()
