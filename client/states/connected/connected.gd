extends Node

const packets := preload("res://packets.gd")

var _action_on_ok_received: Callable

@onready var _login_form: LoginForm = $UI/MarginContainer/VBoxContainer/LoginForm
@onready var _register_form: RegisterForm = $UI/MarginContainer/VBoxContainer/RegisterForm
@onready var _register_prompt: RichTextLabel = $UI/MarginContainer/VBoxContainer/RegisterPrompt
@onready var _log: Log = $UI/MarginContainer/VBoxContainer/Log

func _ready() -> void:
	WS.packet_received.connect(_on_ws_packet_received)
	WS.connection_closed.connect(_on_ws_connection_closed)
	_login_form.form_submitted.connect(_on_login_form_submitted)
	_register_form.form_submitted.connect(_on_register_form_submitted)
	_register_form.form_cancelled.connect(_on_register_form_cancelled)
	_register_prompt.meta_clicked.connect(_on_register_prompt_meta_clicked)
	

func _on_ws_packet_received(packet: packets.Packet) -> void:
	var sender_id := packet.get_sender_id()
	if packet.has_deny_response():
		var deny_response_msg := packet.get_deny_response()
		_log.error(deny_response_msg.get_reason())
	elif packet.has_ok_response():
		_action_on_ok_received.call()
	
func _on_ws_connection_closed() -> void:
	_log.warning("Connection closed")

func _on_login_form_submitted(username: String, password: String) -> void:
	var packet := packets.Packet.new()
	var login_request_msg := packet.new_login_request()
	login_request_msg.set_username(username)
	login_request_msg.set_password(password)
	WS.send(packet)
	_action_on_ok_received = func(): GameManager.set_state(GameManager.State.INGAME)

	
func _on_register_form_submitted(username: String, password: String, confirm_password: String, color: Color) -> void:
	if password != confirm_password:
		_log.error("Passwords do not match")
		return
	
	var packet := packets.Packet.new()
	var register_request_msg := packet.new_register_request()
	register_request_msg.set_username(username)
	register_request_msg.set_password(password)
	register_request_msg.set_color(color.to_rgba32())
	WS.send(packet)
	_action_on_ok_received = func(): _log.success("Registration successful! Please go back and log in.")

func _on_register_form_cancelled() -> void:
	_register_form.hide()
	_login_form.show()
	_register_prompt.show()
	
func _on_register_prompt_meta_clicked(meta) -> void:
	if meta is String and meta == "register":
		_login_form.hide()
		_register_form.show()
		_register_prompt.hide()

func _on_hiscores_button_pressed() -> void:
	GameManager.set_state(GameManager.State.BROWSING_HISCORES)
