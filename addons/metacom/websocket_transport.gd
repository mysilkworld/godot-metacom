extends Metacom
class_name WebsocketTransport

var last_state := WebSocketPeer.STATE_CLOSED
var tls_options: TLSOptions = null

func _init(url, options: Dictionary[Metacom.Options, int] = {}) -> void:
	self.url = url
	self.tree = tree
	self.call_timeout = options[Metacom.Options.call_timeout]
	self.ping_interval = options[Metacom.Options.ping_interval]
	self.reconnect_timeout = options[Metacom.Options.reconnect_timeout]
	open()

func open() -> bool:
	socket = WebSocketPeer.new()
	var status := socket.connect_to_url(url, tls_options)
	
	if status == OK:
		active = true
	else:
		push_error("Unable to connect.")
		return false
	
	return false	

func send(method, args) -> Variant:
	var state := socket.get_ready_state()
	if state != socket.STATE_OPEN:
		await connected_to_server
	var results = await sendPacket(method, args)
	return results
	

func get_message() -> Variant:
	if socket.get_available_packet_count() < 1:
		return null
	var packet := socket.get_packet()
	if socket.was_string_packet():
		return packet.get_string_from_utf8()
	return bytes_to_var(packet)

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
		var data := socket.get_packet()
		if socket.was_string_packet():
			message(data.get_string_from_utf8())
