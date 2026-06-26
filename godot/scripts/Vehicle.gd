# Vehicle.gd — A drivable car with semi-realistic physics
# Uses Quaternius Cars CC0 FBX models, falls back to box mesh if asset missing.
extends CharacterBody3D

var car_color: String = "#dc2626"
var car_model: String = ""  # e.g. "NormalCar1" — see VehicleData.CAR_MODELS
var yaw: float = 0.0
var speed: float = 0.0  # forward speed (signed: +forward / -reverse)
var max_speed: float = 18.0  # 18 m/s = ~65 km/h (city speed)
var max_reverse: float = 8.0
var accel: float = 10.0       # engine force when accelerating
var brake_force: float = 18.0  # deceleration when braking
var engine_brake: float = 4.0  # natural deceleration when no throttle
var turn_rate: float = 2.0     # max yaw rate at full steering (rad/s)
var min_turn_speed: float = 2.0  # below this speed, no turning (no tank spins)
var is_driven: bool = false

@onready var mesh: Node3D = $CarMesh

# Wheel nodes (found after model load) for wheel-spin animation
var _wheel_nodes: Array = []
# Front wheels (separate from rear) — these also turn left/right when steering
var _front_wheel_pivots: Array = []  # parent Node3Ds for steering Y-rotation
var _front_wheels_raw: Array = []  # raw wheel nodes before pivot wrapping
var _rear_wheels: Array = []
# Last steering input for body-roll animation
var _last_steer: float = 0.0
# True when using box-mesh fallback (FBX wheel animation is unreliable
# because the wheel nodes have baked orientations that conflict with our
# rotate_x / rotation.y assignments)
var _use_box_mesh: bool = false

func _ready():
	add_to_group("vehicle")
	# Floor detection — tuned for driving over sidewalks and small steps
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	floor_snap_length = 0.5  # snap to floor within 50cm (was 0.3) — handles sidewalk steps
	floor_max_angle = deg_to_rad(60)  # allow climbing slopes up to 60° (was default 45°)
	_build_mesh()
	rotation.y = yaw + PI

func _build_mesh():
	# Try loading the real FBX model first
	if car_model != "":
		var model_path = VehicleData.get_model_path(car_model)
		if model_path != "" and ResourceLoader.has_method("exists") and ResourceLoader.exists(model_path):
			_load_real_model(model_path)
			return
		elif model_path != "":
			# ResourceLoader.exists may not work for unimported FBX;
			# try load anyway — Godot will import on first editor open
			var loaded = load(model_path)
			if loaded != null:
				_instantiate_model(loaded)
				return
			push_warning("Vehicle: could not load model '%s', falling back to box mesh" % car_model)
	# Fallback: build simple box mesh
	_build_box_mesh()

func _load_real_model(model_path: String):
	var packed_scene = load(model_path)
	if packed_scene == null:
		_build_box_mesh()
		return
	_instantiate_model(packed_scene)

func _instantiate_model(packed_scene):
	var instance = packed_scene.instantiate()
	# Quaternius cars are roughly 4m long, 2m wide — scale to match our collision box (2 x 1.5 x 4.4)
	# Tune this if models look wrong-sized in game
	instance.scale = Vector3(1.0, 1.0, 1.0)
	mesh.add_child(instance)
	# Try to find wheel nodes for spin animation
	_find_wheels(instance)
	# Add headlights and taillights (lights are not in the model, add as before)
	_add_lights()

func _find_wheels(root):
	# Quaternius cars name wheel nodes like "NormalCar1_FrontLeftWheel",
	# "NormalCar1_FrontRightWheel", "NormalCar1_BackWheels".
	_wheel_nodes.clear()
	_front_wheel_pivots.clear()
	_front_wheels_raw.clear()
	_rear_wheels.clear()
	_collect_wheels(root)
	# NOTE: FBX wheel pivot wrapping DISABLED — was causing wheels to swing
	# in an arc when steering (FBX mesh offset != wheel node origin).
	# Steering animation only works for box-mesh fallback (pivots created
	# in _build_box_mesh). FBX models: wheels don't turn visually when steering.
	# Will be fixed properly in Sprint D.5 (Animations) with real rigging.

