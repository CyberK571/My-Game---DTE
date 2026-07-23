extends StaticBody2D

var is_sealed: bool = false

func try_open(player):
	if is_sealed:
		return
	if player.keys_collected >= player.keys_required:
		for gate in get_tree().get_nodes_in_group("gate"):
			gate.open_gate()
	else:
		for gate in get_tree().get_nodes_in_group("gate"):
			gate.shake_locked()
		player.flash_key_label_red()

func open_gate():
	if is_sealed:
		return
	$CollisionShape2D.set_deferred("disabled", true)
	for boss in get_tree().get_nodes_in_group("boss"):
		if boss.has_method("activate"):
			boss.activate()

	var fade_out = create_tween()
	fade_out.tween_property($Sprite2D, "modulate:a", 0.0, 0.6)
	await fade_out.finished
	# Gate stays open from here — it only gets called shut by the boss's
	# seal_shut(), triggered once the player lands their first hit.

func seal_shut():
	# Called by the boss the moment it takes its first hit — permanently
	# locks the entrance for the rest of the fight (and for good, since
	# is_sealed blocks try_open from ever reopening it afterward).
	is_sealed = true
	var fade_in = create_tween()
	fade_in.tween_property($Sprite2D, "modulate:a", 1.0, 0.6)
	await fade_in.finished
	$CollisionShape2D.set_deferred("disabled", false)

func open_on_boss_defeat():
	# Called once the boss dies — releases the lock for good.
	is_sealed = false
	$CollisionShape2D.set_deferred("disabled", true)
	var fade_out = create_tween()
	fade_out.tween_property($Sprite2D, "modulate:a", 0.0, 0.6)
	await fade_out.finished

func shake_locked():
	var original_pos = $Sprite2D.position
	var tween = create_tween()
	tween.tween_property($Sprite2D, "position", original_pos + Vector2(4, 0), 0.05)
	tween.tween_property($Sprite2D, "position", original_pos - Vector2(4, 0), 0.05)
	tween.tween_property($Sprite2D, "position", original_pos + Vector2(4, 0), 0.05)
	tween.tween_property($Sprite2D, "position", original_pos, 0.05)
