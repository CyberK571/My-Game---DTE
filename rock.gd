extends StaticBody2D

var hits: int = 0
var is_dying: bool = false
var original_position: Vector2

func _ready():
	original_position = position
	add_to_group("rock")

func take_hit():
	if is_dying:
		return
	hits += 1
	if hits >= 2:
		_die()
	else:
		_vibrate()

func _vibrate():
	var tween = create_tween()
	tween.tween_property(self, "position", original_position + Vector2(6, 0), 0.05)
	tween.tween_property(self, "position", original_position + Vector2(-6, 0), 0.05)
	tween.tween_property(self, "position", original_position + Vector2(4, 0), 0.05)
	tween.tween_property(self, "position", original_position + Vector2(-4, 0), 0.05)
	tween.tween_property(self, "position", original_position, 0.05)

func _die():
	is_dying = true
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 0), 0.6)
	tween.tween_callback(queue_free)

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		body.take_hit()
	elif body.is_in_group("rock"):
		body.take_hit()
	queue_free()
