extends CanvasLayer

func _ready():
	visible = false
	$DialogueBox.modulate.a = 0.0
	DialogueManager.dialogue_line_changed.connect(_on_dialogue_line_changed)
	DialogueManager.dialogue_advance_requested.connect(_on_advance_requested)
	DialogueManager.dialogue_hidden.connect(_on_dialogue_hidden)
	print("DialogueUI ready, connections made")

func _on_dialogue_line_changed(text):
	print("dialogue_line_changed received: ", text)
	$DialogueBox/Label.text = text
	visible = true
	$DialogueBox.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property($DialogueBox, "modulate:a", 1.0, 0.3)

func _on_advance_requested(next_text):
	var tween = create_tween()
	tween.tween_property($DialogueBox, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func(): $DialogueBox/Label.text = next_text)
	tween.tween_property($DialogueBox, "modulate:a", 1.0, 0.3)

func _on_dialogue_hidden():
	var tween = create_tween()
	tween.tween_property($DialogueBox, "modulate:a", 0.0, 0.2)
	tween.finished.connect(_hide_dialogue_box)

func _hide_dialogue_box():
	visible = false
