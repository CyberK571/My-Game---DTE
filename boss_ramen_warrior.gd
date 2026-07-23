extends CharacterBody2D

# ── Boss: Ramen Warrior (Island 1) ────────────────────────────────
# Punch-only boss for this island. Needle/lasso attacks are saved for
# a later island's version of this boss.
#
# Phase 1 (100%–50% HP): normal punches, normal speed
# Phase 2 (50%–33% HP): RAGE — red tint, faster movement, shorter attack cooldowns
# Phase 3 (below 33% HP): RAGE 2 — even faster, minimal cooldowns

signal phase_changed(new_phase: int)
signal boss_died

@export var max_health: int = 30
@export var move_speed: float = 90.0
@export var phase_2_threshold: float = 0.5
@export var phase_3_threshold: float = 0.33

# Rage tuning — multipliers applied to move_speed and to attack
# cooldowns when each phase kicks in (cooldown multiplier < 1 = faster).
@export var phase_2_speed_multiplier: float = 1.3
@export var phase_2_cooldown_multiplier: float = 0.75
@export var phase_3_speed_multiplier: float = 1.6
@export var phase_3_cooldown_multiplier: float = 0.5

# Persistent red tint applied once the boss enters rage (phase 2+),
# on top of whatever base color it's already at.
@export var rage_tint: Color = Color(1.0, 0.6, 0.6)

# Health bar shown above the boss's head — built automatically at
# runtime, no manual scene setup needed.
@export var health_bar_width: float = 56.0
@export var health_bar_height: float = 7.0
@export var health_bar_offset: Vector2 = Vector2(0, -45)
@export var health_bar_color_normal: Color = Color(0.25, 0.85, 0.3)
@export var health_bar_color_rage: Color = Color(0.95, 0.55, 0.1)
@export var health_bar_color_low: Color = Color(0.9, 0.15, 0.15)

# If the boss touches the gate (once it's sealed shut), snap it back
# to this position instead of letting it push through/get stuck on it.
# Assign a Marker2D placed at the arena's center in the editor.
@export var arena_center_path: NodePath

# Left Punch — short, direct forward strike
@export var left_punch_range: float = 175.0
@export var left_punch_damage: int = 1
@export var left_punch_windup: float = 0.05
@export var left_punch_cooldown: float = 0.8
@export var left_punch_hit_fraction: float = 0.8

# Right Punch — hook with rotation, higher damage
@export var right_punch_range: float = 180.0
@export var right_punch_damage: int = 1
@export var right_punch_windup: float = 0.05
@export var right_punch_cooldown: float = 1.1
@export var right_punch_hit_fraction: float = 0.8

# How far the boss steps toward the player during an attack, and how
# quickly — in the exact direction to the player (any angle), so it
# reaches properly whether they're beside, above, or below it.
@export var lunge_distance: float = 40.0
@export var lunge_time: float = 0.15

# The attack frames are 128px wide vs 64px for idle/walk/jump, and the
# body sits left-of-center in that wider frame. This nudges it back so
# the torso lines up across all animations instead of visibly jumping
# when switching animations or flipping.
@export var wide_frame_offset_x: float = 20.0  # tune by eye in the editor
const WIDE_ANIMS = ["Left_Punch", "Right_Punch"]

enum State { INACTIVE, CHASE, TELEGRAPH, ATTACK, RECOVER, DEAD }
enum AttackType { LEFT_PUNCH, RIGHT_PUNCH }

var current_health: int
var current_phase: int = 1
var state: State = State.INACTIVE
var player: Node2D = null
var current_attack: AttackType = AttackType.LEFT_PUNCH
var state_timer: float = 0.0
var attack_cooldowns := {
	AttackType.LEFT_PUNCH: 0.0,
	AttackType.RIGHT_PUNCH: 0.0,
}
# Current cooldown durations, scaled down as rage phases kick in.
var left_punch_cooldown_current: float
var right_punch_cooldown_current: float
# The boss's persistent color when not mid-flash — white normally,
# switches to rage_tint once phase 2 hits.
var base_tint: Color = Color(1, 1, 1)
var health_bar_bg: ColorRect
var health_bar_fill: ColorRect
var has_been_hit: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


# Connect this to Hurtbox's area_entered signal in the editor
# (Node tab -> Signals -> area_entered).
func _on_hurtbox_area_entered(area: Area2D) -> void:
	take_damage(1)  # adjust damage amount, or read it from the weapon if it exposes one


func _play_anim(anim_name: String) -> void:
	var target_offset_x: float = 0.0
	if anim_name in WIDE_ANIMS:
		target_offset_x = -wide_frame_offset_x if sprite.flip_h else wide_frame_offset_x

	# Tween instead of snapping sprite.offset.x directly — an instant
	# jump here reads as the boss suddenly popping forward/back.
	if not is_equal_approx(sprite.offset.x, target_offset_x):
		var tween := create_tween()
		tween.tween_property(sprite, "offset:x", target_offset_x, 0.08)

	# Only restart playback if this is a new animation — calling play()
	# every frame (e.g. from _process_chase) would otherwise reset a
	# looping animation like "Walk" back to frame 0 every tick, making
	# it look frozen instead of animating.
	if sprite.animation != anim_name or not sprite.is_playing():
		sprite.play(anim_name)


