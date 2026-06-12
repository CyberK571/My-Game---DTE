extends Control

@onready var player_dot = $TextureRect/ColorRect
@onready var player = get_node("/root/IslandRoot/Player")

# Define your island bounds (adjust to match your TileMapLayer size)
const MAP_MIN = Vector2(-3904, -3591)
const MAP_MAX = Vector2(3237, 3203)

const MINIMAP_SIZE = Vector2(800, 1800)
const DOT_OFFSET = Vector2(-50, -50)  # nudge to fit inside parchment

func _process(delta):
	var pos = player.global_position
	var normalized = (pos - MAP_MIN) / (MAP_MAX - MAP_MIN)
	normalized = normalized.clamp(Vector2(0,0), Vector2(1,1))
	player_dot.position = normalized * MINIMAP_SIZE + DOT_OFFSET
