extends RigidBody2D
class_name mugre

#enum State { NORMAL, ORBITING, FALLING }
#
#@export var orbit_duration := 100
#@export var orbit_radius := 50.0
#@export var orbit_speed := 0.3
#@export var orbit_trigger_y := 0.0
#
#var state = State.NORMAL
#var orbit_angle := 0.0
#var orbit_timer := 0.0
#var orbit_center := Vector2.ZERO
#
#func _physics_process(delta):
	#if state == State.NORMAL:
		#if global_position.y < orbit_trigger_y:
			#enter_orbit()
	#elif state == State.FALLING:
		## Let physics take over
		#pass
#
#func _process(delta):
	#if state == State.ORBITING:
		#orbit_timer -= delta
		#orbit_angle += orbit_speed * delta
		#global_position = orbit_center + Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius
		#if orbit_timer <= 0:
			#exit_orbit()
#
#func enter_orbit():
	#state = State.ORBITING
	#freeze = true
	#sleeping = true
	#linear_velocity = Vector2.ZERO
	#orbit_angle = 0.0
	#orbit_timer = orbit_duration
	#orbit_radius = global_position.x 
#
#func exit_orbit():
	#state = State.FALLING
	#freeze = false
	#sleeping = false
	#linear_velocity = Vector2(0, 300)
		
func _ready():
	randomize()
	sleeping = true
	can_sleep = true
	gravity_scale = 0
