extends KinematicBody2D

const UP = Vector2(0, -1)

const SPEED = 60
const GRAVITY = 260
const JUMP_SPEED = -180
const FLOOR_TIMER = 0.1

var movement = Vector2()
var last_anim = 0
var on_floor_timer = 0

func _ready():
	$Sprite.playing = true
	set_safe_margin(0.01)
	
func set_anim(anim):
	if anim == last_anim:
		return
	last_anim = anim
	if anim == 1:
		$Sprite.animation = "Idle"
	if anim == 2:
		$Sprite.animation = "Run"
	if anim == 3:
		$Sprite.animation = "Crouch"
	if anim == 4:
		$Sprite.animation = "Jump"
	if anim == 5:
		$Sprite.animation = "Fall"
	
func _physics_process(delta):
	var on_floor = on_floor_timer > 0
	
	if on_floor:
		movement.y = 0
	
	movement.y += GRAVITY * delta
	
	var moved = false
	
	var input_left = Input.is_action_pressed("ui_left")
	var input_right = Input.is_action_pressed("ui_right")
	var input_crouch = Input.is_action_pressed("ui_down")
	var input_jump = Input.is_action_just_pressed("ui_up")
	
	if input_left and not input_right and not input_crouch:
		movement.x = -SPEED
		$Sprite.flip_h = true
		if on_floor:
			moved = true
	elif input_right and not input_left and not input_crouch:
		movement.x = SPEED
		$Sprite.flip_h = false
		if on_floor:
			moved = true
	else:
		movement.x = 0
		if input_left and not input_right:
			$Sprite.flip_h = true
		elif input_right and not input_left:
			$Sprite.flip_h = false
	
	if input_crouch and on_floor:
		set_anim(3)
	else:
		if on_floor:
			if moved:
				set_anim(2)
			else:
				set_anim(1)
		else:
			if movement.y < 0:
				set_anim(4)
			else:
				set_anim(5)
	
	if on_floor:
		if input_jump:
			movement.y = JUMP_SPEED
			on_floor_timer = -1
	
	var new_movement = move_and_slide(movement, UP, 2)
	movement.x = new_movement.x
	if is_on_floor():
		on_floor_timer = FLOOR_TIMER
	else:
		if on_floor_timer > -1:
			on_floor_timer -= delta
	
	$Label.text = "  %3.1f  %3.1f %3.1f" % [on_floor_timer, movement.y, get_safe_margin()]
	
