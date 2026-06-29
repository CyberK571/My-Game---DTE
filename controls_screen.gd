extends Control

var slides = [
	{
		"image": preload("res://assets/controls/movement.png"),
		"text": "WASD to move your ship across the ocean."
	},
	{
		"image": preload("res://assets/controls/attack.png"),
		"text": "Aim with the mouse and left click to fire your cannons."
	},
	{
		"image": preload("res://assets/controls/obstacles.png"),
		"text": "Watch out for rocks and enemy ships!\nEnemy ships will chase you on sight."
	},
	{
		"image": preload("res://assets/controls/fuel.png"),
		"text": "Collect fuel pickups to keep sailing.\nTake too many hits and your ship will sink!"
	},
	{
		"image": preload("res://assets/controls/sprint.png"),
		"text": "Hold Shift to sprint — but it burns fuel faster!"
	},
]

var current_slide = 0

@onready var slide_image = $SlideImage
@onready var slide_label = $TextBox/SlideLabel
@onready var prompt_label = $PromptLabel

func _ready():
	show_slide(0)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		current_slide += 1
		if current_slide >= slides.size():
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		else:
			show_slide(current_slide)

func show_slide(index):
	slide_image.texture = slides[index]["image"]
	slide_label.text = slides[index]["text"]
	if index == slides.size() - 1:
		prompt_label.text = "Press Enter to return to menu"
	else:
		prompt_label.text = "Press Enter to continue"
