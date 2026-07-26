extends Control

func _ready():
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.6)
	$VBoxContainer/PlayButton.pressed.connect(_on_play)
	$VBoxContainer/ControlsButton.pressed.connect(_on_controls)
	$VBoxContainer/CreditsButton.pressed.connect(_on_credits)
		
	$VBoxContainer2/"Island Scene".pressed.connect(_on_1st_Island_Scene)
	$VBoxContainer2/"Second Ocean Scene".pressed.connect(_on_Second_Ocean_Scene)
	$VBoxContainer2/"Second Island Scene".pressed.connect(_on_Second_Island_Scene)

func _on_play():
	get_tree().change_scene_to_file("res://level_root.tscn")

func _on_controls():
	get_tree().change_scene_to_file("res://controls_menu.tscn")

func _on_credits():
	get_tree().change_scene_to_file("res://credits_screen.tscn")

func _on_1st_Island_Scene():
	Transition.change_scene("res://island_root.tscn")

func _on_Second_Ocean_Scene():
	Transition.change_scene("res://level_root2.tscn")

func _on_Second_Island_Scene():
	pass
