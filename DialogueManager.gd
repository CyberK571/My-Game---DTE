extends Node

signal dialogue_line_changed(text: String)
signal dialogue_advance_requested
signal dialogue_hidden

var lines: Array = []
var current_index := 0
var is_active := false
var on_finished: Callable = Callable()
var second_ocean_intro_shown := false
var third_ocean_intro_shown := false

func show_dialogue(dialogue_lines: Array, on_finish: Callable = Callable()):
	lines = dialogue_lines
	current_index = 0
	is_active = true
	on_finished = on_finish
	emit_signal("dialogue_line_changed", lines[current_index])

func _input(event):
	if is_active and event.is_action_pressed("ui_accept"):
		advance()

func advance():
	current_index += 1
	if current_index >= lines.size():
		hide_dialogue()
	else:
		emit_signal("dialogue_advance_requested", lines[current_index])

func hide_dialogue():
	is_active = false
	emit_signal("dialogue_hidden")
	if on_finished.is_valid():
		on_finished.call()
		on_finished = Callable()
