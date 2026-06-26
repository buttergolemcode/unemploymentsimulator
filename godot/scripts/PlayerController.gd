# PlayerController.gd — First-person player + vehicle enter/exit
extends CharacterBody3D

const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const MOUSE_SENS = 0.0022
const PITCH_LIMIT = 1.5

var yaw: float = 0.0
var camera_yaw: float = 0.0  # independent camera orbit yaw (mouse-controlled, used in vehicle)
var pitch: float = 0.0
var camera_mode: String = "first"
var in_vehicle: Node = null

@onready var camera: Camera3D = $Camera3D

func _ready():
        add_to_group("player")
        camera.top_level = true  # detach camera from player transform
        # Explicit floor detection settings (prevents flying bug)
        motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
        floor_snap_length = 0.3
        floor_max_angle = deg_to_rad(50)
        _build_mesh()
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
        if GameManager.phase != "playing":
                return
        
        if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
                if in_vehicle:
                        # In vehicle: mouse controls camera_yaw (independent orbit), not car yaw
                        camera_yaw -= event.relative.x * MOUSE_SENS
                else:
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
        # Camera is top_level so set full rotation explicitly
        
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
                camera.global_position = global_position + Vector3(0, 1.6, 0)
                camera.rotation = Vector3(pitch, yaw, 0)
                camera.fov = 70
        else:
                var dist = 4.5
                var h = 1.6
                camera.global_position = global_position + Vector3(sin(yaw) * dist, h, cos(yaw) * dist)
                camera.look_at(global_position + Vector3(0, 1.0, 0))
                camera.fov = 60
        
        _check_nearby()

func _update_vehicle_camera():
        var v = in_vehicle
        if not v:
                return
        var dist = 7.0
        var h = 2.5
        # Use camera_yaw (mouse-controlled) instead of yaw (synced to car)
        # This lets the player look around the car independently of driving direction
        camera.global_position = v.global_position + Vector3(sin(camera_yaw) * dist, h, cos(camera_yaw) * dist)
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
                # Place player BEHIND the vehicle (opposite of movement direction)
                # Movement direction is (-sin(yaw), 0, -cos(yaw)), so behind is +(sin(yaw), cos(yaw))
                var exit_offset = Vector3(sin(v.yaw) * 2.5, 0, cos(v.yaw) * 2.5)
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
                                camera_yaw = vehicle.yaw  # init camera_yaw to car heading (no jump)
                                velocity = Vector3.ZERO  # reset velocity to prevent flying after exit
                                visible = false
                                GameManager.log_message.emit("Entered vehicle. WASD to drive, Space to brake, F to exit.", "info")
                                return

# ============================================================
# Player visual model (visible only in third-person mode)
# ============================================================
func _build_mesh():
        var mesh_node = Node3D.new()
        mesh_node.name = "PlayerMesh"
        add_child(mesh_node)

        # Try loading a Quaternius character model (use "Suit" for player)
        var model_path = "res://assets/quaternius_modular_chars/FBX/Suit.fbx"
        var packed_scene = load(model_path)
        if packed_scene != null:
                var instance = packed_scene.instantiate()
                instance.scale = Vector3(1.0, 1.0, 1.0)
                instance.rotation.y = PI  # face -Z (forward)
                mesh_node.add_child(instance)
                return

        # Fallback: build simple capsule mesh
        push_warning("PlayerController: could not load Suit.fbx, falling back to capsule")
        _build_capsule_mesh(mesh_node)

func _build_capsule_mesh(mesh_node: Node3D):
        # Body (capsule)
        var body = MeshInstance3D.new()
        var body_m = CapsuleMesh.new()
        body_m.radius = 0.35
        body_m.height = 1.4
        body.mesh = body_m
        body.position = Vector3(0, 0.7, 0)
        var body_mat = StandardMaterial3D.new()
        body_mat.albedo_color = Color(0.12, 0.23, 0.54)  # dark blue
        body_mat.roughness = 0.7
        body.material_override = body_mat
        mesh_node.add_child(body)

        # Head (sphere)
        var head = MeshInstance3D.new()
        var head_m = SphereMesh.new()
        head_m.radius = 0.18
        head_m.height = 0.36
        head.mesh = head_m
        head.position = Vector3(0, 1.6, 0)
        var head_mat = StandardMaterial3D.new()
        head_mat.albedo_color = Color(0.96, 0.85, 0.7)  # warm skin tone
        head_mat.roughness = 0.6
        head.material_override = head_mat
        mesh_node.add_child(head)

        # Simple hat (cylinder) for visibility from behind
        var hat = MeshInstance3D.new()
        var hat_m = CylinderMesh.new()
        hat_m.top_radius = 0.2
        hat_m.bottom_radius = 0.2
        hat_m.height = 0.12
        hat.mesh = hat_m
        hat.position = Vector3(0, 1.78, 0)
        var hat_mat = StandardMaterial3D.new()
        hat_mat.albedo_color = Color(0.08, 0.08, 0.1)  # black beanie
        hat_mat.roughness = 0.85
        hat.material_override = hat_mat
        mesh_node.add_child(hat)
