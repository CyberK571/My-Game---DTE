extends CanvasLayer

@onready var color_rect = $ColorRect

func _ready():
	color_rect.color.a = 0.0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	print("Transition ready, layer: ", layer)

func fade_out(duration := 0.5):
	print("fade_out called")
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, duration)
	await tween.finished
	print("fade_out finished, alpha: ", color_rect.color.a)

func fade_in(duration := 0.5):
	print("fade_in called")
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, duration)
	await tween.finished
	print("fade_in finished, alpha: ", color_rect.color.a)

func change_scene(path: String):
	# start loading in the background right away
	ResourceLoader.load_threaded_request(path)

	# fade out while it loads
	await fade_out()

	# wait until the load actually finishes (usually already done by now)
	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame

	var packed_scene = ResourceLoader.load_threaded_get(path)
	get_tree().change_scene_to_packed(packed_scene)

	await get_tree().process_frame
	await get_tree().process_frame
	await fade_in()
