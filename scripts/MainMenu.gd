extends Control
@onready var boton_start = $VBoxContainer/StartButton
@onready var boton_credits = $VBoxContainer/CreditsButton
@onready var boton_settings = $VBoxContainer/SettingsButton
@onready var settings_panel = $SettingsPanel
@onready var credits_panel = $CreditsPanel
@onready var close_settings = $SettingsPanel/CloseButton
@onready var close_credits = $CreditsPanel/CloseButton


func _set_buttons_disabled(x) -> void:
	boton_credits.set ("disabled", x)
	boton_start.set ("disabled", x)
	boton_settings.set ("disabled", x)

func _ready():
	credits_panel.set ("visible", false)
	settings_panel.set ("visible", false)
	
	$VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$VBoxContainer/SettingsButton.pressed.connect(_on_controls_pressed)
	$VBoxContainer/CreditsButton.pressed.connect(_on_credits_pressed)

	$SettingsPanel/CloseButton.pressed.connect(_on_close_controls)
	$CreditsPanel/CloseButton.pressed.connect(_on_close_credits)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/mundo.tscn")

func _on_controls_pressed():
	$SettingsPanel.visible = true
	_set_buttons_disabled(true)

func _on_credits_pressed():
	$CreditsPanel.visible = true
	_set_buttons_disabled(true)

func _on_close_controls():
	$SettingsPanel.visible = false
	_set_buttons_disabled(false)

func _on_close_credits():
	$CreditsPanel.visible = false
	_set_buttons_disabled(false)
