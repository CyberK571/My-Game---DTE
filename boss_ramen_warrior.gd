extends CharacterBody2D

# ── Boss: Ramen Warrior (Island 1) ────────────────────────────────
# Punch-only boss for this island. Needle/lasso attacks are saved for
# a later island's version of this boss.
#
# Phase 1 (100%–66% HP): normal punches, normal speed
# Phase 2 (66%–33% HP): RAGE — faster movement + shorter attack cooldowns
# Phase 3 (below 33% HP): RAGE 2 — even faster, minimal cooldowns

signal phase_changed(new_phase: int)
signal boss_died

@export var max_health: int = 30
@export var move_speed: float = 90.0
@export var phase_2_threshold: float = 0.66
@export var phase_3_threshold: float = 0.33

# Rage tuning — multipliers applied to move_speed and to attack
# cooldowns when each phase kicks in (cooldown multiplier < 1 = faster).
@export var phase_2_speed_multiplier: float = 1.3
@export var phase_2_cooldown_multiplier: float = 0.75
@export var phase_3_speed_multiplier: float = 1.6
@export var phase_3_cooldown_multiplier: float = 0.5

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


func _ready() -> void:
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	left_punch_cooldown_current = left_punch_cooldown
	right_punch_cooldown_current = right_punch_cooldown
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

	current_health -= amount
	_flash_damage()
	_check_phase_transition()

	if current_health <= 0:
		_die()


func _check_phase_transition() -> void:
	var health_pct: float = float(current_health) / float(max_health)

	if current_phase < 2 and health_pct <= phase_2_threshold:
		current_phase = 2
		move_speed *= phase_2_speed_multiplier
		left_punch_cooldown_current = left_punch_cooldown * phase_2_cooldown_multiplier
		right_punch_cooldown_current = right_punch_cooldown * phase_2_cooldown_multiplier
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
		sprite.modulate = Color(1, 1, 1)


func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	_play_anim("Idle")  # swap for a death animation if you add one later
	emit_signal("boss_died")
	# Add loot drop / scene transition hook here.
