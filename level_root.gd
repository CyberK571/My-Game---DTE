extends Node2D

func _ready():
	$Camera2D.zoom = Vector2(0.7, 0.7)
	Transition.play_music(preload("res://Music/He's a Pirate 8-Bit Remix (Pirates of the Caribbean).mp3"), 0.0)
	
