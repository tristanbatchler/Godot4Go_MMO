class_name WebSocketClient
extends Node

const packets := preload("res://packets.gd")

@export var handshake_headers: PackedStringArray
@export var supported_protocols: PackedStringArray
var tls_options: TLSOptions = null

var socket := WebSocketPeer.new()
var last_state := WebSocketPeer.STATE_CLOSED

signal connected_to_server()
signal connection_closed()
signal packet_received(packet: packets.Packet)

func connect_to_url(url: String) -> int:
	socket.supported_protocols = supported_protocols
	socket.handshake_headers = handshake_headers

	var err := socket.connect_to_url(url, tls_options)
	if err != OK:
		return err

	last_state = socket.get_ready_state()
	return OK


func send(packet: packets.Packet) -> int:
	packet.set_sender_id(0)
	var data := packet.to_bytes()
	return socket.send(data)


func get_packet() -> packets.Packet:
	if socket.get_available_packet_count() < 1:
		return null
	var data := socket.get_packet()
	var packet := packets.Packet.new()
	var result := packet.from_bytes(data)
	if result != OK:
		printerr("Error formatting packet from data %s" % data.get_string_from_utf8())
		
	return packet


func close(code: int = 1000, reason: String = "") -> void:
	socket.close(code, reason)
	last_state = socket.get_ready_state()


func clear() -> void:
	socket = WebSocketPeer.new()
	last_state = socket.get_ready_state()


func get_socket() -> WebSocketPeer:
	return socket


func poll() -> void:
	if socket.get_ready_state() != socket.STATE_CLOSED:
		socket.poll()

	var state := socket.get_ready_state()

	if last_state != state:
		last_state = state
		if state == socket.STATE_OPEN:
			connected_to_server.emit()
		elif state == socket.STATE_CLOSED:
			connection_closed.emit()
	while socket.get_ready_state() == socket.STATE_OPEN and socket.get_available_packet_count():
		packet_received.emit(get_packet())


func _process(_delta: float) -> void:
	poll()
