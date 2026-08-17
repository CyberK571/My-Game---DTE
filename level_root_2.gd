extends Node2D

func _ready():
	$Camera2D.zoom = Vector2(0.7, 0.7)
	if DialogueManager.second_ocean_intro_shown:
		return
	DialogueManager.second_ocean_intro_shown = true
	await get_tree().create_timer(1.0).timeout
	DialogueManager.show_dialogue([
		"Welcome to Ocean 2 (Enter to Continue)",
		"The waters grow rougher here.",
		"Stay alert, captain, this sea hides new dangers which prevent your journey to the second island.",
		"Dangerous fishes are attracted to the food you carry alongboard, you must shoot them down before they reach you",
	])