func _collect_wheels(node):
	var name_lower = node.name.to_lower()
	if "wheel" in name_lower:
		_wheel_nodes.append(node)
		# Identify front wheels by 'f' or 'front' in name, plus 'l'/'r' for side
		# Quaternius convention: Wheel_FL, Wheel_FR, Wheel_RL, Wheel_RR
		if "front" in name_lower or "_fl" in name_lower or "_fr" in name_lower:
			_front_wheels_raw.append(node)
		elif "back" in name_lower or "rear" in name_lower or "_rl" in name_lower or "_rr" in name_lower:
			_rear_wheels.append(node)
	for child in node.get_children():
		_collect_wheels(child)

func _add_lights():
	# Headlights
	for x in [-0.75, 0.75]:
		var hl = OmniLight3D.new()
		hl.position = Vector3(x, 0.85, 2.25)  # at front of body
		hl.light_color = Color(1, 0.95, 0.8)
		hl.light_energy = 1.5
		hl.omni_range = 8.0
		mesh.add_child(hl)
	# Taillights
	for x in [-0.75, 0.75]:
		var tl = OmniLight3D.new()
		tl.position = Vector3(x, 0.85, -2.25)  # at rear of body
		tl.light_color = Color(1, 0.2, 0.1)
		tl.light_energy = 0.8
		tl.omni_range = 4.0
		mesh.add_child(tl)

# === Box mesh fallback (used if FBX model can't be loaded) ===
func _build_box_mesh():
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.from_string(car_color, Color.GRAY)
	mat.roughness = 0.4
	mat.metalness = 0.5

	# Body
	var body = MeshInstance3D.new()
	var body_m = BoxMesh.new()
	body_m.size = Vector3(2.0, 1.2, 4.5)  # 2m wide, 1.2m body, 4.5m long (slightly larger)
	body.mesh = body_m
	body.position = Vector3(0, 0.8, 0)  # body center at 0.8m (above wheels at 0.4+0.4=0.8)
	body.material_override = mat
	mesh.add_child(body)

	# Cabin
	var cabin = MeshInstance3D.new()
	var cabin_m = BoxMesh.new()
	cabin_m.size = Vector3(1.7, 0.8, 2.0)  # cabin: 1.7m wide, 0.8m tall, 2.0m long
	cabin.mesh = cabin_m
	cabin.position = Vector3(0, 1.7, -0.2)  # on top of body (body top at 1.4)
	cabin.material_override = mat
	mesh.add_child(cabin)

	# Windshield
	var wind = MeshInstance3D.new()
	var wind_m = BoxMesh.new()
	wind_m.size = Vector3(1.6, 0.7, 0.1)
	wind.mesh = wind_m
	wind.position = Vector3(0, 1.7, 0.95)  # at cabin height
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.06, 0.09, 0.16, 0.8)
	glass_mat.roughness = 0.1
	glass_mat.metalness = 0.9
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wind.material_override = glass_mat
	mesh.add_child(wind)

	# Wheels (also tracked for wheel-spin)
	_wheel_nodes.clear()
	# Wheel y-position: radius=0.4, center at y=0.4 -> bottom at y=0.0 (ground contact)
	# When car drives onto sidewalk, floor_snap raises entire car (including wheels)
	for pos in [Vector3(-0.95, 0.4, 1.5), Vector3(0.95, 0.4, 1.5), Vector3(-0.95, 0.4, -1.5), Vector3(0.95, 0.4, -1.5)]:
		var wheel = MeshInstance3D.new()
		var w_m = CylinderMesh.new()
		w_m.top_radius = 0.4  # 40cm radius = 80cm diameter (realistic SUV)
		w_m.bottom_radius = 0.4
		w_m.height = 0.3  # 30cm tire width
		wheel.mesh = w_m
		wheel.rotation.z = PI / 2
		wheel.position = pos
		var wmat = StandardMaterial3D.new()
		wmat.albedo_color = Color(0.1, 0.1, 0.1)
		wmat.roughness = 0.9
		wheel.material_override = wmat
		mesh.add_child(wheel)
		_wheel_nodes.append(wheel)
	# In box-mesh fallback: order is [FL, FR, RL, RR] (z=+1.5 is front in local space
	# because CarMesh is rotated 180° via rotation.y = yaw + PI)
	# Wrap first two wheels (front) in pivots for steering animation
	for i in [0, 1]:
		var wheel_node = _wheel_nodes[i]
		var pivot = Node3D.new()
		pivot.name = "BoxSteerPivot_" + str(i)
		var parent_node = wheel_node.get_parent()
		var wp = wheel_node.position
		var wr = wheel_node.rotation
		parent_node.remove_child(wheel_node)
		pivot.position = wp
		parent_node.add_child(pivot)
		wheel_node.position = Vector3.ZERO
		wheel_node.rotation = wr
		pivot.add_child(wheel_node)
		_front_wheel_pivots.append(pivot)
	_rear_wheels = [_wheel_nodes[2], _wheel_nodes[3]]
	_use_box_mesh = true  # enable wheel spin animation

	_add_lights()

