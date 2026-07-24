extends Area2D

@onready var prompt_label: Label = $Label
var player_in_range := false
var float_tween: Tween
var base_position: Vector2

func _ready():
	prompt_label.visible = false
	prompt_label.modulate.a = 0.0
	base_position = prompt_label.position
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		prompt_label.visible = true
		prompt_label.modulate.a = 0.0
		var fade_tween = create_tween()
		fade_tween.tween_property(prompt_label, "modulate:a", 1.0, 0.25)
		start_floating()

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		if float_tween:
			float_tween.kill()
		prompt_label.position = base_position
		var fade_tween = create_tween()
		fade_tween.tween_property(prompt_label, "modulate:a", 0.0, 0.15)
		fade_tween.tween_callback(func(): prompt_label.visible = false)

func start_floating():
	if float_tween:
		float_tween.kill()
	float_tween = create_tween().set_loops()
	float_tween.tween_property(prompt_label, "position:y", base_position.y - 2, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(prompt_label, "position:y", base_position.y, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _unhandled_input(event):
	if player_in_range and event.is_action_pressed("interact"):
		start_dialogue()

func start_dialogue():
	prompt_label.visible = false
	if float_tween:
		float_tween.kill()
	TutorialManager.show_dialogue("Old man's line here...")

func end_dialogue():
	if player_in_range:
		prompt_label.visible = true
		prompt_label.modulate.a = 1.0
		start_floating()
