extends CharacterBody2D

@export var chase_speed: float = 80.0
@export var activation_range: float = 600.0

var player: Node2D
var active: bool = false

func _ready():
    player = get_tree().get_root().find_child("Ship", true, false)

func _physics_process(delta):
    if player == null:
        return

    var dist = global_position.distance_to(player.global_position)

    # Activate when player gets close
    if not active and dist < activation_range:
        active = true

    if not active:
        return  # sit still until activated

    var diff = player.global_position - global_position
    velocity = diff.normalized() * chase_speed
    move_and_slide()

    # Subtle tilt toward player
    var dir = diff.normalized()
    rotation = lerp(rotation, (dir.x - dir.y) * -0.15, delta * 3)

    # Game over on contact
    for i in get_slide_collision_count():
        var collision = get_slide_collision(i)
        if collision.get_collider().name == "Ship":
            get_tree().paused = true

var hits: int = 0
var max_hits: int = 2
var is_dying: bool = false

func take_hit():
    if is_dying:
        return
    hits += 1
    _flash_red()
    if hits >= max_hits:
        _die()

func _flash_red():
    $Sprite2D.modulate = Color(1, 0, 0, 1)
    await get_tree().create_timer(0.15).timeout
    $Sprite2D.modulate = Color(1, 1, 1, 1)

func _die():
    is_dying = true
    var tween = create_tween()
    tween.tween_property($Sprite2D, "modulate", Color(0, 0, 0, 0), 0.8)
    tween.tween_callback(queue_free)
