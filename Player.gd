extends KinematicBody2D

const UP = Vector2(0, -1)

const SPEED = 60
const GRAVITY = 260
const JUMP_SPEED = -180

var movement = Vector2()
var last_anim = 0

func _ready():
	$Sprite.playing = true
	
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
	movement.y += GRAVITY * delta
	if Input.is_action_pressed("ui_left"):
		movement.x = -SPEED
		$Sprite.flip_h = true
		if is_on_floor():
			set_anim(2)
	elif Input.is_action_pressed("ui_right"):
		movement.x = SPEED
		$Sprite.flip_h = false
		if is_on_floor():
			set_anim(2)
	elif Input.is_action_pressed("ui_down") and is_on_floor():
		set_anim(3)
	else:
		if is_on_floor():
			set_anim(1)
		if movement.y < 0:
			set_anim(4)
		else:
			set_anim(5)
	
	if is_on_floor():
		if Input.is_action_just_pressed("ui_up"):
			movement.y = JUMP_SPEED
		else:
			movement.y = 0
		
	movement = move_and_slide(movement, UP)
	
	
	
	
