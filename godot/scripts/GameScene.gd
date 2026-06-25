# GameScene.gd — Main game scene: builds world, spawns vehicles/NPCs, day/night, weather
extends Node3D

@onready var directional_light: DirectionalLight3D = $DirectionalLight3D
@onready var world_env: WorldEnvironment = $WorldEnvironment

var elapsed_time: float = 0.0
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
		vehicle.car_color = vdata.color
		vehicle.yaw = vdata.yaw
		vehicle.position = Vector3(vdata.x, 0, vdata.z)
		
		# Collision
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(2, 1.5, 4.4)
		col.shape = shape
		col.position = Vector3(0, 0.75, 0)
		vehicle.add_child(col)
		
		# Mesh container
		var mesh_node = Node3D.new()
		mesh_node.name = "CarMesh"
		vehicle.add_child(mesh_node)
		
		add_child(vehicle)

func _spawn_npcs():
	# Merchants near scheme buildings
	var merchant_positions = [
		{"x": -8, "z": -38, "color": "#16a34a", "district": "downtown"},
		{"x": -33, "z": -18, "color": "#16a34a", "district": "downtown"},
		{"x": -18, "z": -10, "color": "#16a34a", "district": "downtown"},
		{"x": 25, "z": -35, "color": "#7e22ce", "district": "harbor"},
		{"x": -25, "z": 20, "color": "#b91c1c", "district": "slums"},
		{"x": -14, "z": 35, "color": "#b91c1c", "district": "slums"},
		{"x": 18, "z": 25, "color": "#d97706", "district": "industrial"},
		{"x": 38, "z": 15, "color": "#d97706", "district": "industrial"},
	]
	for mp in merchant_positions:
		_spawn_npc(mp.x, mp.z, mp.color, mp.district, true)
	
	# Pedestrians
	var ped_configs = [
		{"district": "downtown", "count": 8, "colors": ["#1e293b", "#0f172a", "#374151", "#4b5563"]},
		{"district": "harbor", "count": 3, "colors": ["#1c1917", "#292524", "#44403c"]},
		{"district": "slums", "count": 10, "colors": ["#7c2d12", "#9a3412", "#451a03", "#1c1917"]},
		{"district": "industrial", "count": 5, "colors": ["#3f3f46", "#525252", "#27272a"]},
		{"district": "suburbs", "count": 4, "colors": ["#525252", "#737373", "#404040"]},
		{"district": "rural", "count": 2, "colors": ["#6b5b4a", "#7a6a5a"]},
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
	npc.position = Vector3(x, 0, z)
	
	var col = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.5
	col.shape = shape
	col.position = Vector3(0, 0.75, 0)
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
		"downtown": return [-80, 0, -80, 0]
		"harbor": return [0, 80, -80, 0]
		"slums": return [-80, 0, 0, 80]
		"industrial": return [0, 80, 0, 80]
		"suburbs": return [-150, 150, -150, 150]
		_: return [-220, 220, -220, 220]

func _process(delta):
	elapsed_time += delta
	
	# Day/night cycle
	var t = fmod(elapsed_time / CYCLE_SECONDS, 1.0)
	var sun_angle = (t - 0.25) * TAU
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
