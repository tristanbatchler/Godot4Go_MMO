extends Area2D

const Scene := preload("res://objects/spore/spore.tscn")
const Spore := preload("res://objects/spore/spore.gd")

var spore_id: int
var x: float
var y: float
var radius: float
var color: Color

@onready var _collision_shape: CircleShape2D = $CollisionShape2D.shape

static func instantiate(spore_id: int, x: float, y: float, radius: float) -> Spore:
	var spore := Scene.instantiate()
	spore.spore_id = spore_id
	spore.x = x
	spore.y = y
	spore.radius = radius
	
	return spore

func _ready() -> void:
	position.x = x
	position.y = y
	_collision_shape.radius = radius
	color = Color.from_hsv(randf(), 1, 1, 1)
	
func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
