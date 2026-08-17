extends CharacterBody2D

var speed = 330.0
var normal_speed = 330.0
var dash_speed = 600.0
var dash_time = 0.2
var dash_cooldown = 0.8
var is_dashing = false
var can_dash = true
var is_attacking = false
var last_dir = Vector2.DOWN
var max_health = 3
var current_health = 3
var is_invincible = false
var keys_collected = 0
@export var keys_required = 3
var shield_active = false
var can_shield = true

@onready var hearts = [$CanvasLayer/Heart1, $CanvasLayer/Heart2, $CanvasLayer/Heart3]
@export var full_heart_texture: Texture2D
@export var empty_heart_texture: Texture2D
@export var invincible_time = 1.0
@onready var key_label = $CanvasLayer/KeyLabel

func _ready():
	update_hearts()
	update_key_label()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		activate_shield()

func activate_shield():
	if not can_shield or shield_active:
		return
	can_shield = false
	shield_active = true

	$ParryFlash.visible = true
	$ParryFlash.play_flash()
	flash_player_white()

	await get_tree().create_timer(2.0).timeout
	shield_active = false
	await $ParryFlash.fade_out()
	$ParryFlash.visible = false

	await get_tree().create_timer(2.0).timeout
	can_shield = true

func flash_player_white():
	var tween = create_tween()
	tween.tween_property($PlayerAnim, "modulate", Color(2, 2, 2, 1), 0.08)
	tween.tween_property($PlayerAnim, "modulate", Color(1, 1, 1, 1), 0.15)
	
func take_damage(amount = 1):
	if is_invincible:
		return

	current_health -= amount
	update_hearts()
	flash_hurt()

	if current_health <= 0:
		die()
	else:
		is_invincible = true
		await get_tree().create_timer(invincible_time).timeout
		is_invincible = false

func collect_key():
	keys_collected += 1
	update_key_label()
	
func heal_full():
	current_health = max_health
	update_hearts()

func update_key_label():
	key_label.text = "Keys: " + str(keys_collected) + "/" + str(keys_required)

func flash_key_label_red():
	var normal_color = Color(1, 1, 1, 1)
	for i in 3:
		key_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		await get_tree().create_timer(0.15).timeout
		key_label.add_theme_color_override("font_color", normal_color)
		await get_tree().create_timer(0.15).timeout

func update_hearts():
	for i in hearts.size():
		if i < current_health:
			hearts[i].modulate.a = 1.0
		else:
			hearts[i].modulate.a = 0.3

func flash_hurt():
	var tween = create_tween()
	tween.tween_property($PlayerAnim, "modulate", Color(1, 0.3, 0.3), 0.1)
	tween.tween_property($PlayerAnim, "modulate", Color(1, 1, 1), 0.1)

func die():
	print("player died")
	await Transition.fade_out()

	get_tree().paused = true
	var death_screen = preload("res://DeathScreen.tscn").instantiate()
	death_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	Transition.add_child(death_screen)

func _physics_process(delta):
	if is_dashing:
		velocity = last_dir * dash_speed
		move_and_slide()
		return
	
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
		last_dir = dir
		velocity = dir * speed
		if not is_attacking:
			play_walk_animation(dir)
	else:
		velocity = Vector2.ZERO
		if not is_attacking:
			play_idle_animation()
	
	move_and_slide()

func play_walk_animation(dir):
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			$PlayerAnim.play("Walk_right")
			$Shadow.play("Walk_right")
		else:
			$PlayerAnim.play("Walk_left")
			$Shadow.play("Walk_left")
	else:
		if dir.y > 0:
			$PlayerAnim.play("Walk_down")
			$Shadow.play("Walk_down")
		else:
			$PlayerAnim.play("Walk_up")
			$Shadow.play("Walk_up")

func play_idle_animation():
	if abs(last_dir.x) > abs(last_dir.y):
		if last_dir.x > 0:
			$PlayerAnim.play("Idle_right")
			$Shadow.play("Idle_right")
		else:
			$PlayerAnim.play("Idle_left")
			$Shadow.play("Idle_left")
	else:
		if last_dir.y > 0:
			$PlayerAnim.play("Idle_down")
			$Shadow.play("Idle_down")
		else:
			$PlayerAnim.play("Idle_up")
			$Shadow.play("Idle_up")

func _process(_delta):
	if Input.is_action_just_pressed("dash") and can_dash:
		start_dash()
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

func start_dash():
	is_dashing = true
	can_dash = false
	await get_tree().create_timer(dash_time).timeout
	is_dashing = false
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

func attack():
	is_attacking = true
	play_attack_animation(last_dir)
	$AttackArea.monitoring = true
	$AttackArea/CollisionShape2D.set_deferred("disabled", false)
	await get_tree().create_timer(0.4).timeout
	$AttackArea.monitoring = false
	$AttackArea/CollisionShape2D.set_deferred("disabled", true)
	is_attacking = false

func play_attack_animation(dir):
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			$PlayerAnim.play("Attack_right")
			$Shadow.play("Attack_right")
		else:
			$PlayerAnim.play("Attack_left")
			$Shadow.play("Attack_left")
	else:
		if dir.y > 0:
			$PlayerAnim.play("Attack_down")
			$Shadow.play("Attack_down")
		else:
			$PlayerAnim.play("Attack_up")
			$Shadow.play("Attack_up")

func _on_attack_area_area_entered(area: Area2D) -> void:
	if area.name == "HurtBox":
		var enemy = area.get_parent()
		if enemy.has_method("take_hit"):
			enemy.take_hit(global_position)
	elif area.name == "GateHurtBox":
		var gate = area.get_parent()
		if gate.has_method("try_open"):
			gate.try_open(self)
