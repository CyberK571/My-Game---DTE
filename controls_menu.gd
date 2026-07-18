extends Control

func _ready():
	$PanelContainer/VBoxContainer/OceanButton.pressed.connect(_on_ocean)
	$PanelContainer/VBoxContainer/IslandButton.pressed.connect(_on_island)
	$CloseButton.pressed.connect(_on_close)

func _on_ocean():
	get_tree().change_scene_to_file("res://controls_screen.tscn")

func _on_island():
	get_tree().change_scene_to_file("res://island_controls.tscn")

func _on_close():
	get_tree().change_scene_to_file("res://MainMenu.tscn")
