extends CanvasLayer

@onready var color_rect = $ColorRect

func _ready():
	color_rect.color.a = 0.0
	print("Transition ready, layer: ", layer)

func fade_out(duration := 0.5):
	print("fade_out called")
	color_rect.color.a = 0.0
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, duration)
	await tween.finished
	print("fade_out finished, alpha: ", color_rect.color.a)

func fade_in(duration := 0.5):
	print("fade_in called")
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, duration)
	await tween.finished
	print("fade_in finished")

func change_scene(path: String):
	print("change_scene called: ", path)
	await fade_out()
	await get_tree().process_frame
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await fade_in()
