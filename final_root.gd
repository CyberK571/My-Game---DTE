extends Control

func _ready():
	$VBoxContainer/ReturnButton.pressed.connect(_on_return_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _on_return_pressed():
	Transition.change_scene("res://main_menu.tscn") # swap in your actual main menu scene path
	
func _on_quit_pressed():
	get_tree().quit()