func _physics_process(delta):
	if not is_driven:
		# Apply engine brake when nobody is driving
		speed = move_toward(speed, 0, engine_brake * delta)
		_apply_gravity_and_move(delta)
		_animate_wheels_and_body(delta, 0.0)
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

	# === Engine model ===
	if throttle > 0:
		speed += accel * throttle * delta
		speed = min(speed, max_speed)
	elif throttle < 0:
		if speed > 0.5:
			speed = max(0, speed - brake_force * delta)
		else:
			speed += -accel * 0.6 * delta
			speed = max(speed, -max_reverse)
	else:
		if speed > 0:
			speed = max(0, speed - engine_brake * delta)
		elif speed < 0:
			speed = min(0, speed + engine_brake * delta)

	if brake_input:
		var decel = brake_force * delta
		if speed > 0:
			speed = max(0, speed - decel)
		elif speed < 0:
			speed = min(0, speed + decel)

	# === Steering model ===
	var abs_speed = abs(speed)
	if abs_speed > min_turn_speed:
		# Bell-curve steering authority (realistic):
		# - Ramps UP from 0 at standstill to peak at ~5 m/s (city cornering)
		# - Decreases at high speed for stability (no tank-spin at top speed)
		# At 2 m/s: factor=0.28, turn=0.56 rad/s (32 deg/s — slow parking)
		# At 5 m/s: factor=0.70, turn=1.40 rad/s (80 deg/s — tight corner)
		# At 10 m/s: factor=0.58, turn=1.16 rad/s (66 deg/s — avenue)
		# At 22 m/s: factor=0.30, turn=0.60 rad/s (34 deg/s — highway)
		var speed_factor: float
		if abs_speed < 5.0:
			speed_factor = (abs_speed / 5.0) * 0.70
		else:
			speed_factor = 0.70 - (abs_speed - 5.0) / 17.0 * 0.40
			speed_factor = clamp(speed_factor, 0.30, 0.70)
		var turn = steer * turn_rate * speed_factor * delta
		if speed < 0:  # reverse: steering inverts (like real car)
			yaw += turn
		else:
			yaw -= turn
	rotation.y = yaw + PI

	# === Velocity from yaw + speed ===
	velocity.x = -sin(yaw) * speed
	velocity.z = -cos(yaw) * speed

	_apply_gravity_and_move(delta)

	# === Collision response: lose speed on impact ===
	if get_slide_collision_count() > 0:
		var hit_normal = Vector3.ZERO
		for i in get_slide_collision_count():
			var c = get_slide_collision(i)
			hit_normal += c.get_normal()
		if hit_normal.length() > 0:
			hit_normal = hit_normal.normalized()
			var v_along_normal = velocity.dot(-hit_normal)
			if v_along_normal > 0.5:
				var impact_strength = clamp(v_along_normal / 8.0, 0.3, 0.95)
				speed *= (1.0 - impact_strength)
				velocity += hit_normal * 1.5

	# Wheel spin + body roll animation
	_animate_wheels_and_body(delta, steer)

	# Sync player to vehicle position
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = global_position
		player.yaw = yaw

	_last_steer = steer

