extends CanvasLayer

### PanelPlayer
onready var playerName = $PanelPlayer/Content/txtPlayerName
### ---

### PanelHost
onready var hostServerName = $PanelHost/Content/txtServerName
onready var hostServerPort = $PanelHost/Content/txtServerPort
### ---

### PanelJoin
onready var joinServerIP = $PanelJoin/Content/txtJoinIP
onready var joinServerPort = $PanelJoin/Content/txtJoinPort
### ---

func _ready():
	network.connect("connection_established", self, "_on_connection_established")
	network.connect("connection_closed", self, "_on_connection_closed")

	if "--host=true" in OS.get_cmdline_args():
		set_player_info()
		network.create_server("KAG-Rewritten Server", 3074)

func set_player_info():
	if (!playerName.text.empty()):
		network.player.name = playerName.text

func _on_btCreate_pressed():
	set_player_info()

	var name = hostServerName.text
	var port = int(joinServerPort.text)

	network.create_server(name, port)

func _on_btJoin_pressed():
	set_player_info()

	var ip = joinServerIP.text
	var port = int(joinServerPort.text)

	network.join_server(ip, port)

### --- Events

func _on_connection_established():
	if get_tree().change_scene("res://base/levels/content/multiplayer.tscn") != OK:
		push_error("Failed loading the scene.")

func _on_connection_closed():
	print("Failed to join server.")
