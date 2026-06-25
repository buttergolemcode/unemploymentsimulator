# Vehicle.gd — A drivable car
extends CharacterBody3D

var car_color: String = "#dc2626"
var yaw: float = 0.0
var speed: float = 0.0
var max_speed: float = 22.0
var max_reverse: float = 8.0
var accel: float = 8.0
var brake_force: float = 14.0
var friction: float = 3.0
var turn_rate: float = 1.8
var is_driven: bool = false

@onready var mesh: Node3D = $CarMesh

func _ready():
	add_to_group("vehicle")
	# Floor detection for gravity
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	floor_snap_length = 0.3
	_build_mesh()
	rotation.y = yaw + PI

func _build_mesh():
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.from_string(car_color, Color.GRAY)
	mat.roughness = 0.4
	mat.metalness = 0.5
	
	# Body
	var body = MeshInstance3D.new()
	var body_m = BoxMesh.new()
	body_m.size = Vector3(2, 0.7, 4.4)
	body.mesh = body_m
	body.position = Vector3(0, 0.6, 0)
	body.material_override = mat
	mesh.add_child(body)
	
	# Cabin
	var cabin = MeshInstance3D.new()
	var cabin_m = BoxMesh.new()
	cabin_m.size = Vector3(1.7, 0.6, 2.0)
	cabin.mesh = cabin_m
	cabin.position = Vector3(0, 1.25, -0.2)
	cabin.material_override = mat
	mesh.add_child(cabin)
	
	# Windshield
	var wind = MeshInstance3D.new()
	var wind_m = BoxMesh.new()
	wind_m.size = Vector3(1.6, 0.5, 0.1)
	wind.mesh = wind_m
	wind.position = Vector3(0, 1.25, 0.85)
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.06, 0.09, 0.16, 0.8)
	glass_mat.roughness = 0.1
	glass_mat.metalness = 0.9
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wind.material_override = glass_mat
	mesh.add_child(wind)
	
	# Wheels
	for pos in [Vector3(-0.9, 0.35, 1.5), Vector3(0.9, 0.35, 1.5), Vector3(-0.9, 0.35, -1.5), Vector3(0.9, 0.35, -1.5)]:
		var wheel = MeshInstance3D.new()
		var w_m = CylinderMesh.new()
		w_m.top_radius = 0.35
		w_m.bottom_radius = 0.35
		w_m.height = 0.25
		wheel.mesh = w_m
		wheel.rotation.z = PI / 2
		wheel.position = pos
		var wmat = StandardMaterial3D.new()
		wmat.albedo_color = Color(0.1, 0.1, 0.1)
		wmat.roughness = 0.9
		wheel.material_override = wmat
		mesh.add_child(wheel)
	
	# Headlights
	for x in [-0.6, 0.6]:
		var hl = OmniLight3D.new()
		hl.position = Vector3(x, 0.6, 2.2)
		hl.light_color = Color(1, 0.95, 0.8)
		hl.light_energy = 1.5
		hl.omni_range = 8.0
		mesh.add_child(hl)
	
	# Taillights
	for x in [-0.6, 0.6]:
		var tl = OmniLight3D.new()
		tl.position = Vector3(x, 0.6, -2.2)
		tl.light_color = Color(1, 0.2, 0.1)
		tl.light_energy = 0.8
		tl.omni_range = 4.0
		mesh.add_child(tl)

func _physics_process(delta):
	if not is_driven:
		speed = move_toward(speed, 0, friction * delta)
		return
	
	var throttle = 0.0
	var steer = 0.0
	var brake_input = false
	
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		throttle += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		throttle -= 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		steer -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		steer += 1.0
	if Input.is_key_pressed(KEY_SPACE):
		brake_input = true
	
	if throttle > 0:
		speed += accel * throttle * delta
		speed = min(speed, max_speed)
	elif throttle < 0:
		speed += -accel * abs(throttle) * delta * 0.6
		speed = max(speed, -max_reverse)
	else:
		if speed > 0:
			speed = max(0, speed - friction * delta)
		elif speed < 0:
			speed = min(0, speed + friction * delta)
	
	if brake_input:
		var decel = brake_force * delta
		if speed > 0:
			speed = max(0, speed - decel)
		elif speed < 0:
			speed = min(0, speed + decel)
	
	var speed_factor = min(1, abs(speed) / 5)
	var turn = steer * turn_rate * speed_factor * delta
	if speed < 0:
		yaw += turn
	else:
		yaw -= turn
	
	rotation.y = yaw + PI
	
	velocity.x = -sin(yaw) * speed
	velocity.z = -cos(yaw) * speed
	# Apply gravity so the car stays on the ground
	if not is_on_floor():
		velocity.y -= 14.0 * delta  # heavier gravity for cars
	else:
		velocity.y = 0
	
	move_and_slide()
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = global_position
		player.yaw = yaw

func enter():
	is_driven = true
	visible = true

func exit():
	is_driven = false
