extends Panel

@export var world_size: Vector2 = Vector2(5950, 5006)
@export var world_offset: Vector2 = Vector2(-4450, -3506)

@onready var boat_marker = $BoatMarker
@onready var bar_fill = $"../HealthBar/BarFill"
@onready var health_label = $"../HealthBar/HealthLabel"
@onready var fuel_bar = $"../FuelBar/HBoxContainer"

var boat: Node2D
var enemy_data: Array = []
var max_health: int = 3
var current_health: int = 3
var bar_max_width: float = 196.0
var enemy_markers: Array = []

var max_fuel: int = 10
var current_fuel: int = 10
var fuel_timer: float = 0.0
var fuel_drain_time: float = 5.0

func _ready():
	boat = get_tree().get_root().find_child("Ship", true, false)
	boat_marker.size = Vector2(8, 8)
	_setup_enemy_markers()
	_update_bar()
	_setup_fuel_bar()
	
func _setup_fuel_bar():
	for i in max_fuel:
		var seg = ColorRect.new()
		seg.custom_minimum_size = Vector2(16, 12)
		seg.color = Color(1, 0.6, 0, 1)  # orange
		fuel_bar.add_child(seg)
	# Add gaps between segments
	fuel_bar.add_theme_constant_override("separation", 2)

func refuel():
	current_fuel = max_fuel
	_update_fuel_bar()

func _update_fuel_bar():
	for i in fuel_bar.get_child_count():
		var seg = fuel_bar.get_child(i)
		seg.color = Color(1, 0.6, 0, 1) if i < current_fuel else Color(0.3, 0.3, 0.3, 0.8)
   
	if current_fuel <= 3:
		_start_flash_warning()
var flashing: bool = false

func _start_flash_warning():
	if flashing:
		return
	flashing = true
	_flash()

func _flash():
	if current_fuel > 3:
		flashing = false
		return
	for i in current_fuel:
		fuel_bar.get_child(i).color = Color(1, 0.1, 0.1, 1)  # red
	await get_tree().create_timer(0.3).timeout
	for i in current_fuel:
		fuel_bar.get_child(i).color = Color(1, 0.6, 0, 1)  # orange
	await get_tree().create_timer(0.3).timeout
	_flash()  # loop
	
func _setup_enemy_markers():
	# Find all nodes in the "enemy" group
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		var marker = ColorRect.new()
		marker.size = Vector2(8, 8)
		marker.color = Color(1, 0.4, 0, 1)
		add_child(marker)
		enemy_markers.append({"node": enemy, "marker": marker})

func take_damage():
	current_health -= 1
	_update_bar()
	if current_health <= 0:
		get_tree().paused = true
		print("GAME OVER - no health")

func _update_bar():
	var pct = float(current_health) / float(max_health)
	bar_fill.size.x = bar_max_width * pct
	if health_label:
		health_label.text = str(current_health) + " / " + str(max_health)
	if pct > 0.6:
		bar_fill.color = Color(0.2, 0.8, 0.2, 1)
	elif pct > 0.3:
		bar_fill.color = Color(0.9, 0.7, 0.1, 1)
	else:
		bar_fill.color = Color(0.9, 0.2, 0.1, 1)

func _process(delta):
	if boat:
		var norm = (boat.global_position - world_offset) / world_size
		norm = norm.clamp(Vector2.ZERO, Vector2.ONE)
		boat_marker.position = norm * size - boat_marker.size / 2
		boat_marker.modulate.a = 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.005)
	queue_redraw()
	fuel_timer += delta
	if fuel_timer >= fuel_drain_time:
		fuel_timer = 0.0
		current_fuel -= 1
		current_fuel = max(current_fuel, 0)
		_update_fuel_bar()
		if current_fuel <= 0:
			get_tree().paused = true
			print("GAME OVER - no fuel")

	for entry in enemy_markers:
		var enemy = entry["node"]
		var marker = entry["marker"]
		if is_instance_valid(enemy):
			var norm = (enemy.global_position - world_offset) / world_size
			norm = norm.clamp(Vector2.ZERO, Vector2.ONE)
			marker.position = norm * size - marker.size / 2
			marker.modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.01)
func _draw():
	var pulse = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.01)
	for enemy in enemy_data:
		if is_instance_valid(enemy) and enemy.is_inside_tree():
			var norm = (enemy.global_position - world_offset) / world_size
			norm = norm.clamp(Vector2.ZERO, Vector2.ONE)
			var pos = norm * size
			draw_circle(pos, 5, Color(1, 0.4, 0, pulse))
			draw_circle(pos, 2.5, Color(1, 0.6, 0.2, 1))
			
			
			
