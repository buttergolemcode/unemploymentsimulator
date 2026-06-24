# PlayerController.gd — First-person player movement + interaction
extends CharacterBody3D

# ============================================================
# Constants
# ============================================================
const WALK_SPEED: float = 5.0
const SPRINT_SPEED: float = 8.0
const MOUSE_SENSITIVITY: float = 0.0022
const PITCH_LIMIT: float = 1.5  # ~85 degrees in radians

# ============================================================
# State
# ============================================================
var yaw: float = 0.0
var pitch: float = 0.0
var camera_mode: String = "first"  # first, third
var in_vehicle: Node = null

# ============================================================
# Nodes
# ============================================================
@onready var camera: Camera3D = $Camera3D
@onready var ray_cast: RayCast3D = $Camera3D/RayCast3D

# ============================================================
# Ready
# ============================================================
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_to_group("player")

# ============================================================
# Input
# ============================================================
func _unhandled_input(event: InputEvent) -> void:
	if GameManager.phase != "playing":
		return
	
	# Mouse look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * MOUSE_SENSITIVITY
		pitch -= event.relative.y * MOUSE_SENSITIVITY
		pitch = clamp(pitch, -PITCH_LIMIT, PITCH_LIMIT)
	
	# Toggle camera (V)
	if event.is_action_pressed("toggle_camera"):
		camera_mode = "third" if camera_mode == "first" else "first"
	
	# Interact (E)
	if event.is_action_pressed("interact"):
		_try_interact()
	
	# Release mouse on Escape
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# ============================================================
# Physics process
# ============================================================
func _physics_process(delta: float) -> void:
	if GameManager.phase != "playing":
		return
	
	if in_vehicle:
		# When in vehicle, hide player and let vehicle controller handle movement
		visible = false
		return
	
	visible = camera_mode == "third"
	
	# Apply rotation from yaw + pitch
	rotation.y = yaw
	camera.rotation.x = pitch
	
	# Movement input
	var input_dir: Vector2 = Vector2.ZERO
	input_dir.y = Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	
	# Transform input to world space (based on yaw)
	var forward = Vector3(-sin(yaw), 0, -cos(yaw))
	var right = Vector3(cos(yaw), 0, -sin(yaw))
	
	var wish_dir = (forward * input_dir.y + right * input_dir.x).normalized()
	
	# Speed (sprint with shift)
	var speed = SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else WALK_SPEED
	
	# Apply velocity
	velocity.x = wish_dir.x * speed
	velocity.z = wish_dir.z * speed
	
	# Gravity (always apply)
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0
	
	move_and_slide()
	
	# Update camera position
	_update_camera()
	
	# Check for nearby interactable
	_check_nearby_interactable()

# ============================================================
# Camera update
# ============================================================
func _update_camera() -> void:
	if camera_mode == "first":
		# Camera at eye height
		camera.position = Vector3(0, 1.6, 0)
		camera.fov = 70
	else:
		# Third person: behind and above
		var distance = 6.0
		var height = 4.0
		var offset = Vector3(sin(yaw) * distance, height, cos(yaw) * distance)
		camera.global_position = global_position + offset
		camera.look_at(global_position + Vector3(0, 1.2, 0))
		camera.fov = 60

# ============================================================
# Interaction
# ============================================================
var nearby_building: Dictionary = {}

func _check_nearby_interactable() -> void:
	# Check for nearby scheme buildings
	var buildings = get_tree().get_nodes_in_group("scheme_building")
	var nearest: Node3D = null
	var nearest_dist: float = 999.0
	
	for building in buildings:
		var dist = global_position.distance_to(building.global_position)
		if dist < GameManager.INTERACT_DISTANCE if GameManager.has_method("get") else 6.0:
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = building
	
	if nearest:
		var scheme_id = nearest.get_meta("scheme_id", "")
		if nearby_building.get("id", "") != scheme_id:
			nearby_building = {"id": scheme_id, "node": nearest}
			# Emit signal or update UI
			GameManager.log_message.emit("Press E to enter %s" % nearest.get_meta("scheme_name", ""), "info")
	elif nearby_building:
		nearby_building = {}
	
	# Check for nearby vehicles
	var vehicles = get_tree().get_nodes_in_group("vehicle")
	for vehicle in vehicles:
		var dist = global_position.distance_to(vehicle.global_position)
		if dist < 4.0:
			# Show "Press F to enter vehicle" prompt
			pass

func _try_interact() -> void:
	if nearby_building:
		var scheme_id = nearby_building.id
		# Emit signal to UI to show building panel
		GameManager.log_message.emit("Entering %s..." % nearby_building.node.get_meta("scheme_name", ""), "info")
		# The UI will handle showing the action panel
		get_tree().call_group("ui", "show_building_panel", scheme_id)

# ============================================================
# Vehicle enter/exit
# ============================================================
func enter_vehicle(vehicle: Node) -> void:
	in_vehicle = vehicle
	visible = false
	vehicle.enter()

func exit_vehicle() -> void:
	if in_vehicle:
		var vehicle = in_vehicle
		in_vehicle = null
		# Place player beside vehicle
		var exit_offset = Vector3(cos(vehicle.rotation.y) * -1.8, 0, -sin(vehicle.rotation.y) * -1.8)
		global_position = vehicle.global_position + exit_offset
		visible = camera_mode == "third"
		vehicle.exit()
