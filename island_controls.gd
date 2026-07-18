extends Control

var slides = [
	{ "image": preload("res://Images/Controls/island controls/IslandMovement.png"),},
	{ "image": preload("res://Images/Controls/island controls/IslandAttack.png"),},
	{ "image": preload("res://Images/Controls/island controls/IslandHealthandKey.png"),},
	{ "image": preload("res://Images/Controls/island controls/IslandEnemy.png"),},
	{ "image": preload("res://Images/Controls/island controls/IslandMinimap.png"),},
]

var current_slide = 0

@onready var slide_image = $SlideImage
@onready var slide_label = $TextBox/SlideLabel
@onready var prompt_label = $PromptLabel

func _ready():
	$SlideImage.modulate.a = 0.0
	show_slide(0)
	var tween = create_tween()
	tween.tween_property($SlideImage, "modulate:a", 1.0, 0.15)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		current_slide += 1
		if current_slide >= slides.size():
			var tween = create_tween()
			tween.tween_property($SlideImage, "modulate:a", 0.0, 0.15)
			await tween.finished
			get_tree().change_scene_to_file("res://controls_menu.tscn")
		else:
			await fade_slide(current_slide)

func fade_slide(index):
	var tween = create_tween()
	tween.tween_property($SlideImage, "modulate:a", 0.0, 0.15)
	await tween.finished
	show_slide(index)
	tween = create_tween()
	tween.tween_property($SlideImage, "modulate:a", 1.0, 0.15)
	await tween.finished

func show_slide(index):
	slide_image.texture = slides[index]["image"]
	if index == slides.size() - 1:
		prompt_label.text = "Press Enter to return to menu"
	else:
		prompt_label.text = "Press Enter to continue"
