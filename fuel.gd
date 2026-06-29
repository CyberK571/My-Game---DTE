extends Area2D

var base_y: float
var time: float = 0.0

func _ready():
	body_entered.connect(_on_body_entered)
	base_y = position.y

func _process(delta):
	time += delta
	
	# Bob up and down
	position.y = base_y + sin(time * 2.0) * 12.0
	
	# Flash white transparency
	var flash = 0.85 + 0.15 * sin(time * 4.0)
	$Sprite2D.modulate = Color(1, 1, 1, flash)

func _on_body_entered(body):
	if body.name == "Ship":
		var hud = get_tree().get_root().find_child("Panel", true, false)
		if hud and hud.has_method("refuel"):
			TutorialManager.report_action("collected_fuel") 
			hud.refuel()
		queue_free()
