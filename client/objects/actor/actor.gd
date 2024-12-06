extends Area2D

const packets := preload("res://packets.gd")

const Scene := preload("res://objects/actor/actor.tscn")
const Actor := preload("res://objects/actor/actor.gd")

var actor_id: int
var actor_name: String
var start_x: float
var start_y: float
var start_rad: float
var speed: float
var is_player: bool

var velocity: Vector2
var radius: float

@onready var _nameplate: Label = $Nameplate
@onready var _collision_shape: CircleShape2D = $CollisionShape2D.shape
@onready var _camera: Camera2D = $Camera2D

static func instatiate(actor_id: int, actor_name: String, x: float, y: float, rad: float, speed: float, is_player: bool) -> Actor:
	var actor := Scene.instantiate()
	actor.actor_id = actor_id
	actor.actor_name = actor_name
	actor.start_x = x
	actor.start_y = y
	actor.start_rad = rad
	actor.speed = speed
	actor.is_player = is_player
	
	return actor
	
func _ready():
	position.x = start_x
	position.y = start_y
	
	velocity = Vector2.RIGHT * speed
	radius = start_rad
	
	_collision_shape.radius = radius
	_nameplate.text = actor_name
	
func _physics_process(delta: float) -> void:
	position += velocity * delta
	
	if not is_player:
		return
	# Player-specific stuff below here
	
	var mouse_pos := get_global_mouse_position()
	
	var input_vec := position.direction_to(mouse_pos).normalized()
	if abs(velocity.angle_to(input_vec)) > TAU / 15: 
		velocity = input_vec * speed
		var packet := packets.Packet.new()
		var player_direction_msg := packet.new_player_direction()
		player_direction_msg.set_direction(velocity.angle())
		WS.send(packet)
		
func _input(event: InputEvent) -> void:
	if is_player and event is InputEventMouseButton and event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_camera.zoom.x = min(4, _camera.zoom.x + 0.1)
			MOUSE_BUTTON_WHEEL_DOWN:
				_camera.zoom.x = max(0.1, _camera.zoom.x - 0.1)
		_camera.zoom.y = _camera.zoom.x
	
func _draw() -> void:
	draw_circle(Vector2.ZERO, _collision_shape.radius, Color.DARK_ORCHID)
