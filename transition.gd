extends CanvasLayer

@onready var color_rect = $ColorRect
@onready var music_player = $MusicPlayer

func _ready():
	color_rect.color.a = 0.0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	print("Transition ready, layer: ", layer)

func fade_out(duration := 0.5):
	print("fade_out called")
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(color_rect, "color:a", 1.0, duration)
	tween.tween_property(music_player, "volume_db", -40.0, duration)
	await tween.finished

func fade_in(duration := 0.5):
	print("fade_in called")
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(color_rect, "color:a", 0.0, duration)
	tween.tween_property(music_player, "volume_db", -10.0, duration)
	await tween.finished

func change_scene(path: String):
	ResourceLoader.load_threaded_request(path)
	await fade_out(0.5)
	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	var packed_scene = ResourceLoader.load_threaded_get(path)
	get_tree().change_scene_to_packed(packed_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await fade_in()

func play_music(stream: AudioStream, start_position := 0.0):
	music_player.stop()
	music_player.stream = stream
	music_player.volume_db = -10.0
	music_player.play(start_position)
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -10.0, 1.0)
