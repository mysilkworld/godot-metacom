extends RefCounted
class_name Metacom

signal connected_to_server
signal connection_closed
signal message_received(message: Variant)

enum Options { call_timeout, ping_interval, reconnect_timeout }

const CALL_TIMEOUT: int = 7 * 1000
const PING_INTERVAL: int = 60 * 1000;
const RECONNECT_TIMEOUT: int = 2 * 1000;

var url: String
var socket: WebSocketPeer
var api: Dictionary
var call_id: int = 0
var calls: Dictionary[int, Signal]
var streams: Dictionary
var stream_id: int = 0
var active: bool = false
var connected: bool = false
var opening = null
var last_activity
var call_timeout: int
var ping_interval: int
var reconnect_timeout: int
var ping = null
var tree = null

func _init(url, options: Dictionary[Options, int] = {}) -> void:
	print("_init Metacom ")

static func create(url, metacom_options: Dictionary[Options, int] = {}):
	var options: Dictionary[Options, int] = {
		Options.call_timeout: metacom_options.get(Options.call_timeout, CALL_TIMEOUT),
		Options.ping_interval: metacom_options.get(Options.ping_interval, PING_INTERVAL),
		Options.reconnect_timeout: metacom_options.get(Options.reconnect_timeout, RECONNECT_TIMEOUT),
	}
	var transport = Transport.new()
	if url.begins_with("ws"): 
		return transport.ws.new(url, options)
	elif url.begins_with("http"):
		return transport.http.new(url, options)
	push_error("Unsupported URL scheme: ", url)

func createPacket(method, args) -> Dictionary:
	call_id = call_id + 1
	var packet = {
		"id": call_id,
		"type": "call",
		"args": args,
		"method": method,
	}
	return packet

func sendPacket(method, args) -> Variant:
	var packet = createPacket(method, args)
	var signale_name = str(packet.id)
	var promise = Signal(self, signale_name)
	calls[packet.id] = promise
	var jsonPacket = JSON.stringify(packet)
	socket.send_text(jsonPacket)
	add_user_signal(signale_name)
	return await promise

func message(data):
	var packet = JSON.parse_string(data)
	packet.id = int(packet.id)
	if packet.type == "event":
		print("it`s event")
	if not packet.id:
		push_error("Packet structure error")
	if packet.type == "callback":
		var promise = calls[packet.id] 
		promise.emit(packet)
		remove_user_signal(str(packet.id))
	
	
	
	
