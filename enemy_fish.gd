extends CharacterBody2D

@export var swim_speed: float = 100.0
@export var kill_radius: float = 80.0
@export var max_health: int = 1
var health: int
var pulse_alpha: float = 0.0
var pulse_timer: Timer
var player: Node2D = null
var is_chomping: bool = false

func _ready():
	health = max_health
	player = get_tree().get_first_node_in_group("player")
	$DetectionArea.body_entered.connect(_on_hit_box_body_entered)
	
	pulse_timer = Timer.new()
	pulse_timer.wait_time = 3.0
	pulse_timer.timeout.connect(_do_pulse)
	add_child(pulse_timer)
	pulse_timer.start()
	
func take_hit():
	if is_chomping:
		return
	is_chomping = true
	velocity = Vector2.ZERO
	pulse_alpha = 0.0
	pulse_timer.stop()
	queue_redraw()
	$AnimatedSprite2D.play("Hurt")
	$Shadow.play("Hurt")
	await $AnimatedSprite2D.animation_finished
	die()

func die():
	velocity = Vector2.ZERO
	$AnimatedSprite2D.play("Die")
	$Shadow.play("Die")
	await $AnimatedSprite2D.animation_finished
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property($AnimatedSprite2D, "modulate:a", 0.0, 0.6)
	tween.tween_property($Shadow, "modulate:a", 0.0, 0.6)
	await tween.finished
	queue_free()

func _do_pulse():
	if is_chomping:
		return
	var tween = create_tween()
	tween.tween_property(self, "pulse_alpha", 0.6, 0.4)
	tween.tween_property(self, "pulse_alpha", 0.0, 0.4)

func _process(delta):
	queue_redraw()
	if player and not is_chomping:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * swim_speed
		rotation = direction.angle()
		$AnimatedSprite2D.play("Swim")
		$Shadow.play("Swim")
	move_and_slide()


func _on_hit_box_body_entered(body):
	if body == player and not is_chomping:
		explode()
		var hud = get_tree().get_root().find_child("Panel", true, false)
		if hud and hud.has_method("take_damage"):
			hud.take_damage()

func explode():
	if is_chomping:
		return
	is_chomping = true
	velocity = Vector2.ZERO
	pulse_alpha = 0.0
	pulse_timer.stop()
	queue_redraw()
	$AnimatedSprite2D.scale = Vector2(5.0, 5.0)
	$Shadow.scale = Vector2(5.0, 5.0)
	$AnimatedSprite2D.play("Explosion")
	$Shadow.play("Explosion")
	await $AnimatedSprite2D.animation_finished
	queue_free()
	

func _draw():
	if pulse_alpha > 0:
		draw_arc(Vector2.ZERO, kill_radius, 0, TAU, 64, Color(1, 0, 0, pulse_alpha), 3.0)
