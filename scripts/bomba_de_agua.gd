extends StaticBody2D

signal stop_player_movement_signal()
signal restore_player_movement_signal()
signal spawn_agua_signal(bomba_ref)

var dragging := false
var drag_strength: float
const UP_DRAG_STRENGTH := 8.0 
const DOWN_DRAG_STRENGTH := 2.0 # lower means harder
var mouse_pos: Vector2
var to_mouse: Vector2
var rotation_target := 0.0

var spawn_area: Vector2
var agua_spawn_cooldown := 0.05 # seconds between spawns
var agua_spawn_timer := 0.0

func _ready():
	spawn_area = $spawn_area/spawn_area_collsh.global_position
	var player = get_parent().get_node("jugador")
	connect("stop_player_movement_signal", Callable(player, "_on_stop_player_movement"))
	connect("restore_player_movement_signal", Callable(player, "_on_restore_player_movement"))
	var mundo = get_parent()
	connect("spawn_agua_signal", Callable(mundo, "_on_spawn_agua"))

func _process(delta):
	if dragging:
		mouse_pos = get_global_mouse_position()
		to_mouse = mouse_pos - $brazo.global_position
		rotation_target = to_mouse.angle() - PI/2
		if to_mouse.y < 0:
			drag_strength = UP_DRAG_STRENGTH
		else:
			drag_strength = DOWN_DRAG_STRENGTH
		var lerp_brazo_rotation = lerp_angle($brazo.rotation, rotation_target, delta * DOWN_DRAG_STRENGTH)
		var clamped_lerp_brazo_rotation = clamp(lerp_brazo_rotation, 0, PI/2)
		$brazo.rotation = clamped_lerp_brazo_rotation
		
		var diferencial_manija = abs(rotation_target) - abs(lerp_brazo_rotation)
		# Update timer
		agua_spawn_timer -= delta
		if diferencial_manija < -0.2 and agua_spawn_timer <= 0:
			agua_spawn_timer = agua_spawn_cooldown
			emit_signal("spawn_agua_signal", self)
	else:
		rotation_target = 0.0
		$brazo.rotation = lerp_angle($brazo.rotation, rotation_target, delta * DOWN_DRAG_STRENGTH)
		agua_spawn_timer -= delta/10
		if agua_spawn_timer <= 0:
			agua_spawn_timer = agua_spawn_cooldown
			emit_signal("spawn_agua_signal", self)
		if $brazo.rotation <= 0.01:
			set_process(false)
	
	var start_point = Vector2(0, -11.0) # Fixed anchor point in ChainLine's local space
	var brazo_tip_local = Vector2(4.0, -11.0) # Right edge
	var brazo_tip_global = $brazo.to_global(brazo_tip_local)
	var tip_in_chain_space = $cadena.to_local(brazo_tip_global)
	
	$cadena.points = [start_point, tip_in_chain_space]

func _on_manija_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed('click_izq'):
		dragging = true
		set_process(true)
		emit_signal("stop_player_movement_signal")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released('click_izq'):
		dragging = false
		emit_signal("restore_player_movement_signal")
