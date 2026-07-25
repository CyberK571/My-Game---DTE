extends Node

signal dialogue_line_changed(text: String)
signal dialogue_advance_requested
signal dialogue_hidden

var lines: Array = []
var current_index := 0
var is_active := false

func show_dialogue(dialogue_lines: Array):
	lines = dialogue_lines
	current_index = 0
	is_active = true
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
