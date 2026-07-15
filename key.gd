extends Area2D

func _ready():
	float_and_glow()

func float_and_glow():
	var original_pos = $Sprite2D.position
	var tween = create_tween()
	tween.set_loops()
	tween.set_parallel(true)
	tween.tween_property($Sprite2D, "position", original_pos + Vector2(0, -4), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($Sprite2D, "modulate", Color(1.6, 1.5, 1.1, 1.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_property($Sprite2D, "position", original_pos, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property($Sprite2D, "modulate", Color(1.4, 1.3, 1.0, 1.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.collect_key()
		queue_free()
