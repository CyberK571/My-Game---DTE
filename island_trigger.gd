extends Area2D

func _on_body_entered(body):
	print("Body entered: ", body.name)
	if body.name == "Ship":
		Transition.change_scene("res://island_root.tscn")
