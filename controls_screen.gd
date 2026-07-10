extends Control


var slides = [
	{
		"image": preload("res://Images/controls/movement.png"),
		"text": "WASD to move your ship across the ocean."
	},
	{
		"image": preload("res://Images/controls/attack.png"),
		"text": "Aim with the mouse and left click to fire your cannons."
	},
	{
		"image": preload("res://Images/controls/healthandfuel.png"),
		"text": "Watch out for rocks and enemy ships!\nEnemy ships will chase you on sight."
	},
	{
		"image": preload("res://Images/controls/obstaclesandenemies.png"),
		"text": "Collect fuel pickups to keep sailing.\nTake too many hits and your ship will sink!"
	},
	{
		"image": preload("res://Images/controls/islandcontrols.png"),
		"text": "Hold Shift to sprint — but it burns fuel faster!"
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
		current_slide += 1
		if current_slide >= slides.size():
			var tween = create_tween()
			tween.tween_property($SlideImage, "modulate:a", 0.0, 0.15)
			await tween.finished
			get_tree().change_scene_to_file("res://MainMenu.tscn")
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
	slide_label.text = slides[index]["text"]
	if index == slides.size() - 1:
		prompt_label.text = "Press Enter to return to menu"
	else:
		prompt_label.text = "Press Enter to continue"
