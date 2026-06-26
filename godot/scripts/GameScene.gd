# GameScene.gd — Main game scene: builds world, spawns vehicles/NPCs, day/night, weather
extends Node3D

@onready var directional_light: DirectionalLight3D = $DirectionalLight3D
@onready var world_env: WorldEnvironment = $WorldEnvironment

var elapsed_time: float = 360.0  # Start at noon (t=0.5)
const CYCLE_SECONDS: float = 720.0  # 12 min = 24h

var building_panel: Control
var event_modal: Control
var nearby_building_id: String = ""
var nearby_building_node: Node3D = null

func _ready():
	# Environment
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.05, 0.1, 1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.3, 0.4, 1)
	env.ambient_light_energy = 0.4
	env.fog_enabled = true
	env.fog_light_color = Color(0.04, 0.05, 0.1, 1)
	env.fog_density = 0.003
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	world_env.environment = env
	
	# Build the world (terrain, roads, buildings, borders, lamps)
	WorldBuilder.build_world(self)
	
	# Spawn vehicles
	_spawn_vehicles()
	
	# Spawn NPCs
	_spawn_npcs()
	
	# Add weather
	var weather = preload("res://scripts/Weather.gd").new()
	add_child(weather)
	
	# Create UI overlays
	_create_ui()
	
	# Connect signals
	GameManager.phase_changed.connect(_on_phase_changed)

func _create_ui():
	building_panel = preload("res://scripts/BuildingActionPanel.gd").new()
	building_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(building_panel)
	
	event_modal = preload("res://scripts/EventModal.gd").new()
	event_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(event_modal)

func _spawn_vehicles():
	for vdata in VehicleData.get_positions():
		var vehicle = CharacterBody3D.new()
		vehicle.script = preload("res://scripts/Vehicle.gd")
		vehicle.car_model = vdata.get("model", "NormalCar1")
		vehicle.yaw = vdata.yaw
		vehicle.position = Vector3(vdata.x, 0, vdata.z)
		
		# Collision
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		# Collision box with GROUND CLEARANCE (like real car chassis)
		# Box bottom at y=0.2 (20cm clearance above road) — car can drive
		# over sidewalks (15cm) and small obstacles without getting stuck.
		# Wheels (visual) reach down to y=0 to show ground contact.
		shape.size = Vector3(1.9, 1.2, 4.3)
		col.shape = shape
		col.position = Vector3(0, 0.8, 0)  # center at y=0.8, bottom at y=0.2
		vehicle.add_child(col)
		
		# Mesh container
		var mesh_node = Node3D.new()
		mesh_node.name = "CarMesh"
		vehicle.add_child(mesh_node)
		
		add_child(vehicle)

func _spawn_npcs():
	# Merchants near scheme buildings (positions match new D.4 v2 layout)
	var merchant_positions = [
		# Downtown merchants (financial district)
		{"x": -90, "z": -45, "color": "#16a34a", "district": "downtown"},
		{"x": 110, "z": -75, "color": "#16a34a", "district": "downtown"},
		{"x": -140, "z": 55, "color": "#16a34a", "district": "downtown"},
		{"x": 130, "z": 95, "color": "#16a34a", "district": "downtown"},
		# Slums merchants (drugs/scam/robbery)
		{"x": -290, "z": 275, "color": "#b91c1c", "district": "slums"},
		{"x": -240, "z": 325, "color": "#b91c1c", "district": "slums"},
		{"x": -320, "z": 345, "color": "#b91c1c", "district": "slums"},
		# Industrial merchant (e-com)
		{"x": -270, "z": -245, "color": "#d97706", "district": "industrial"},
		# Harbor merchant
		{"x": 230, "z": 0, "color": "#7e22ce", "district": "harbor"},
	]
	for mp in merchant_positions:
		_spawn_npc(mp.x, mp.z, mp.color, mp.district, true)
	
	# Pedestrians — distributed per district (3x more NPCs for livelier city)
	var ped_configs = [
		{"district": "downtown", "count": 35, "colors": ["#1e293b", "#0f172a", "#374151", "#4b5563"]},
		{"district": "harbor", "count": 15, "colors": ["#1c1917", "#292524", "#44403c"]},
		{"district": "slums", "count": 30, "colors": ["#7c2d12", "#9a3412", "#451a03", "#1c1917"]},
		{"district": "industrial", "count": 18, "colors": ["#3f3f46", "#525252", "#27272a"]},
		{"district": "suburbs", "count": 15, "colors": ["#525252", "#737373", "#404040"]},
		{"district": "rural", "count": 8, "colors": ["#6b5b4a", "#7a6a5a"]},
	]
	for config in ped_configs:
		for i in config.count:
			var color = config.colors[i % config.colors.size()]
			_spawn_npc_in_district(config.district, color)

