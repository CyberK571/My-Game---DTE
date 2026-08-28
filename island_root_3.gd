extends Node2D

func _ready():
	LevelUnlock.unlock("Third Island Scene")
	Transition.play_music(preload("res://Music/Title Theme.mp3"))
	$Player/Camera2D.zoom = Vector2(0.8, 0.8)
	await get_tree().create_timer(2.0).timeout
	DialogueManager.show_dialogue([
		"You've landed on the Final Island...",
		"The Ramen Warrior Boss has Returned Once More and is even stronger..",
		"Successfully Deliver to the final Customer and your Quest shall be finished!",
	])
