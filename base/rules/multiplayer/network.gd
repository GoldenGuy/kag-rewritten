extends Node2D

signal connection_established()
signal connection_closed()

signal player_added(pinfo)
signal player_removed(pinfo)

var player = {
	id = 1,
	name = "Guest",
	character = "",
}

var players = {}

func _ready():
	get_tree().connect("network_peer_connected", self, "_on_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")

	get_tree().connect("connected_to_server", self, "_on_connection_established")
	get_tree().connect("server_disconnected", self, "_on_connection_closed")
	get_tree().connect("connection_failed", self, "_on_connection_closed")

	$Server.connect("create_success", self, "_on_connection_established")
	$Server.connect("create_fail", self, "_on_connection_closed")

func create_server(name: String, port: int):
	$Server._create_server(name, port)

func join_server(ip: String, port: int):
	$Client._join_server(ip, port)

### --- Events

func _on_player_connected(id):
	if id != 1:
		rpc_id(id, "register_player", player)

func _on_player_disconnected(id):
	unregister_player(id)

func _on_connection_established():
	emit_signal("connection_established")

	if get_tree().is_network_server():
		call_deferred("register_player", player)
	else:
		network.player.id = get_tree().get_network_unique_id()
		register_player(player)

func _on_connection_closed():
	get_tree().set_network_peer(null)

	emit_signal("connection_closed")

### --- Remote functions

remote func register_player(pinfo):
	if get_tree().get_rpc_sender_id() == 0 && pinfo.id != 1:
		rpc_id(1, "register_player", player)

	players[pinfo.id] = pinfo
	emit_signal("player_added", pinfo)

func unregister_player(id):
	if not (id in players):
		print("No player with this ID to unregister.")
		return

	var pinfo = players[id]
	players.erase(id)

	emit_signal("player_removed", pinfo)
