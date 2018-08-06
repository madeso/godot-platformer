extends KinematicBody2D

var Dev = preload("res://Dev.gd")

const UP = Vector2(0, -1)

const MAX_SPEED = 100
const ACCELERATION = 300
const AIR_ACCELERATION = 25
const FRICTION = 170
const CROUCH_FRICTION = 25
const AIR_FRICTION = 10

const GRAVITY = 260
const JUMP_SPEED = -90
const JUMP_TIME = 0.3
const CROUCH_JUMP_EXTRA_TIME = 0.2
const FLOOR_TIMER = 0.1
const CROUCH_TIMER = 0.2

# single double jump, less powerful than standard jump
const MULTI_JUMPS = 1
const MULTI_JUMP_TIMER = 0.2
const MULTI_JUMP_SPEED_CHECK = 40

const WALL_JUMP_HOR_SPEED = 60

enum Anim {
	INVALID, Idle, Run, Crouch, Jump, Fall
}

var movement = Vector2()
var last_anim = Anim.INVALID
var on_floor_timer = 0
var jump_timer = 0
var crouch_timer = 0
var multi_jump = 0
var on_wall_timer = 0

func pickup_gem():
	print("todo: add score or something")
	Dev.play_sound($GemSfx)

func _ready():
	$Sprite.playing = true
	set_safe_margin(0.01)

func set_collision_default():
	$CollisionShape2D.position = Vector2(-1, 6)
	$CollisionShape2D.shape.extents = Vector2(9, 10)

func set_collision_crouch():
	$CollisionShape2D.position = Vector2(-1, 9)
	$CollisionShape2D.shape.extents = Vector2(9, 7)

func set_anim(anim):
	if anim == last_anim:
		return
	last_anim = anim
	if anim == Anim.Idle:
		$Sprite.animation = "Idle"
		set_collision_default()
	if anim == Anim.Run:
		$Sprite.animation = "Run"
		set_collision_default()
	if anim == Anim.Crouch:
		$Sprite.animation = "Crouch"
		set_collision_crouch()
	if anim == Anim.Jump:
		$Sprite.animation = "Jump"
		set_collision_default()
	if anim == Anim.Fall:
		$Sprite.animation = "Fall"
		set_collision_default()
	
func get_collision_box_y():
	return {
		y=$CollisionShape2D.position.y,
		half=$CollisionShape2D.shape.extents.y
		}

func can_stand():
	if last_anim == Anim.Crouch:
		set_collision_default()
		var def = get_collision_box_y()
		set_collision_crouch()
		var cr = get_collision_box_y()
		var dy = (def.y - def.half) - (cr.y - cr.half)
		var lower_dy = (def.y + def.half) - (cr.y + cr.half)
		assert lower_dy == 0
		var stand_col = test_move(transform, Vector2(0, dy))
		return not stand_col
	else:
		return true
	
func _physics_process(delta):
	var on_floor = on_floor_timer > 0
	var on_wall = on_wall_timer > 0
	
	if on_floor:
		movement.y = 0
	
	movement.y += GRAVITY * delta
	
	var moved = false
	
	var input_left = Input.is_action_pressed("ui_left")
	var input_right = Input.is_action_pressed("ui_right")
	var input_crouch = Input.is_action_pressed("ui_down")
	var input_jump = Input.is_action_just_pressed("ui_up")
	var input_jump_hold = Input.is_action_pressed("ui_up")
	
	if not input_crouch and last_anim == Anim.Crouch and not can_stand():
		input_crouch = true
	
	var acceleration = ACCELERATION
	if not on_floor:
		acceleration = AIR_ACCELERATION
	
	if input_left and not input_right and not input_crouch:
		movement.x = max(movement.x-acceleration*delta, -MAX_SPEED)
		$Sprite.flip_h = true
		if on_floor:
			moved = true
	elif input_right and not input_left and not input_crouch:
		movement.x = min(movement.x+acceleration*delta, MAX_SPEED)
		$Sprite.flip_h = false
		if on_floor:
			moved = true
	else:
		var friction = FRICTION
		if input_crouch:
			crouch_timer = 0
			friction = CROUCH_FRICTION
			if on_floor and not can_stand():
				friction = 0
		if not on_floor:
			friction = AIR_FRICTION
		# do friction
		movement.x = sign(movement.x) * max(abs(movement.x)-friction*delta, 0)
		
		if input_left and not input_right:
			$Sprite.flip_h = true
		elif input_right and not input_left:
			$Sprite.flip_h = false
	
	if not input_crouch:
		if crouch_timer < CROUCH_TIMER:
			crouch_timer += delta
		else:
			crouch_timer = CROUCH_TIMER + 1
	
	if input_crouch and on_floor:
		set_anim(Anim.Crouch)
	else:
		if on_floor:
			if moved:
				set_anim(Anim.Run)
			else:
				set_anim(Anim.Idle)
		else:
			if movement.y < 0:
				set_anim(Anim.Jump)
			else:
				set_anim(Anim.Fall)
	
	if on_floor:
		multi_jump = MULTI_JUMPS
	
	if input_jump and not input_crouch:
		var do_jump = false
		if on_floor:
			do_jump = true
			if crouch_timer < CROUCH_TIMER:
				jump_timer = -CROUCH_JUMP_EXTRA_TIME
				Dev.play_sound($JumpCrouch)
			else:
				Dev.play_sound($JumpSfx)
				jump_timer = 0
		elif on_wall:
			var dir = -1
			if $Sprite.flip_h:
				dir = 1
			movement.x = dir * WALL_JUMP_HOR_SPEED
			do_jump = true
			jump_timer = 0
			multi_jump = MULTI_JUMPS
			Dev.play_sound($JumpWallSfx)
		elif multi_jump > 0 and abs(movement.y) < MULTI_JUMP_SPEED_CHECK:
			multi_jump -= 1
			do_jump = true
			jump_timer = MULTI_JUMP_TIMER
			Dev.play_sound($MultiJumpSfx)
		else:
			if multi_jump > 0:
				# print(abs(movement.y))
				$Label.text = "  %3.3f" % [movement.y]
				pass
			
		if do_jump:
			movement.y = JUMP_SPEED
			on_floor_timer = -1
	
	if not on_floor:
		if input_jump_hold:
			if jump_timer < JUMP_TIME:
				jump_timer += delta
			if jump_timer < JUMP_TIME:
				movement.y = JUMP_SPEED
		else:
			jump_timer = JUMP_TIME + 1
	
	movement = move_and_slide(movement, UP, 0.1)
	
	if is_on_floor():
		on_floor_timer = FLOOR_TIMER
	else:
		if on_floor_timer > -1:
			on_floor_timer -= delta
	
	if is_on_wall():
		on_wall_timer = FLOOR_TIMER
	else:
		if on_wall_timer > -1:
			on_wall_timer -= delta
	
	#$Label.text = "  %s" % [on_wall]
	