func _spawn_npc(x: float, z: float, color: String, district: String, is_merchant: bool):
	var npc = CharacterBody3D.new()
	npc.script = preload("res://scripts/NPC.gd")
	npc.npc_color = color
	npc.district = district
	npc.is_merchant = is_merchant
	# NPCs on collision layer 3, mask only layer 1 (ground/walls) - NOT layer 2 (player/vehicle)
	# This lets vehicles drive through NPCs (handled in NPC.gd via distance check)
	npc.collision_layer = 4  # layer 3
	npc.collision_mask = 1  # only collide with ground layer
	npc.position = Vector3(x, 0, z)
	
	var col = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.35  # 35cm radius — realistic human shoulder width
	shape.height = 1.7  # 1.7m tall capsule (covers head to feet)
	col.shape = shape
	col.position = Vector3(0, 0.85, 0)  # center at 0.85m
	npc.add_child(col)
	
	var mesh_node = Node3D.new()
	mesh_node.name = "NPCMesh"
	npc.add_child(mesh_node)
	
	add_child(npc)

func _spawn_npc_in_district(district: String, color: String):
	var bounds = _get_district_bounds(district)
	for i in 30:
		var x = bounds[0] + randf() * (bounds[1] - bounds[0])
		var z = bounds[2] + randf() * (bounds[3] - bounds[2])
		_spawn_npc(x, z, color, district, false)
		return

func _get_district_bounds(d: String) -> Array:
	# Bounds match D.4 v2 island layout (x_min, x_max, z_min, z_max)
	match d:
		"downtown": return [-200, 200, -150, 200]
		"harbor": return [200, 400, -300, 300]
		"slums": return [-400, -150, 200, 400]
		"industrial": return [-400, -150, -400, -100]
		"suburbs": return [-400, -150, -100, 200]
		_: return [-380, 380, -380, 380]  # rural + water

func _process(delta):
	elapsed_time += delta
	
	# Day/night cycle
	var t = fmod(elapsed_time / CYCLE_SECONDS, 1.0)
	# Godot 4: rotation.x=0 is noon (light pointing down),
	# rotation.x=PI is midnight (light pointing up).
	# t=0 -> midnight, t=0.5 -> noon
	var sun_angle = PI - t * TAU
	directional_light.rotation.x = sun_angle
	
	var phase = _get_day_phase(t)
	match phase:
		"night":
			directional_light.light_energy = 0.05
			directional_light.light_color = Color(0.3, 0.4, 0.9)
		"dawn":
			directional_light.light_energy = 0.4
			directional_light.light_color = Color(0.98, 0.57, 0.23)
		"day":
			directional_light.light_energy = 1.2
			directional_light.light_color = Color(1, 0.97, 0.91)
		"dusk":
			directional_light.light_energy = 0.4
			directional_light.light_color = Color(0.86, 0.15, 0.08)
	
	# Check for pending events
	if not GameManager.pending_event.is_empty() and not event_modal.visible:
		event_modal.show_event(GameManager.pending_event)
	
	# Check nearby building
	_check_nearby_building()
	
	# Check vehicle enter/exit
	_check_vehicle_interaction()

func _get_day_phase(t: float) -> String:
	if t < 0.08 or t >= 0.92:
		return "night"
	if t < 0.20:
		return "dawn"
	if t < 0.70:
		return "day"
	if t < 0.83:
		return "dusk"
	return "night"

func _check_nearby_building():
	if GameManager.phase != "playing":
		return
	if building_panel.visible:
		return
	
	var player = get_node_or_null("Player")
	if not player:
		return
	
	var nearest_id = ""
	var nearest_node = null
	var nearest_dist = 999.0
	
	for building in get_tree().get_nodes_in_group("scheme_building"):
		var dist = player.global_position.distance_to(building.global_position)
		if dist < 8.0 and dist < nearest_dist:
			nearest_dist = dist
			nearest_id = building.get_meta("scheme_id", "")
			nearest_node = building
	
	if nearest_id != nearby_building_id:
		nearby_building_id = nearest_id
		nearby_building_node = nearest_node
		if nearest_id != "":
			GameManager.log_message.emit("Press E to enter %s" % nearest_node.get_meta("scheme_name", ""), "info")

func _check_vehicle_interaction():
	if GameManager.phase != "playing":
		return
	if building_panel.visible:
		return
	
	var player = get_node_or_null("Player")
	if not player:
		return
	
	# Check F key for vehicle enter/exit
	# This is handled in PlayerController but we check for nearby vehicle prompt
	if player.in_vehicle != null:
		# Player is in vehicle — exit handled by PlayerController
		return
	
	# Check if near any vehicle for prompt
	for vehicle in get_tree().get_nodes_in_group("vehicle"):
		if vehicle.is_driven:
			continue
		var dist = player.global_position.distance_to(vehicle.global_position)
		if dist < 4.0:
			# Could show "Press F" prompt here
			pass

func _on_phase_changed(new_phase):
	if new_phase == "menu":
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	elif new_phase == "won" or new_phase == "lost":
		get_tree().change_scene_to_file("res://scenes/EndScreen.tscn")

func on_player_interact(scheme_id):
	if building_panel and not building_panel.visible:
		building_panel.show_panel(scheme_id)
