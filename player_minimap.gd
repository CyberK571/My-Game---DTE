extends Control

@onready var player_dot = $TextureRect/ColorRect
@onready var player = get_node("/root/IslandRoot/Player")

# Define your island bounds (adjust to match your TileMapLayer size)
const MAP_MIN = Vector2(-3000, -4500)
const MAP_MAX = Vector2(3500, 5700)

const MINIMAP_SIZE = Vector2(720, 2000)
const DOT_OFFSET = Vector2.ZERO

var enemy_markers = []  # list of {"node": enemy, "marker": ColorRect}

func _ready():
	_setup_enemy_markers()
	_flash_minimap_icons()

func _process(delta):
	var pos = player.global_position
	var normalized = (pos - MAP_MIN) / (MAP_MAX - MAP_MIN)
	normalized = normalized.clamp(Vector2(0,0), Vector2(1,1))
	player_dot.position = normalized * MINIMAP_SIZE + DOT_OFFSET

	_update_enemy_markers()

func _setup_enemy_markers():
	var enemies = get_tree().get_nodes_in_group("enemy")
	var parent_scale = $TextureRect.scale
	for enemy in enemies:
		var marker = ColorRect.new()
		marker.size = Vector2(40, 40)
		marker.scale = Vector2(1.0 / parent_scale.x, 1.0 / parent_scale.y) * 0.08  # tweak multiplier to size it visually
		marker.color = Color(1, 0.4, 0, 1)
		$TextureRect.add_child(marker)
		enemy_markers.append({"node": enemy, "marker": marker})
		_flash(marker)

func _flash(marker):
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(marker, "modulate:a", 0.2, 0.5)
	tween.tween_property(marker, "modulate:a", 1.0, 0.5)

func _update_enemy_markers():
	var i = 0
	while i < enemy_markers.size():
		var entry = enemy_markers[i]
		var enemy = entry["node"]
		var marker = entry["marker"]

		if not is_instance_valid(enemy) or not is_instance_valid(marker):
			if is_instance_valid(marker):
				marker.queue_free()
			enemy_markers.remove_at(i)
			continue

		var enemy_pos = enemy.global_position
		var enemy_normalized = (enemy_pos - MAP_MIN) / (MAP_MAX - MAP_MIN)
		enemy_normalized = enemy_normalized.clamp(Vector2(0,0), Vector2(1,1))
		marker.position = enemy_normalized * MINIMAP_SIZE + DOT_OFFSET
		i += 1

func _flash_minimap_icons():
	var icons = get_tree().get_nodes_in_group("minimap_icons")
	for icon in icons:
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(icon, "modulate:a", 0.3, 0.6)
		tween.tween_property(icon, "modulate:a", 1.0, 0.6)
