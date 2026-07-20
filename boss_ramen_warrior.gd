extends CharacterBody2D

# ── Boss: Ramen Warrior ───────────────────────────────────────────
# Built around the Ramen Warrior asset pack's animation set:
#   Idle, Walk, Jump, Left_Punch, Right_Punch, Needle_Attack_1, Needle_Attack_2
#
# Phase 1 (100%–66% HP): left_punch + right_punch (close range)
# Phase 2 (66%–33% HP): adds needle_attack_1 (forward-thrusting, longer reach)
# Phase 3 (below 33% HP): adds needle_attack_2 (diagonal whip), faster overall

signal phase_changed(new_phase: int)
signal boss_died

@export var max_health: int = 30
@export var move_speed: float = 90.0
@export var phase_2_threshold: float = 0.66
@export var phase_3_threshold: float = 0.33
@export var enrage_speed_multiplier: float = 1.4

# Left Punch — short, direct forward strike (7 frames)
@export var left_punch_range: float = 175.0
@export var left_punch_damage: int = 1
@export var left_punch_windup: float = 0.05
@export var left_punch_cooldown: float = 0.8

# Right Punch — hook with rotation, more telegraphed (3 frames but wind up longer for readability)
@export var right_punch_range: float = 180.0
@export var right_punch_damage: int = 2
@export var right_punch_windup: float = 0.05
@export var right_punch_cooldown: float = 1.1

# Needle Attack 1 — forward-thrusting noodle extension, long reach
@export var needle1_range: float = 280.0
@export var needle1_damage: int = 2
@export var needle1_windup: float = 0.05
@export var needle1_cooldown: float = 1.6

# Needle Attack 2 — diagonal whipping strike, wide arc, phase 3 only
@export var needle2_range: float = 240.0
@export var needle2_damage: int = 2
@export var needle2_windup: float = 0.05
@export var needle2_cooldown: float = 1.4

enum State { INACTIVE, CHASE, TELEGRAPH, ATTACK, RECOVER, DEAD }
enum AttackType { LEFT_PUNCH, RIGHT_PUNCH, NEEDLE_1, NEEDLE_2 }

var current_health: int
var current_phase: int = 1
var state: State = State.INACTIVE
var player: Node2D = null
var current_attack: AttackType = AttackType.LEFT_PUNCH
var state_timer: float = 0.0
var attack_cooldowns := {
	AttackType.LEFT_PUNCH: 0.0,
	AttackType.RIGHT_PUNCH: 0.0,
	AttackType.NEEDLE_1: 0.0,
	AttackType.NEEDLE_2: 0.0,
}

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# The attack frames (punches + needle attacks) are 128px wide vs 64px for
# idle/walk/jump, and the body sits left-of-center in that wider frame.
# This nudges it back so the torso lines up across all animations instead
# of visibly jumping/swinging when switching animations or flipping.
@export var wide_frame_offset_x: float = 20.0  # tune by eye in the editor
const WIDE_ANIMS = ["Left_Punch", "Right_Punch", "Needle_Attack_1", "Needle_Attack_2"]


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


func _ready() -> void:
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	_play_anim("Idle")


func activate() -> void:
	# Call this once — e.g. when the gate opens — to start the fight.
	if state != State.INACTIVE:
		return
	state = State.CHASE


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
	# Prefer the longest-reaching attack the current phase unlocks and
	# whose cooldown is ready, falling back to punches up close.
	if current_phase >= 3 and distance <= needle2_range and attack_cooldowns[AttackType.NEEDLE_2] <= 0.0:
		return AttackType.NEEDLE_2
	if current_phase >= 2 and distance <= needle1_range and distance > right_punch_range and attack_cooldowns[AttackType.NEEDLE_1] <= 0.0:
		return AttackType.NEEDLE_1
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
		AttackType.NEEDLE_1:
			state_timer = needle1_windup
		AttackType.NEEDLE_2:
			state_timer = needle2_windup

	if player:
		_update_facing(player.global_position - global_position)


