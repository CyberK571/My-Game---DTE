extends Panel

@export var world_size: Vector2 = Vector2(5950, 5006)
@export var world_offset: Vector2 = Vector2(-4450, -3506)

@onready var boat_marker = $BoatMarker
var boat: Node2D

func _ready():
	boat = get_tree().get_root().find_child("Ship", true, false)
	boat_marker.size = Vector2(8, 8)

func _process(_delta):
	if boat == null:
		return

	var norm = (boat.global_position - world_offset) / world_size
	norm = norm.clamp(Vector2.ZERO, Vector2.ONE)
	boat_marker.position = norm * size - boat_marker.size / 2

	var pulse = 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.005)
	boat_marker.modulate.a = pulse
