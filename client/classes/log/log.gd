class_name Log
extends RichTextLabel

func _message(message: String, color: Color = Color.WHITE) -> void:
	append_text("[color=#%s]%s[/color]\n" % [color.to_html(false), message])

func info(message: String) -> void:
	_message(message, Color.WHITE)
	
func warning(message: String) -> void:
	_message(message, Color.YELLOW)
	
func error(message: String) -> void:
	_message(message, Color.ORANGE_RED)
	
func success(message: String) -> void:
	_message(message, Color.LAWN_GREEN)
	
func chat(sender_name: String, message: String) -> void:
	_message("[color=#%s]%s:[/color] [i]%s[/i]" % [Color.CORNFLOWER_BLUE.to_html(false), sender_name, message])
