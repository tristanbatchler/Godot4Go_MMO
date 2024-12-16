class_name RegisterForm
extends VBoxContainer

@onready var _username_field: LineEdit = $Username
@onready var _password_field: LineEdit = $Password
@onready var _confirm_password: LineEdit = $ConfirmPassword
@onready var _confirm_button: Button = $HBoxContainer/ConfirmButton
@onready var _cancel_button: Button = $HBoxContainer/CancelButton
@onready var _color_picker: ColorPicker = $ColorPicker

signal form_submitted(username: String, password: String, confirm_password: String, color: Color)
signal form_cancelled()

func _ready() -> void:
	_confirm_button.pressed.connect(_on_confirm_button_pressed)
	_cancel_button.pressed.connect(_on_cancel_button_pressed)
	
func _on_confirm_button_pressed() -> void:
	form_submitted.emit(_username_field.text, _password_field.text, _confirm_password.text, _color_picker.color)
	
func _on_cancel_button_pressed() -> void:
	form_cancelled.emit()
