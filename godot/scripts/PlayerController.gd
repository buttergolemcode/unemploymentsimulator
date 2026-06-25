# PlayerController.gd — First-person player + vehicle enter/exit
extends CharacterBody3D

const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const MOUSE_SENS = 0.0022
const PITCH_LIMIT = 1.5

var yaw: float = 0.0
var pitch: float = 0.0
var camera_mode: String = "first"
var in_vehicle: Node = null

@onready var camera: Camera3D = $Camera3D

func _ready():
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if GameManager.phase != "playing":
		return
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * MOUSE_SENS
		pitch -= event.relative.y * MOUSE_SENS
		pitch = clamp(pitch, -PITCH_LIMIT, PITCH_LIMIT)
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_V:
				camera_mode = "third" if camera_mode == "first" else "first"
				visible = camera_mode == "third"
			KEY_E:
				_try_interact()
			KEY_F:
				_try_vehicle_enter_exit()
			KEY_B:
				if GameManager.actions_left == 0:
					GameManager.end_day()
			KEY_ESCAPE:
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				else:
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	if GameManager.phase != "playing":
		return
	
	if in_vehicle:
		visible = false
		# Camera follows vehicle (chase cam)
		_update_vehicle_camera()
		return
	
	visible = camera_mode == "third"
	rotation.y = yaw
	camera.rotation.x = pitch
	
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
	
	var forward = Vector3(-sin(yaw), 0, -cos(yaw))
	var right = Vector3(cos(yaw), 0, -sin(yaw))
	var wish_dir = (forward * input_forward + right * input_right).normalized()
	
	var speed = SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else WALK_SPEED
	velocity.x = wish_dir.x * speed
	velocity.z = wish_dir.z * speed
	
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0
	
	move_and_slide()
	
	if camera_mode == "first":
		camera.position = Vector3(0, 1.6, 0)
		camera.fov = 70
	else:
		var dist = 6.0
		var h = 4.0
		camera.global_position = global_position + Vector3(sin(yaw) * dist, h, cos(yaw) * dist)
		camera.look_at(global_position + Vector3(0, 1.2, 0))
		camera.fov = 60
	
	_check_nearby()

func _update_vehicle_camera():
	var v = in_vehicle
	if not v:
		return
	var dist = 8.0
	var h = 3.8
	camera.global_position = v.global_position + Vector3(sin(yaw) * dist, h, cos(yaw) * dist)
	camera.look_at(v.global_position + Vector3(0, 1.2, 0))
	camera.fov = 65

# ============================================================
# Building interaction
# ============================================================
var nearby_building_id = ""
var nearby_building_node = null

func _check_nearby():
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

# ============================================================
# Vehicle enter/exit
# ============================================================
func _try_vehicle_enter_exit():
	if in_vehicle:
		# Exit
		var v = in_vehicle
		v.exit()
		in_vehicle = null
		# Place player beside vehicle
		var exit_offset = Vector3(cos(v.yaw) * -1.8, 0, -sin(v.yaw) * -1.8)
		global_position = v.global_position + exit_offset
		visible = camera_mode == "third"
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		# Try to enter nearest vehicle
		for vehicle in get_tree().get_nodes_in_group("vehicle"):
			if vehicle.is_driven:
				continue
			var dist = global_position.distance_to(vehicle.global_position)
			if dist < 5.0:
				in_vehicle = vehicle
				vehicle.enter()
				yaw = vehicle.yaw
				visible = false
				GameManager.log_message.emit("Entered vehicle. WASD to drive, Space to brake, F to exit.", "info")
				return
