extends Control

@onready var hover_sound = $HoverSound
@onready var click_sound = $ClickSound

const LEVEL_SCENES = {
	"Island Scene": "res://island_root.tscn",
	"Second Ocean Scene": "res://level_root2.tscn",
	"Second Island Scene": "res://island_root2.tscn",
	"Third Ocean Scene": "res://level_root3.tscn",
	"Third Island Scene": "res://island_root3.tscn",  # fill in when ready
}

func _ready():
	Transition.play_music(preload("res://Music/Alestorm Pirate Song - 8 Bit.mp3"))
	print("Unlocked levels: ", LevelUnlock.unlocked)
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.6)
	for btn in $VBoxContainer.get_children():
		btn.mouse_entered.connect(_on_button_hover)
		btn.pressed.connect(_on_button_click)
	for btn in $VBoxContainer2.get_children():
		btn.mouse_entered.connect(_on_button_hover)
		if LevelUnlock.is_unlocked(btn.name):
			btn.visible = true
			btn.pressed.connect(func(): Transition.change_scene(LEVEL_SCENES[btn.name]))
		else:
			btn.visible = false

	$VBoxContainer/PlayButton.pressed.connect(_on_play)
	$VBoxContainer/ControlsButton.pressed.connect(_on_controls)
	$VBoxContainer/CreditsButton.pressed.connect(_on_credits)
	
func _on_button_hover():
	hover_sound.play()

func _on_button_click():
	click_sound.play()

	for btn in $VBoxContainer2.get_children():
		if LevelUnlock.is_unlocked(btn.name):
			btn.visible = true
			btn.pressed.connect(func(): Transition.change_scene(LEVEL_SCENES[btn.name]))
		else:
			btn.visible = false

func _on_play():
	get_tree().change_scene_to_file("res://level_root.tscn")

func _on_controls():
	get_tree().change_scene_to_file("res://controls_menu.tscn")

func _on_credits():
	get_tree().change_scene_to_file("res://credits_screen.tscn")

func _on_1st_Island_Scene():
	Transition.change_scene("res://island_root.tscn")

func _on_Second_Ocean_Scene():
	Transition.change_scene("res://level_root2.tscn")

func _on_Second_Island_Scene():
	Transition.change_scene("res://island_root2.tscn")
	
func _on_Third_Ocean_Scene():
	Transition.change_scene("res://level_root3.tscn")

func _on_Third_Island_Scene():
	Transition.change_scene("res://island_root3.tscn")
