extends Area2D

var speed := 300.0
var direction := Vector2.RIGHT

func set_direction(dir: Vector2):
	direction = dir
	rotation = dir.angle()

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		# body.take_damage(1) — hook into your health system
		queue_free()

func _on_screen_exited():
	queue_free()
