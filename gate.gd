extends StaticBody2D

func try_open(player):
	if player.keys_collected >= player.keys_required:
		for gate in get_tree().get_nodes_in_group("gate"):
			gate.open_gate()
	else:
		for gate in get_tree().get_nodes_in_group("gate"):
			gate.shake_locked()
		player.flash_key_label_red()

func open_gate():
	$CollisionShape2D.set_deferred("disabled", true)
	for boss in get_tree().get_nodes_in_group("boss"):
		if boss.has_method("activate"):
			boss.activate()
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.6)
	await tween.finished
	queue_free()

func shake_locked():
	var original_pos = $Sprite2D.position
	var tween = create_tween()
	tween.tween_property($Sprite2D, "position", original_pos + Vector2(4, 0), 0.05)
	tween.tween_property($Sprite2D, "position", original_pos - Vector2(4, 0), 0.05)
	tween.tween_property($Sprite2D, "position", original_pos + Vector2(4, 0), 0.05)
	tween.tween_property($Sprite2D, "position", original_pos, 0.05)
