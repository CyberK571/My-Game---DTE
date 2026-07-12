extends Area2D

var direction = Vector2.RIGHT
@export var speed = 200
@export var lifetime = 3.0

func _ready():
	$AnimatedSprite2D.play("Bullet")
	await get_tree().create_timer(lifetime).timeout
	fade_and_remove()

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(1)
		fade_and_remove()

func fade_and_remove():
	set_physics_process(false)
	var tween = create_tween()
	tween.tween_property($AnimatedSprite2D, "modulate:a", 0.0, 1.0)
	await tween.finished
	queue_free()
