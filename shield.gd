extends Area2D

var pulse_tween: Tween

func _ready():
	area_entered.connect(_on_area_entered)

func _on_area_entered(area):
	if area.is_in_group("enemy_projectile") and get_parent().shield_active:
		area.fade_and_remove()

func play_flash():
	modulate = Color(1, 1, 1, 0)
	scale = Vector2(0.8, 0.8)
	
	if pulse_tween:
		pulse_tween.kill()
	
	pulse_tween = create_tween()
	pulse_tween.tween_property(self, "modulate", Color(2, 2, 2, 1), 0.1)
	pulse_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	pulse_tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 1), 0.15)
	pulse_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	pulse_tween.set_loops(4)

func stop_flash():
	if pulse_tween:
		pulse_tween.kill()

func fade_out():
	if pulse_tween:
		pulse_tween.kill()
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
