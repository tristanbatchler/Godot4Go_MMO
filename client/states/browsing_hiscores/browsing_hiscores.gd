extends Node

const packets := preload("res://packets.gd")

@onready var _hiscores: Hiscores = $UI/Hiscores

func _ready() -> void:
	WS.packet_received.connect(_on_ws_packet_received)
	
	var packet := packets.Packet.new()
	packet.new_hiscore_board_request()
	WS.send(packet)
	
func _on_ws_packet_received(packet: packets.Packet) -> void:
	if packet.has_hiscore_board():
		_handle_hiscore_board_msg(packet.get_hiscore_board())
		
func _handle_hiscore_board_msg(hiscore_board_msg: packets.HiscoreBoardMessage) -> void:
	for hiscore_msg: packets.HiscoreMessage in hiscore_board_msg.get_hiscores():
		var name := hiscore_msg.get_name()
		var rank_and_name := "%d. %s" % [hiscore_msg.get_rank(), name]
		var score := hiscore_msg.get_score()
		_hiscores.set_hiscore(rank_and_name, score)
