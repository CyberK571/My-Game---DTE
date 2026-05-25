extends CharacterBody2D

const SPEED = 150.0
const TILE_W = 249.0
const TILE_H = 126.0
const Cannonball = preload("res://cannon_ball.tscn")

@onready var cooldown_ui = $CannonSpawn/CoolDownUI/ColorRect
@onready var cooldown_label = $CannonSpawn/CoolDownUI/ColorRect/Label
@onready var camera = get_node("/root/LevelRoot/Camera2D")

var iso_right = Vector2(TILE_W / 2, TILE_H / 2).normalized()
var iso_left  = Vector2(-TILE_W / 2, -TILE_H / 2).normalized()
var iso_down = Vector2(-TILE_W / 2, TILE_H / 2).normalized()
var iso_up = Vector2(TILE_W / 2, -TILE_H / 2).normalized()
var can_shoot = true
var cooldown_remaining = 0.0
var target_tilt = 0.0
var facing = Vector2.RIGHT
var diagonal = (global_position.x - global_position.y) * 0.5

func _physics_process(delta):
	var dir = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		dir += iso_right
  
	if Input.is_action_pressed("ui_left"):
		dir += iso_left
	   
	if Input.is_action_pressed("ui_down"):
		dir += iso_down
		rotation = lerp(rotation, -0.10, 0.1)
		target_tilt = deg_to_rad(-10.0)
		
	if Input.is_action_pressed("ui_up"):
		dir += iso_up
		rotation = lerp(rotation, 0.10, 0.1)
		target_tilt = deg_to_rad(10.0)
		
	if dir != Vector2.ZERO:
		velocity = dir.normalized() * SPEED
	else:
		velocity = Vector2(1, -0.7).normalized() * 15
		rotation = lerp(rotation, 0.0, 0.1)

	if cooldown_remaining > 0:
		cooldown_remaining -= delta
		cooldown_ui.visible = true
		cooldown_label.text = str(ceil(cooldown_remaining))
	else:
		cooldown_ui.visible = false

	move_and_slide()
	var forward = Vector2(1, 0.5).normalized()
	var ship_projected = forward * forward.dot(global_position)
	
	camera.global_position = forward * forward.dot(global_position)
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if can_shoot:
				shoot()

func shoot():
	can_shoot = false
	cooldown_remaining = 3.0
	var ball = Cannonball.instantiate()
	get_parent().add_child(ball)
	ball.global_position = $CannonSpawn.global_position
	var mouse_pos = get_global_mouse_position()
	ball.direction = (mouse_pos - $CannonSpawn.global_position).normalized()
	await get_tree().create_timer(3.0).timeout
	can_shoot = true
