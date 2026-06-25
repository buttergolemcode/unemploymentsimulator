# PlayerController.gd — First-person player movement
# Uses direct key checks instead of InputMap actions for reliability
extends CharacterBody3D

const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const MOUSE_SENS = 0.0022
const PITCH_LIMIT = 1.5

var yaw: float = 0.0
var pitch: float = 0.0
var camera_mode: String = "first"
var in_vehicle = null

@onready var camera: Camera3D = $Camera3D

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if GameManager.phase != "playing":
		return
	
	# Mouse look — must check for motion AND captured mouse
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * MOUSE_SENS
		pitch -= event.relative.y * MOUSE_SENS
		pitch = clamp(pitch, -PITCH_LIMIT, PITCH_LIMIT)
	
	# Toggle camera with V
	if event is InputEventKey and event.pressed and event.keycode == KEY_V:
		camera_mode = "third" if camera_mode == "first" else "first"
		visible = camera_mode == "third"
	
	# Interact with E
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		_try_interact()
	
	# End day with B
	if event is InputEventKey and event.pressed and event.keycode == KEY_B:
		if GameManager.actions_left > 0:
			# Confirm
			pass
		else:
			GameManager.end_day()
	
	# Release mouse on Escape
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Click to recapture mouse
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	if GameManager.phase != "playing":
		return
	if in_vehicle:
		visible = false
		return
	
	visible = camera_mode == "third"
	
	# Apply rotation
	rotation.y = yaw
	camera.rotation.x = pitch
	
	# Movement — direct key checks
	var input_forward = 0.0
	var input_right = 0.0
	
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_forward += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_forward -= 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_right -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_right += 1.0
	
	# Transform to world space based on yaw
	var forward = Vector3(-sin(yaw), 0, -cos(yaw))
	var right = Vector3(cos(yaw), 0, -sin(yaw))
	var wish_dir = (forward * input_forward + right * input_right).normalized()
	
	var speed = SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else WALK_SPEED
	
	velocity.x = wish_dir.x * speed
	velocity.z = wish_dir.z * speed
	
	# Gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0
	
	move_and_slide()
	
	# Camera position
	if camera_mode == "first":
		camera.position = Vector3(0, 1.6, 0)
		camera.fov = 70
	else:
		var dist = 6.0
		var h = 4.0
		var offset = Vector3(sin(yaw) * dist, h, cos(yaw) * dist)
		camera.global_position = global_position + offset
		camera.look_at(global_position + Vector3(0, 1.2, 0))
		camera.fov = 60
	
	# Check nearby building
	_check_nearby()

var nearby_building_id = ""
var nearby_building_node = null

func _check_nearby():
	if get_parent() == null:
		return
	
	var buildings = get_tree().get_nodes_in_group("scheme_building")
	var nearest = null
	var nearest_dist = 999.0
	
	for b in buildings:
		var d = global_position.distance_to(b.global_position)
		if d < 8.0 and d < nearest_dist:
			nearest_dist = d
			nearest = b
	
	if nearest:
		var sid = nearest.get_meta("scheme_id", "")
		if sid != nearby_building_id:
			nearby_building_id = sid
			nearby_building_node = nearest
			GameManager.log_message.emit("Press E to enter %s" % nearest.get_meta("scheme_name", ""), "info")
	elif nearby_building_id != "":
		nearby_building_id = ""
		nearby_building_node = null

func _try_interact():
	if nearby_building_id != "" and nearby_building_node:
		var game_scene = get_parent()
		if game_scene and game_scene.has_method("on_player_interact"):
			game_scene.on_player_interact(nearby_building_id)

func enter_vehicle(vehicle):
	in_vehicle = vehicle
	visible = false

func exit_vehicle():
	if in_vehicle:
		var v = in_vehicle
		in_vehicle = null
		global_position = v.global_position + Vector3(2, 0, 0)
		visible = camera_mode == "third"