func _anim_duration(anim_name: String) -> float:
	var frames := sprite.sprite_frames
	var count := frames.get_frame_count(anim_name)
	var speed := frames.get_animation_speed(anim_name)
	if speed <= 0.0:
		return 0.3
	return float(count) / speed


func _create_health_bar() -> void:
	var bar_top_left := health_bar_offset + Vector2(-health_bar_width / 2.0, 0)

	health_bar_bg = ColorRect.new()
	health_bar_bg.color = Color(0, 0, 0, 0.6)
	health_bar_bg.size = Vector2(health_bar_width + 4, health_bar_height + 4)
	health_bar_bg.position = bar_top_left - Vector2(2, 2)
	add_child(health_bar_bg)

	health_bar_fill = ColorRect.new()
	health_bar_fill.color = health_bar_color_normal
	health_bar_fill.size = Vector2(health_bar_width, health_bar_height)
	health_bar_fill.position = bar_top_left
	add_child(health_bar_fill)

	health_bar_bg.visible = false
	health_bar_fill.visible = false

	_update_health_bar()


func _update_health_bar() -> void:
	if health_bar_fill == null:
		return

	var pct: float = clampf(float(current_health) / float(max_health), 0.0, 1.0)
	health_bar_fill.size.x = health_bar_width * pct

	if current_phase >= 3:
		health_bar_fill.color = health_bar_color_low
	elif current_phase == 2:
		health_bar_fill.color = health_bar_color_rage
	else:
		health_bar_fill.color = health_bar_color_normal


func _ready() -> void:
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	left_punch_cooldown_current = left_punch_cooldown
	right_punch_cooldown_current = right_punch_cooldown
	_play_anim("Idle")
	_create_health_bar()


func activate() -> void:
	# Call this once — e.g. when the gate opens — to start the fight.
	if state != State.INACTIVE:
		return
	state = State.CHASE
	if health_bar_bg:
		health_bar_bg.visible = true
	if health_bar_fill:
		health_bar_fill.visible = true


func _physics_process(delta: float) -> void:
	if state == State.INACTIVE or state == State.DEAD:
		return

	_tick_cooldowns(delta)

	match state:
		State.CHASE:
			_process_chase(delta)
		State.TELEGRAPH:
			_process_telegraph(delta)
		State.RECOVER:
			_process_recover(delta)
		# State.ATTACK is driven by the await chain in _start_attack(),
		# not by a per-frame process function.

	move_and_slide()
	_check_gate_bounce()


func _check_gate_bounce() -> void:
	if arena_center_path.is_empty():
		return
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider and collider.is_in_group("gate"):
			var center := get_node(arena_center_path)
			if center:
				global_position = center.global_position
				velocity = Vector2.ZERO
			return


func _tick_cooldowns(delta: float) -> void:
	for key in attack_cooldowns.keys():
		if attack_cooldowns[key] > 0.0:
			attack_cooldowns[key] -= delta


