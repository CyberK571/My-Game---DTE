extends CharacterBody2D

@export var speed = 100
@export var patrol_distance = 100
@export var detect_range = 200
@export var give_up_range = 300
@export var knockback_speed = 300
@export var knockback_time = 0.2
@export var shoot_cooldown = 1.5
@export var projectile_scene: PackedScene


var start_position
var patrol_target
var player = null
var chasing = false
var returning = false
var is_hit = false
var knockback_velocity = Vector2.ZERO
var health = 3
var can_shoot = true
var is_dying = false
var is_attacking = false


func _ready():
	start_position = global_position
	patrol_target = start_position + Vector2(patrol_distance, 0)
	player = get_tree().get_first_node_in_group("player")
	$AnimatedSprite2D.play("Idle")

func take_hit(from_position):
	is_hit = true
	health -= 1

	var dir = (global_position - from_position).normalized()
	knockback_velocity = dir * knockback_speed
	$AnimatedSprite2D.play("Hit")
	$AnimatedSprite2D.modulate = Color(1, 1, 1) * 2
	await get_tree().create_timer(knockback_time).timeout
	knockback_velocity = Vector2.ZERO
	$AnimatedSprite2D.modulate = Color(1, 1, 1)
	is_hit = false

	if health <= 0:
		die()

func die():
	is_dying = true
	is_hit = true
	velocity = Vector2.ZERO
	$AnimatedSprite2D.pause()
	var tween = create_tween()
	tween.tween_property($AnimatedSprite2D, "modulate:a", 0.0, 0.6)
	await tween.finished
	queue_free()

func try_shoot():
	if not can_shoot or is_dying:
		return
	can_shoot = false

	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
	projectile.direction = (player.global_position - global_position).normalized()
	projectile.rotation = projectile.direction.angle()

	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func show_alert():
	$AlertIcon.modulate.a = 1.0
	$AlertIcon.visible = true

	var target_scale = Vector2(0.05, 0.05)
	$AlertIcon.scale = target_scale * 0.3

	var tween = create_tween()
	tween.tween_property($AlertIcon, "scale", target_scale * 1.3, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property($AlertIcon, "scale", target_scale, 0.1)
	tween.tween_interval(1.0)
	tween.tween_property($AlertIcon, "modulate:a", 0.0, 0.3)

func _physics_process(delta):
	if player == null:
		return

	if chasing:
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * speed
		if abs(dir.x) > 0.2:
			$AnimatedSprite2D.flip_h = dir.x < 0
		try_shoot()

	if is_hit:
		velocity = knockback_velocity
		move_and_slide()
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	if distance_to_player < detect_range:
		if not chasing:
			show_alert()
		chasing = true
		returning = false
	elif distance_to_player > give_up_range and chasing:
		chasing = false
		returning = true
		$AnimatedSprite2D.flip_h = start_position.x < global_position.x

	if chasing:
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * speed
		if abs(dir.x) > 0.2:
			$AnimatedSprite2D.flip_h = dir.x < 0

	elif returning:
		var distance = global_position.distance_to(start_position)
		if distance < 4:
			returning = false
			velocity = Vector2.ZERO
			global_position = start_position
			patrol_target = start_position + Vector2(patrol_distance, 0)
		else:
			var dir = (start_position - global_position).normalized()
			velocity = dir * speed

	else:
		var dir = (patrol_target - global_position).normalized()
		velocity = dir * speed
		$AnimatedSprite2D.flip_h = dir.x < 0

		if global_position.distance_to(patrol_target) < 4:
			if patrol_target.x > start_position.x:
				patrol_target = start_position - Vector2(patrol_distance, 0)
			else:
				patrol_target = start_position + Vector2(patrol_distance, 0)

	if not is_hit:
		if velocity.length() > 5:
			$AnimatedSprite2D.play("Walk")
		else:
			$AnimatedSprite2D.play("Idle")
		
	move_and_slide()
	
func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_dying:
		body.take_damage(1)
