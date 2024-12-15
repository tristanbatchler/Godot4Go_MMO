extends Node

const packets := preload("res://packets.gd")

@onready var _back_button: Button = $UI/VBoxContainer/HBoxContainer/BackButton
@onready var _line_edit: LineEdit = $UI/VBoxContainer/HBoxContainer/LineEdit
@onready var _search_button: Button = $UI/VBoxContainer/HBoxContainer/SearchButton

@onready var _hiscores: Hiscores = $UI/VBoxContainer/Hiscores
@onready var _log: Log = $UI/VBoxContainer/Log

func _ready() -> void:
	_back_button.pressed.connect(_on_back_button_pressed)
	_line_edit.text_submitted.connect(_on_search_button_pressed)
	_search_button.pressed.connect(_on_search_button_pressed)
	
	WS.packet_received.connect(_on_ws_packet_received)
	
	var packet := packets.Packet.new()
	packet.new_hiscore_board_request()
	WS.send(packet)
	
func _on_back_button_pressed() -> void:
	var packet := packets.Packet.new()
	packet.new_finished_browsing_hiscores()
	WS.send(packet)
	GameManager.set_state(GameManager.State.CONNECTED)
	
func _on_ws_packet_received(packet: packets.Packet) -> void:
	if packet.has_hiscore_board():
		_handle_hiscore_board_msg(packet.get_hiscore_board())
	elif packet.has_deny_response():
		_handle_deny_response(packet.get_deny_response())
		
func _handle_hiscore_board_msg(hiscore_board_msg: packets.HiscoreBoardMessage) -> void:
	_hiscores.clear_hiscores()
	for hiscore_msg: packets.HiscoreMessage in hiscore_board_msg.get_hiscores():
		var name := hiscore_msg.get_name()
		var rank_and_name := "%d. %s" % [hiscore_msg.get_rank(), name]
		var score := hiscore_msg.get_score()
		var highlight := name.to_lower() == _line_edit.text.to_lower()
		_hiscores.set_hiscore(rank_and_name, score, highlight)

func _handle_deny_response(deny_response_msg: packets.DenyResponseMessage) -> void:
	_log.error(deny_response_msg.get_reason())

func _on_search_button_pressed() -> void:
	var packet := packets.Packet.new()
	var search_hiscore_msg := packet.new_search_hiscore()
	search_hiscore_msg.set_name(_line_edit.text)
	WS.send(packet)
