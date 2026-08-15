extends CharacterBody2D

@export var projectile_scene: PackedScene
@export var shoot_interval: float = 0.8

var player_in_range: Node2D = null

enum State { BURIED, EMERGING, JUMPING, ATTACKING, BURROWING }
var state: State = State.BURIED

@export var shoot_range: float = 80.0
@export var jump_duration: float = 0.4
@export var jump_cooldown: float = 0.6
var cached_territory_poly: PackedVector2Array
var is_jumping := false
@onready var sprite = $AnimatedSprite2D
@onready var dirt = $Dirt
@onready var shoot_timer = $ShootTimer
@onready var muzzle = $MuzzlePoint
@onready var detection_area = $DetectionArea
@export var jump_distance: float = 150.0
@onready var territory = $Territory
@export var projectile_color: Color = Color(0.5, 1.0, 0.1)
@export var projectile_speed: float = 300.0

func _ready():
	sprite.visible = false
	dirt.play("Normal")
	sprite.play("Idle")
	shoot_timer.wait_time = shoot_interval
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

	# Cache territory's global shape BEFORE any jumping moves the parent
	cached_territory_poly = PackedVector2Array()
	for p in territory.polygon:
		cached_territory_poly.append(territory.to_global(p))

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = body
		_emerge()

func _on_body_exited(body):
	if body == player_in_range:
		player_in_range = null
		_bury()

func _emerge():
	state = State.EMERGING
	sprite.visible = true
	sprite.play("Idle")
	dirt.play("Normal")
	await get_tree().create_timer(0.3).timeout
	state = State.JUMPING
	_decide_next_move()

func _decide_next_move():
	if state == State.BURIED or not player_in_range:
		return

	var dist_to_player = global_position.distance_to(player_in_range.global_position)
	print("dist to player: ", dist_to_player, " | shoot_range: ", shoot_range)

	if dist_to_player <= shoot_range:
		state = State.ATTACKING
		sprite.play("Idle")
		shoot_timer.start()
		_shoot() # fire immediately instead of waiting a full interval first
	else:
		if state != State.JUMPING:
			shoot_timer.stop()
			state = State.JUMPING
		_do_jump()
		
func _do_jump():
	if is_jumping:
		return
	is_jumping = true
	state = State.JUMPING

	var target = _pick_jump_target()
	var start_pos = global_position
	var mid_pos = start_pos.lerp(target, 0.5) - Vector2(0, 40)

	dirt.play("Burst")
	sprite.play("Jump")

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_arc_position.bind(start_pos, mid_pos, target), 0.0, 1.0, jump_duration)
	await tween.finished

	dirt.play("Mound")
	await dirt.animation_finished
	dirt.play("Normal")

	is_jumping = false
	await get_tree().create_timer(jump_cooldown).timeout
	if state == State.JUMPING and player_in_range:
		_decide_next_move()

func _flash_dirt_burst():
	dirt.visible = true
	dirt.play("Burst")
	if not dirt.animation_finished.is_connected(_on_burst_finished):
		dirt.animation_finished.connect(_on_burst_finished, CONNECT_ONE_SHOT)

func _on_burst_finished():
	dirt.visible = false

func _on_jump_finished():
	is_jumping = false
	# Don't force Idle here — only switch if the worm is about to attack or has nothing else queued
	await get_tree().create_timer(jump_cooldown).timeout
	if state == State.JUMPING and player_in_range:
		_decide_next_move() 
		
func _set_arc_position(t: float, start_pos: Vector2, mid_pos: Vector2, end_pos: Vector2):
	var a = start_pos.lerp(mid_pos, t)
	var b = mid_pos.lerp(end_pos, t)
	global_position = a.lerp(b, t)

func _squash_land():
	sprite.scale = Vector2(1.3, 0.7)
	var squash_tween = create_tween()
	squash_tween.set_trans(Tween.TRANS_ELASTIC)
	squash_tween.set_ease(Tween.EASE_OUT)
	squash_tween.tween_property(sprite, "scale", Vector2(1, 1), 0.25)

func _bury():
	state = State.BURIED
	shoot_timer.stop()
	sprite.visible = false
	dirt.play("Mound")
	await dirt.animation_finished
	dirt.play("Normal")

func _on_shoot_timer_timeout():
	print("timer fired, state: ", state, " player_in_range: ", player_in_range)
	if not player_in_range:
		return
	var dist_to_player = global_position.distance_to(player_in_range.global_position)
	if dist_to_player > shoot_range:
		state = State.JUMPING
		_decide_next_move()
		return
	_shoot()

func _shoot():
	if not projectile_scene:
		return
	sprite.play("Attack")
	var proj = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = muzzle.global_position
	proj.modulate = projectile_color
	proj.shooter = self
	proj.speed = projectile_speed
	var direction = (player_in_range.global_position - muzzle.global_position).normalized()
	proj.direction = direction
	proj.rotation = direction.angle()
	await get_tree().create_timer(0.15).timeout
	sprite.play("Idle")
	
func _pick_jump_target() -> Vector2:
	if not player_in_range:
		return global_position
	var desired = global_position + (player_in_range.global_position - global_position).limit_length(jump_distance)
	return _get_clamped_jump_target(desired)
	
func _get_clamped_jump_target(desired_pos: Vector2) -> Vector2:
	var global_poly = cached_territory_poly

	if Geometry2D.is_point_in_polygon(desired_pos, global_poly):
		return desired_pos

	var closest_point = global_poly[0]
	var closest_dist = INF
	for i in range(global_poly.size()):
		var a = global_poly[i]
		var b = global_poly[(i + 1) % global_poly.size()]
		var pt = Geometry2D.get_closest_point_to_segment(desired_pos, a, b)
		var dist = pt.distance_to(desired_pos)
		if dist < closest_dist:
			closest_dist = dist
			closest_point = pt

	var center = Vector2.ZERO
	for p in global_poly:
		center += p
	center /= global_poly.size()
	return closest_point.lerp(center, 0.05)
