extends Panel

@export var world_size: Vector2 = Vector2(5950, 5006)
@export var world_offset: Vector2 = Vector2(-4450, -3506)

@onready var boat_marker = $BoatMarker
var boat: Node2D
var enemy_markers: Array = []

func _ready():
	boat = get_tree().get_root().find_child("Ship", true, false)
	boat_marker.size = Vector2(8, 8)
	_setup_enemy_markers()

func _setup_enemy_markers():
	# Find all nodes in the "enemy" group
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		var marker = ColorRect.new()
		marker.size = Vector2(8, 8)
		marker.color = Color(1, 0.4, 0, 1)
		add_child(marker)
		enemy_markers.append({"node": enemy, "marker": marker})

func _process(_delta):
	if boat:
		var norm = (boat.global_position - world_offset) / world_size
		norm = norm.clamp(Vector2.ZERO, Vector2.ONE)
		boat_marker.position = norm * size - boat_marker.size / 2
		boat_marker.modulate.a = 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.005)

	for entry in enemy_markers:
		var enemy = entry["node"]
		var marker = entry["marker"]
		if is_instance_valid(enemy):
			var norm = (enemy.global_position - world_offset) / world_size
			norm = norm.clamp(Vector2.ZERO, Vector2.ONE)
			marker.position = norm * size - marker.size / 2
			marker.modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.01)
