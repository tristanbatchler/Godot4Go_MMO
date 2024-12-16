class_name LoginForm
extends VBoxContainer

@onready var _username_field: LineEdit = $Username
@onready var _password_field: LineEdit = $Password
@onready var _login_button: Button = $HBoxContainer/LoginButton
@onready var _hiscores_button: Button = $HBoxContainer/HiscoresButton

signal form_submitted(username: String, password: String)

func _ready() -> void:
	_login_button.pressed.connect(_on_login_button_pressed)
	_hiscores_button.pressed.connect(_on_hiscores_button_pressed)
	
func _on_login_button_pressed() -> void:
	form_submitted.emit(_username_field.text, _password_field.text)
	
func _on_hiscores_button_pressed() -> void:
	GameManager.set_state(GameManager.State.BROWSING_HISCORES)
