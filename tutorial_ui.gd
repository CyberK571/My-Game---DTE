extends CanvasLayer
@onready var dialogue_box = $DialogueBox

func _ready():
	TutorialManager.step_changed.connect(_on_step_changed)
	TutorialManager.tutorial_finished.connect(_on_tutorial_finished)
	dialogue_box.modulate.a = 0.0
	dialogue_box.visible = false

	if TutorialManager.tutorial_complete:
		return

	await get_tree().create_timer(2.0).timeout
	if not TutorialManager.tutorial_active:
		return
	$DialogueBox/Label.text = TutorialManager.steps[TutorialManager.current_step]["text"]
	dialogue_box.visible = true
	var tween = create_tween()
	tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.5)

func _on_step_changed(text: String):
	$DialogueBox/Label.text = text
	dialogue_box.visible = true
	var tween = create_tween()
	tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.5)

func _on_tutorial_finished():
	visible = false
	TutorialManager.step_changed.disconnect(_on_step_changed)
	TutorialManager.tutorial_finished.disconnect(_on_tutorial_finished)
