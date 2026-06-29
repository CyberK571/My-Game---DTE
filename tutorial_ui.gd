extends CanvasLayer

@onready var dialogue_box = $DialogueBox

func _ready():
	TutorialManager.step_changed.connect(_on_step_changed)
	TutorialManager.tutorial_finished.connect(_on_tutorial_finished)
	dialogue_box.modulate.a = 0.0
	dialogue_box.visible = false
	await get_tree().create_timer(2.0).timeout
	$DialogueBox/Label.text = TutorialManager.steps[0]["text"]
	dialogue_box.visible = true
	var tween = create_tween()
	tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.5)

func _on_step_changed(text: String):
	$DialogueBox/Label.text = text
	dialogue_box.visible = true
	var tween = create_tween()
	tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.5)

func _on_tutorial_finished():
	var tween = create_tween()
	tween.tween_property(dialogue_box, "modulate:a", 0.0, 0.5)
	await tween.finished
	dialogue_box.visible = false
