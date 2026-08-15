extends Node

const SAVE_PATH = "user://unlocks.cfg"
var unlocked: Array = []

func _ready():
	load_unlocks()

func unlock(level_id: String):
	if level_id not in unlocked:
		unlocked.append(level_id)
		save_unlocks()

func is_unlocked(level_id: String) -> bool:
	return level_id in unlocked

func save_unlocks():
	var cfg = ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.save(SAVE_PATH)

func load_unlocks():
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		unlocked = cfg.get_value("progress", "unlocked", [])
