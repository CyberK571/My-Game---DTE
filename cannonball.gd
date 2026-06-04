extends Area2D

var speed = 400
var direction = Vector2.ZERO

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		body.take_hit()
	queue_free()  # destroy cannonball on any hit
