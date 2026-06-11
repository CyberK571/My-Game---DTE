extends CharacterBody2D

const SPEED = 100.0
@onready var sprite = $Sprite2D

func _physics_process(delta):
	var dir = Vector2.ZERO
	dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	if dir != Vector2.ZERO:
		velocity = dir.normalized() * SPEED
		update_animation(dir, true)
	else:
		velocity = Vector2.ZERO
		update_animation(dir, false)

	move_and_slide()

func update_animation(dir: Vector2, moving: bool):
	var prefix = "Walk_" if moving else "Idle_"

	if abs(dir.x) > abs(dir.y):
		sprite.flip_h = dir.x < 0
		sprite.play(prefix + "side")
	elif dir.y > 0:
		sprite.flip_h = false
		sprite.play(prefix + "down")
	elif dir.y < 0:
		sprite.flip_h = false
		sprite.play(prefix + "up")
