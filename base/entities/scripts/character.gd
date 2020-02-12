extends KinematicBody2D
class_name Character

### Special effects
onready var dust_effect = load("res://base/entities/content/effects/dust.tscn")
### ---

### Sync
puppetsync var r_position = Vector2(0, 0)
puppetsync var r_animation = ""
puppetsync var r_flip_h = false

var p_position = Vector2(0, 0)
var p_jumping = false
### ---

onready var c_sprite = $Sprite
onready var c_anim = $Sprite/Animation
onready var c_body = $Sprite/Body
onready var c_head = $Sprite/Head
onready var c_name = $Name

onready var c_controller = $Controller

### Physics
export (int) var gravity = 500
export (int) var move_speed = 75
export (int) var jump_speed = 160
export (int) var fps = 24

var velocity = Vector2(0, 0)
### ---

func _ready():
	if c_controller.is_network_master():
		game_camera.target = self

	if c_controller.get_network_master() in network.players:
		var pinfo = network.players[c_controller.get_network_master()]
		c_name.text = pinfo.name

var interpolation = 0.0
func _process(delta):
	if is_network_master():
		pass
	else:
		# TODO: Improve position interpolation

		interpolation += delta / (1.0 / fps)
		position = position.linear_interpolate(r_position, interpolation)

		if interpolation > 1.0:
			interpolation = 0.0

func _physics_process(delta):
	if is_network_master():
		_process_input(delta)
		_process_animation(delta)

		velocity.y += gravity * delta
		velocity = move_and_slide(velocity, Vector2(0, -1))

	_sync(delta)

### Event processing
func _process_input(_delta):
	velocity.x = 0

	# Walk
	if c_controller.moveRight:
		velocity.x += move_speed

	if c_controller.moveLeft:
		velocity.x -= move_speed

	# Jump
	if c_controller.jumping && !c_controller.crouching && is_on_floor():
		velocity.y = -jump_speed

func _process_animation(_delta):
	if is_on_floor():
		if c_controller.moveLeft or c_controller.moveRight:
			_animate("walk", c_controller.moveLeft)
		else:
			if c_controller.crouching:
				_animate("crouch")
			else:
				_animate("idle")

		if c_controller.jumping:
			_animate("jump")

var timer = 0
func _sync(delta):
	timer += delta
	if timer > 1.0 / fps:
		timer -= 1.0 / fps
	else:
		return

	if is_network_master():
		if c_controller.jumping and is_on_floor():
			rpc("_play_dust_effect", global_position)

		rset_unreliable("r_animation", c_anim.current_animation)
		rset_unreliable("r_flip_h", c_controller.flip_h)
		rset_unreliable("r_position", position)
	else:
		_animate(r_animation, r_flip_h)
		p_position = position
### ---

func _animate(animation, t_flip_h = null):
	if c_anim.has_animation(animation):
		c_anim.play(animation)

	if t_flip_h != null && t_flip_h != c_controller.flip_h:
		c_controller.flip_h = t_flip_h

		c_sprite.scale.x *= -1

### Remote events
puppetsync func _play_dust_effect(pos):
	var dust = dust_effect.instance()
	dust.set_global_position(pos)

	get_node("/root").add_child(dust)
### ---
