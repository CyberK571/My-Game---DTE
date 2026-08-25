extends Node2D

func _ready():
	Transition.play_music(preload("res://Music/Title Theme.mp3"))
	$Player/Camera2D.zoom = Vector2(0.8, 0.8)
	await get_tree().create_timer(2.0).timeout
	DialogueManager.show_dialogue([
		"You've landed on the Second Island (Enter to Continue)",
		"The stakes grow higher and the land becomes even rougher as more enemies and challenges await...",
		"The Ramen Warrior Boss has Returned and is even stronger..",
		"Remember, your main quest is to deliver!",
	])