func _process_telegraph(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_start_attack()


# ── ATTACK ───────────────────────────────────────────────────────
# Fraction of the animation's duration at which the hit actually lands
# (e.g. 0.8 = 80% of the way through), so damage syncs with the visual
# strike frame instead of firing right at the start of the windup.
@export var left_punch_hit_fraction: float = 0.8
@export var right_punch_hit_fraction: float = 0.8
@export var needle1_hit_fraction: float = 0.7
@export var needle2_hit_fraction: float = 0.7

# How far the boss steps toward the player during an attack, and how
# quickly — in the exact direction to the player (any angle), so it
# reaches properly whether they're beside, above, or below it.
@export var lunge_distance: float = 40.0
@export var lunge_time: float = 0.15


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

	match current_attack:
		AttackType.LEFT_PUNCH:
			_play_anim("Left_Punch")
			_schedule_damage(_anim_duration("Left_Punch") * left_punch_hit_fraction, left_punch_range, left_punch_damage, AttackType.LEFT_PUNCH)
		AttackType.RIGHT_PUNCH:
			_play_anim("Right_Punch")
			_schedule_damage(_anim_duration("Right_Punch") * right_punch_hit_fraction, right_punch_range, right_punch_damage, AttackType.RIGHT_PUNCH)
		AttackType.NEEDLE_1:
			_play_anim("Needle_Attack_1")
			_schedule_damage(_anim_duration("Needle_Attack_1") * needle1_hit_fraction, needle1_range, needle1_damage, AttackType.NEEDLE_1)
		AttackType.NEEDLE_2:
			_play_anim("Needle_Attack_2")
			_schedule_damage(_anim_duration("Needle_Attack_2") * needle2_hit_fraction, needle2_range, needle2_damage, AttackType.NEEDLE_2)

	await sprite.animation_finished
	# Guard: the boss could have died or been reset while we were awaiting.
	if state == State.ATTACK:
		_start_recover()


func _anim_duration(anim_name: String) -> float:
	var frames := sprite.sprite_frames
	var count := frames.get_frame_count(anim_name)
	var speed := frames.get_animation_speed(anim_name)
	if speed <= 0.0:
		return 0.3
	return float(count) / speed


func _schedule_damage(delay: float, attack_range: float, damage: int, expected_attack: int) -> void:
	await get_tree().create_timer(delay).timeout
	# Guard against the boss having been interrupted, died, or moved on
	# to a different attack before this delayed hit would land.
	if state == State.ATTACK and current_attack == expected_attack:
		_deal_damage(attack_range, damage)


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
			state_timer = left_punch_cooldown
			attack_cooldowns[AttackType.LEFT_PUNCH] = left_punch_cooldown
		AttackType.RIGHT_PUNCH:
			state_timer = right_punch_cooldown
			attack_cooldowns[AttackType.RIGHT_PUNCH] = right_punch_cooldown
		AttackType.NEEDLE_1:
			state_timer = needle1_cooldown
			attack_cooldowns[AttackType.NEEDLE_1] = needle1_cooldown
		AttackType.NEEDLE_2:
			state_timer = needle2_cooldown
			attack_cooldowns[AttackType.NEEDLE_2] = needle2_cooldown

	_play_anim("Idle")


func _process_recover(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		state = State.CHASE


func _update_facing(direction: Vector2) -> void:
	if direction.x != 0:
		sprite.flip_h = direction.x < 0


# ── HEALTH / PHASES ──────────────────────────────────────────────
func take_damage(amount: int) -> void:
	if state == State.DEAD:
		return

	current_health -= amount
	_flash_damage()
	_check_phase_transition()

	if current_health <= 0:
		_die()


func _check_phase_transition() -> void:
	var health_pct: float = float(current_health) / float(max_health)

	if current_phase < 2 and health_pct <= phase_2_threshold:
		current_phase = 2
		emit_signal("phase_changed", current_phase)
	elif current_phase < 3 and health_pct <= phase_3_threshold:
		current_phase = 3
		move_speed *= enrage_speed_multiplier
		emit_signal("phase_changed", current_phase)


func _flash_damage() -> void:
	sprite.modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(sprite):
		sprite.modulate = Color(1, 1, 1)


func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	_play_anim("Idle")  # swap for a death animation if you add one later
	emit_signal("boss_died")
	# Add loot drop / scene transition hook here.
