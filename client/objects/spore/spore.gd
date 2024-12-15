extends Area2D

const Scene := preload("res://objects/spore/spore.tscn")
const Spore := preload("res://objects/spore/spore.gd")
const Actor := preload("res://objects/actor/actor.gd")

var spore_id: int
var x: float
var y: float
var radius: float
var color: Color
var underneath_player: bool

@onready var _collision_shape: CircleShape2D = $CollisionShape2D.shape

static func instantiate(spore_id: int, x: float, y: float, radius: float, underneath_player: bool) -> Spore:
	var spore := Scene.instantiate()
	spore.spore_id = spore_id
	spore.x = x
	spore.y = y
	spore.radius = radius
	spore.underneath_player = underneath_player
	
	return spore

func _ready() -> void:
	if underneath_player:
		area_exited.connect(_on_area_exited)
	
	position.x = x
	position.y = y
	_collision_shape.radius = radius
	color = Color.from_hsv(randf(), 1, 1, 1)
	
func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
	
func _on_area_exited(area: Area2D) -> void:
	if area is Actor:
		underneath_player = false
