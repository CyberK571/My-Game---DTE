extends Control


var slides = [
	{
		"image": preload("res://Images/Controls/1.png"),
	},
	{
		"image": preload("res://Images/Controls/2.png"),
	},
	{
		"image": preload("res://Images/Controls/3.png"),
	},
	{
		"image": preload("res://Images/Controls/4.png"),
	},
	{
		"image": preload("res://Images/Controls/5.png"),
	},
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
		get_viewport().set_input_as_handled()
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
