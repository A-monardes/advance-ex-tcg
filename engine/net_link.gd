class_name NetLink
extends RefCounted
## Conexión de una partida en línea con el relay (server/relay.js) por WebSocket.
## Anda igual en PC y en la web. El relay solo une a dos jugadores por un código de sala y
## les pasa los mensajes; la partida la calculan los dos juegos a la vez.
##
## Uso: host(url) o join(url, "ABCD"), y poll() en cada cuadro. Lo que manda el otro queda
## en inbox (diccionarios); send(dic) se lo manda.

const DEFAULT_URL := "ws://127.0.0.1:8080"

var ws := WebSocketPeer.new()
var url := ""
var status := "idle"     # idle · connecting · waiting (sala creada, falta el otro) · ready · closed · error
var room := ""
var you := -1            # 0 = creó la sala, 1 = se unió
var error := ""
var inbox: Array = []
var _pending_op := {}    # lo que hay que mandar al abrir la conexión


func host(server_url: String) -> void:
	_open(server_url, {"op": "create"})


func join(server_url: String, code: String) -> void:
	_open(server_url, {"op": "join", "room": code.strip_edges().to_upper()})


func _open(server_url: String, first: Dictionary) -> void:
	url = server_url
	_pending_op = first
	inbox.clear()
	error = ""
	room = ""
	you = -1
	var err := ws.connect_to_url(url)
	if err != OK:
		status = "error"
		error = "Can't connect to the server (%s)." % url
		return
	status = "connecting"


func poll() -> void:
	if status in ["idle", "closed", "error"]:
		return
	ws.poll()
	var st := ws.get_ready_state()
	if st == WebSocketPeer.STATE_OPEN and not _pending_op.is_empty():
		ws.send_text(JSON.stringify(_pending_op))
		_pending_op = {}
	while ws.get_available_packet_count() > 0:
		var m = JSON.parse_string(ws.get_packet().get_string_from_utf8())
		if not m is Dictionary:
			continue
		match str(m.get("op", "")):
			"created":
				room = str(m.get("room", ""))
				status = "waiting"
			"start":
				room = str(m.get("room", room))
				you = int(m.get("you", 0))
				status = "ready"
			"msg":
				if m.get("data") is Dictionary:
					inbox.append(m["data"])
			"left":
				status = "closed"
				error = "The opponent left."
			"error":
				status = "error"
				match str(m.get("why", "")):
					"no such room": error = "There's no game with that code."
					"room full": error = "That game already has two players."
					_: error = "Server error: " + str(m.get("why", ""))
	if st == WebSocketPeer.STATE_CLOSED and status not in ["closed", "error"]:
		status = "error" if status == "connecting" else "closed"
		error = "Can't reach the server." if status == "error" else "Connection lost."


func send(data: Dictionary) -> void:
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.send_text(JSON.stringify({"op": "msg", "data": data}))


func close() -> void:
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.send_text(JSON.stringify({"op": "leave"}))
		ws.close()
	status = "idle"