func _animate_wheels_and_body(delta: float, current_steer: float):
	var abs_speed = abs(speed)  # used by both front-wheel + body-roll sections
	# Wheel spin + steering: ONLY animate for box-mesh fallback.
	# For real FBX car models, the wheel nodes have baked orientations
	# (e.g. cylinders rotated for visual alignment). Adding rotate_x or
	# setting rotation.y breaks the orientation and the wheels glitch
	# into the car body. We skip animation until proper pivot-node setup
	# is implemented.
	# Front-wheel steering: turn front wheels left/right based on steer input.
	# This works for BOTH box-mesh fallback AND real FBX models because
	# wheel.rotation.y = X only overwrites the Y component, preserving the
	# wheel's baked X/Z orientation (e.g. cylinder rotated for visual alignment).
	var steer_visual_factor: float
	if abs_speed < 1.0:
		steer_visual_factor = 1.0
	elif abs_speed < 5.0:
		steer_visual_factor = 1.0
	else:
		steer_visual_factor = clamp(1.0 - (abs_speed - 5.0) / 17.0, 0.3, 1.0)
	# Negative sign: A=left (steer=-1) should turn wheels LEFT visually.
	# pivot.rotation.y = +X rotates counterclockwise when viewed from top,
	# so positive steer (right) needs negative rotation. Hence the minus sign.
	var target_steer_angle = -current_steer * 0.5 * steer_visual_factor
	for pivot in _front_wheel_pivots:
		pivot.rotation.y = lerp(pivot.rotation.y, target_steer_angle, delta * 8.0)
	
	# Wheel spin (X-axis rotation): ONLY for box-mesh fallback.
	# For real FBX models, rotate_x() would accumulate on top of baked
	# orientation and cause wheels to clip into the body.
	if _use_box_mesh:
		var spin_rate = speed * 3.0
		for wheel in _wheel_nodes:
			wheel.rotate_x(spin_rate * delta)

	# Body roll: lean into turns based on steer input and speed
	# More speed + more steer = more roll. Cap at small angle for subtlety.
	var target_roll = 0.0
	if abs_speed > 1.0:
		var speed_factor = clamp(abs_speed / max_speed, 0.0, 1.0)
		# Lean OUTSIDE of the turn (positive steer = right turn = body rolls left = negative Z rotation)
		target_roll = -current_steer * speed_factor * 0.08  # max ~4.5 degrees
	# Smoothly interpolate to target roll
	mesh.rotation.z = lerp(mesh.rotation.z, target_roll, delta * 5.0)
	# Subtle pitch on accel/brake (squat and dive)
	var target_pitch = 0.0
	if is_driven:
		var accel_input = 0.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			accel_input += 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			accel_input -= 1.0
		# Accelerating = nose up (positive pitch), braking/reverse = nose down
		target_pitch = -accel_input * 0.03  # max ~1.7 degrees
	mesh.rotation.x = lerp(mesh.rotation.x, target_pitch, delta * 4.0)

func _apply_gravity_and_move(delta):
	# Apply gravity so the car stays on the ground
	if not is_on_floor():
		velocity.y -= 14.0 * delta  # heavier gravity for cars
	else:
		velocity.y = 0
	move_and_slide()

func enter():
	is_driven = true
	visible = true

func exit():
	is_driven = false
