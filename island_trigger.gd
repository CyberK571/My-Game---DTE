extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Ship":
		get_tree().change_scene_to_file("res://level2.tscn")
