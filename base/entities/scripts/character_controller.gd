extends Node2D

export (int) var fps = 24
export (float) var emote_time = 3
export (Array, String) var emote_directories

### Input
puppetsync var flip_h = false

puppetsync var jumping = false
puppetsync var crouching = false

puppetsync var moveRight = false
puppetsync var moveLeft = false
### ---god

onready var character = get_parent()
onready var character_emote = character.get_node("Emote")
onready var character_timer = character.get_node("Timer")
var emote_array = {}

func _ready():
	_load_emotes()
	
	if is_network_master():
		game_chat.connect("chat_opened", self, "_on_chat_opened")
		game_chat.connect("chat_closed", self, "_on_chat_closed")

func _process(delta):
	_sync(delta)

func _unhandled_input(event):
	if not is_network_master():
		return
	
	for key in emote_array.keys():
		if Input.is_action_just_pressed(emote_array[key].action):
			rpc("_play_emote", key)
	
	if Input.is_action_just_pressed("move_left"):
		moveLeft = true
	if Input.is_action_just_released("move_left"):
		moveLeft = false
	
	if Input.is_action_just_pressed("move_right"):
		moveRight = true
	if Input.is_action_just_released("move_right"):
		moveRight = false
	
	# Crouch
	if Input.is_action_just_pressed("crouch"):
		crouching = true
	if Input.is_action_just_released("crouch"):
		crouching = false
		
	# Jump
	if Input.is_action_just_pressed("jump"):
		jumping = true
	if Input.is_action_just_released("jump"):
		jumping = false

var timer = 0
func _sync(delta):
	timer += delta
	if timer > 1.0 / fps:
		timer -= 1.0 / fps
	else:
		return
	
	if is_network_master() && get_tree().get_network_unique_id() != 1:
		rset_id(1, "moveLeft", moveLeft)
		rset_id(1, "moveRight", moveRight)
		rset_id(1, "jumping", jumping)
		rset_id(1, "crouching", crouching)

func _load_emotes():
	var file = ""
	var dir = Directory.new()
	for path in emote_directories:
		if dir.open(path) != OK:
			continue
		dir.list_dir_begin()
		file = dir.get_next()
		while file != "":
			if file.ends_with(".tres"):
				var emote = load(path + file)
				
				if emote is Emote:
					emote_array[path + file] = emote
			
			file = dir.get_next()

puppetsync func _play_emote(key):
	if !emote_array.has(key):
		return
	
	character_timer.stop()
	character_emote.set_texture(emote_array[key].image)
	character_timer.start(emote_time)
	
	yield (character_timer, "timeout")
	character_emote.set_texture(null)

puppetsync func _start_chat_emote():
	character_emote.set_texture(game_chat.emote_typing.image)

puppetsync func _stop_chat_emote():
	character_emote.set_texture(null)

func _on_chat_opened():
	rpc("_start_chat_emote")

func _on_chat_closed():
	rpc("_stop_chat_emote")
