extends Control

func _ready():
	$VBoxContainer/PlayButton.pressed.connect(_on_play)
	$VBoxContainer/ControlsButton.pressed.connect(_on_controls)
	$VBoxContainer/CreditsButton.pressed.connect(_on_credits)

func _on_play():
	get_tree().change_scene_to_file("res://level_root.tscn")

func _on_controls():
	get_tree().change_scene_to_file("res://controls_menu.tscn")

func _on_credits():
	get_tree().change_scene_to_file("res://credits_screen.tscn")