# ── CHASE ────────────────────────────────────────────────────────
func _process_chase(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		velocity = Vector2.ZERO
		return

	var to_player: Vector2 = player.global_position - global_position
	var distance: float = to_player.length()

	var chosen := _pick_attack(distance)
	if chosen != -1:
		_start_telegraph(chosen)
		return

	velocity = to_player.normalized() * move_speed
	_play_anim("Walk")
	_update_facing(to_player)


func _pick_attack(distance: float) -> int:
	if distance <= right_punch_range and attack_cooldowns[AttackType.RIGHT_PUNCH] <= 0.0 and randf() < 0.4:
		return AttackType.RIGHT_PUNCH
	if distance <= left_punch_range and attack_cooldowns[AttackType.LEFT_PUNCH] <= 0.0:
		return AttackType.LEFT_PUNCH
	return -1


# ── TELEGRAPH (windup, so the player can react) ─────────────────
func _start_telegraph(attack: int) -> void:
	current_attack = attack
	state = State.TELEGRAPH
	velocity = Vector2.ZERO
	_play_anim("Idle")

	match attack:
		AttackType.LEFT_PUNCH:
			state_timer = left_punch_windup
		AttackType.RIGHT_PUNCH:
			state_timer = right_punch_windup

	if player:
		_update_facing(player.global_position - global_position)


func _process_telegraph(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_start_attack()


# ── ATTACK ───────────────────────────────────────────────────────
func _start_attack() -> void:
	state = State.ATTACK

	# Lunge toward wherever the player actually is (full 2D direction,
	# not just left/right) so the attack visually reaches them even if
	# they're above/below the boss, not only beside it.
	var lunge_dir := Vector2.ZERO
	if player and is_instance_valid(player):
		lunge_dir = (player.global_position - global_position).normalized()
	var lunge_tween := create_tween()
	lunge_tween.tween_property(self, "position", position + lunge_dir * lunge_distance, lunge_time)

	var anim_name: String
	var atk_range: float
	var dmg: int
	var hit_fraction: float

	match current_attack:
		AttackType.LEFT_PUNCH:
			anim_name = "Left_Punch"
			atk_range = left_punch_range
			dmg = left_punch_damage
			hit_fraction = left_punch_hit_fraction
		AttackType.RIGHT_PUNCH:
			anim_name = "Right_Punch"
			atk_range = right_punch_range
			dmg = right_punch_damage
			hit_fraction = right_punch_hit_fraction

	_play_anim(anim_name)
	var duration := _anim_duration(anim_name)
	var hit_delay := duration * hit_fraction

	# One strict sequential timeline instead of two independent timers —
	# guarantees the hit lands exactly once, in order, with no race
	# between the damage timer and the animation ending.
	await get_tree().create_timer(hit_delay).timeout
	if state != State.ATTACK:
		return  # interrupted (died / reset) — don't deal damage or recover
	_deal_damage(atk_range, dmg)

	var remaining := duration - hit_delay
	if remaining > 0.0:
		await get_tree().create_timer(remaining).timeout

	if state == State.ATTACK:
		_start_recover()


func _deal_damage(attack_range: float, damage: int) -> void:
	if player and is_instance_valid(player) and global_position.distance_to(player.global_position) <= attack_range:
		if player.has_method("take_damage"):
			player.take_damage(damage)


# ── RECOVER (cooldown before returning to chase) ────────────────
func _start_recover() -> void:
	state = State.RECOVER
	velocity = Vector2.ZERO

	match current_attack:
		AttackType.LEFT_PUNCH:
			state_timer = left_punch_cooldown_current
			attack_cooldowns[AttackType.LEFT_PUNCH] = left_punch_cooldown_current
		AttackType.RIGHT_PUNCH:
			state_timer = right_punch_cooldown_current
			attack_cooldowns[AttackType.RIGHT_PUNCH] = right_punch_cooldown_current

	_play_anim("Idle")


func _process_recover(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		state = State.CHASE


func _update_facing(direction: Vector2) -> void:
	if direction.x != 0:
		sprite.flip_h = direction.x < 0


# ── HEALTH / RAGE PHASES ──────────────────────────────────────────
func take_damage(amount: int) -> void:
	if state == State.DEAD:
		return

	if not has_been_hit:
		has_been_hit = true
		for gate in get_tree().get_nodes_in_group("gate"):
			if gate.has_method("seal_shut"):
				gate.seal_shut()

	current_health -= amount
	_flash_damage()
	_check_phase_transition()
	_update_health_bar()

	if current_health <= 0:
		_die()


func _check_phase_transition() -> void:
	var health_pct: float = float(current_health) / float(max_health)

	if current_phase < 2 and health_pct <= phase_2_threshold:
		current_phase = 2
		move_speed *= phase_2_speed_multiplier
		left_punch_cooldown_current = left_punch_cooldown * phase_2_cooldown_multiplier
		right_punch_cooldown_current = right_punch_cooldown * phase_2_cooldown_multiplier
		base_tint = rage_tint
		sprite.modulate = base_tint
		emit_signal("phase_changed", current_phase)
	elif current_phase < 3 and health_pct <= phase_3_threshold:
		current_phase = 3
		move_speed *= phase_3_speed_multiplier / phase_2_speed_multiplier
		left_punch_cooldown_current = left_punch_cooldown * phase_3_cooldown_multiplier
		right_punch_cooldown_current = right_punch_cooldown * phase_3_cooldown_multiplier
		emit_signal("phase_changed", current_phase)


func _flash_damage() -> void:
	sprite.modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(sprite):
		sprite.modulate = base_tint


func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	_play_anim("Idle")
	emit_signal("boss_died")
	for gate in get_tree().get_nodes_in_group("gate"):
		if gate.has_method("open_on_boss_defeat"):
			gate.open_on_boss_defeat()
	await _death_effect()
	queue_free()


func _death_effect() -> void:
	# Quick white flicker (a handful of flashes, not a rapid strobe —
	# kept brief since fast full-brightness flashing can be genuinely
	# uncomfortable/triggering for photosensitive players), then a
	# fade-out.
	var flash_count := 8
	for i in range(flash_count):
		sprite.modulate = Color(3, 3, 3)  # blown-out white, additive-looking
		await get_tree().create_timer(0.05).timeout
		if not is_instance_valid(sprite):
			return
		sprite.modulate = base_tint
		await get_tree().create_timer(0.05).timeout
		if not is_instance_valid(sprite):
			return

	if health_bar_bg:
		health_bar_bg.visible = false
	if health_bar_fill:
		health_bar_fill.visible = false

	var fade_tween := create_tween()
	fade_tween.tween_property(sprite, "modulate:a", 0.0, 0.6)
	await fade_tween.finished
	# Add loot drop / scene transition hook here, before queue_free() runs.
