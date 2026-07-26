extends Control

func _ready():
	print("DeathScreen ready")
	$VBoxContainer/MenuButton.pressed.connect(_on_return_to_menu)

func _on_return_to_menu():
	get_tree().paused = false
	await Transition.change_scene("res://MainMenu.tscn")
	queue_free()
