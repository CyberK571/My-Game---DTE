extends Node2D

func _ready():
	for enemy in get_tree().get_nodes_in_group("enemy"):
		print(enemy.name, ": ", enemy.global_position)
	$Camera2D.zoom = Vector2(0.7, 0.7)
	if DialogueManager.second_ocean_intro_shown:
		return
	DialogueManager.second_ocean_intro_shown = true
	await get_tree().create_timer(1.0).timeout
	DialogueManager.show_dialogue([
		"Welcome to Ocean 3, the Final Ocean",
		"Good Luck Captain, It has all come down to this...",
	])
