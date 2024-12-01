extends Node

const packets := preload("res://packets.gd")

func _ready() -> void:
	var data := [8, 69, 18, 15, 10, 13, 72, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100, 33]
	
	var packet := packets.Packet.new()
	packet.from_bytes(data)
	
	print(packet)
