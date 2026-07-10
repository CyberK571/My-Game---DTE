extends Control

@onready var credits_image = $CreditsImage

func _ready():
	credits_image.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(credits_image, "modulate:a", 1.0, 0.3)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		var tween = create_tween()
		tween.tween_property(credits_image, "modulate:a", 0.0, 0.15)
		await tween.finished
		get_tree().change_scene_to_file("res://MainMenu.tscn")
