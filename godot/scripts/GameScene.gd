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
	add_to_group("game_scene")
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
		vehicle.position = Vector3(vdata.x, WorldBuilder.terrain_height(vdata.x, vdata.z), vdata.z)
		
		# Collision
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		# Vehicle collision: CapsuleShape oriented along Z (car length axis)
		# CapsuleShape3D is oriented along Y by default. We rotate it 90° on X
		# so it lies along Z (matching car length). Now it's long enough to
		# cover the full car body, with rounded front/back edges.
		# radius=0.8 (car half-height), height=2.9 (cylinder part = car length - 2*radius)
		# Total length = 2.9 + 2*0.8 = 4.5m (matches car body length)
		# Total height = 2*0.8 = 1.6m (matches car body height ~1.4m)
		var capsule = CapsuleShape3D.new()
		capsule.radius = 0.8
		capsule.height = 2.9  # cylinder part (total = 2.9 + 1.6 = 4.5m along Z)
		col.shape = capsule
		col.position = Vector3(0, 0.8, 0)  # center at y=0.8
		col.rotation.x = PI / 2  # rotate capsule from Y-axis to Z-axis (lie flat)
		vehicle.add_child(col)
		
		# Mesh container
		var mesh_node = Node3D.new()
		mesh_node.name = "CarMesh"
		vehicle.add_child(mesh_node)
		
		add_child(vehicle)

func _spawn_npcs():
	# Merchants near scheme buildings (positions match new D.4 v2 layout)
	var merchant_positions = [
		# NYC Downtown merchants (center)
		{"x": 30, "z": -80, "color": "#16a34a", "district": "nyc"},
		{"x": 130, "z": 30, "color": "#16a34a", "district": "nyc"},
		{"x": -80, "z": 80, "color": "#16a34a", "district": "nyc"},
		{"x": 180, "z": -80, "color": "#16a34a", "district": "nyc"},
		# Slums merchants (W/NW)
		{"x": -380, "z": 180, "color": "#b91c1c", "district": "slums_suburbs"},
		{"x": -480, "z": 280, "color": "#b91c1c", "district": "slums_suburbs"},
		{"x": -330, "z": 330, "color": "#b91c1c", "district": "slums_suburbs"},
		# NYC merchant (e-com warehouse)
		{"x": -30, "z": 180, "color": "#d97706", "district": "nyc"},
		# Harbor merchant (SE)
		{"x": 400, "z": 300, "color": "#7e22ce", "district": "harbor"},
	]
	for mp in merchant_positions:
		_spawn_npc(mp.x, mp.z, mp.color, mp.district, true)
	
	# Pedestrians — distributed per district (3x more NPCs for livelier city)
	var ped_configs = [
		{"district": "nyc", "count": 35, "colors": ["#1e293b", "#0f172a", "#374151", "#4b5563"]},
		{"district": "harbor", "count": 15, "colors": ["#1c1917", "#292524", "#44403c"]},
		{"district": "slums_suburbs", "count": 30, "colors": ["#7c2d12", "#9a3412", "#451a03", "#1c1917"]},
		{"district": "portofino", "count": 15, "colors": ["#d4a574", "#e8c89a", "#c97b50"]},
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
	npc.position = Vector3(x, WorldBuilder.terrain_height(x, z), z)
	
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
	match d:
		"portofino": return [-50, 800, -800, 100]
		"nyc": return [-200, 300, -300, 400]
		"harbor": return [100, 800, 100, 800]
		"slums_suburbs": return [-800, -100, -800, 800]
		_: return [-200, 300, -300, 400]

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
