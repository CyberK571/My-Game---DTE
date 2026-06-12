extends CharacterBody2D

const SPEED = 250.0

func _physics_process(delta):
	var dir = Vector2.ZERO
	
	if Input.is_action_pressed("ui_up"):
		dir.x += 1
	if Input.is_action_pressed("ui_down"):
		dir.x -= 1
	if Input.is_action_pressed("ui_right"):
		dir.y += 1
	if Input.is_action_pressed("ui_left"):
		dir.y -= 1
	
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		velocity = dir * SPEED
		play_walk_animation(dir)
	else:
		velocity = Vector2.ZERO
		play_idle_animation()
	
	move_and_slide()

func play_walk_animation(dir):
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			$Sprite2D.play("Walk_right")
		else:
			$Sprite2D.play("Walk_left")
	else:
		if dir.y > 0:
			$Sprite2D.play("Walk_down")
		else:
			$Sprite2D.play("Walk_up")

func play_idle_animation():
	var anim = $Sprite2D.animation
	if anim.begins_with("Walk"):
		$Sprite2D.play(anim.replace("Walk", "Idle"))
