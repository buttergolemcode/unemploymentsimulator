# GameScene.gd — Main game scene controller
# Spawns buildings, manages day/night, handles building interaction + events
extends Node3D

@onready var directional_light: DirectionalLight3D = $DirectionalLight3D
@onready var world_env: WorldEnvironment = $WorldEnvironment

var elapsed_time: float = 0.0
const CYCLE_SECONDS: float = 720.0  # 12 min = 24h

# Building positions (matching the web version layout)
const BUILDING_POSITIONS: Array = [
	{"id": "trading", "name": "Trading Floor", "emoji": "📈", "x": -18, "z": -55, "w": 14, "d": 12, "h": 42, "color": "#22d3ee"},
	{"id": "wirefraud", "name": "Corporate Tower", "emoji": "💸", "x": -50, "z": -30, "w": 18, "d": 16, "h": 80, "color": "#64748b"},
	{"id": "taxfraud", "name": "Accountant Office", "emoji": "🧾", "x": -30, "z": -18, "w": 12, "d": 10, "h": 24, "color": "#eab308"},
	{"id": "drugs", "name": "Trap House", "emoji": "💊", "x": 38, "z": -50, "w": 10, "d": 9, "h": 9, "color": "#a855f7"},
	{"id": "scam", "name": "Internet Cafe", "emoji": "🎣", "x": -38, "z": 30, "w": 9, "d": 8, "h": 7, "color": "#ec4899"},
	{"id": "robbery", "name": "Corner Store", "emoji": "🔫", "x": -22, "z": 50, "w": 8, "d": 8, "h": 5, "color": "#ef4444"},
	{"id": "ecom", "name": "E-Com Warehouse", "emoji": "📦", "x": 30, "z": 38, "w": 16, "d": 14, "h": 11, "color": "#4ade80"},
	{"id": "gambling", "name": "Casino", "emoji": "🎰", "x": 55, "z": 22, "w": 16, "d": 14, "h": 14, "color": "#f59e0b"},
]

var building_panel: Control
var event_modal: Control
var nearby_building_id: String = ""
var nearby_building_node: Node3D = null

func _ready() -> void:
	# Setup environment
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
	
	# Spawn scheme buildings
	_spawn_buildings()
	
	# Spawn street lamps
	_spawn_street_lamps()
	
	# Create UI overlays
	_create_ui()
	
	# Connect GameManager signals
	GameManager.phase_changed.connect(_on_phase_changed)

func _create_ui() -> void:
	# Building action panel
	building_panel = preload("res://scripts/BuildingActionPanel.gd").new()
	building_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(building_panel)
	
	# Event modal
	event_modal = preload("res://scripts/EventModal.gd").new()
	event_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(event_modal)

func _spawn_buildings() -> void:
	for b in BUILDING_POSITIONS:
		# Building mesh
		var mesh = CSGBox3D.new()
		mesh.size = Vector3(b.w, b.h, b.d)
		mesh.position = Vector3(b.x, b.h / 2.0, b.z)
		mesh.material = _make_building_material(b.color)
		mesh.add_to_group("scheme_building")
		mesh.set_meta("scheme_id", b.id)
		mesh.set_meta("scheme_name", b.name)
		mesh.set_meta("scheme_emoji", b.emoji)
		add_child(mesh)
		
		# Collision body
		var body = StaticBody3D.new()
		body.position = Vector3(b.x, b.h / 2.0, b.z)
		body.collision_layer = 1
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(b.w, b.h, b.d)
		col.shape = shape
		body.add_child(col)
		add_child(body)
		
		# Floating emoji label (using Label3D)
		var label = Label3D.new()
		label.text = "%s %s" % [b.emoji, b.name]
		label.position = Vector3(b.x, b.h + 2, b.z)
		label.font_size = 48
		label.outline_size = 6
		label.outline_modulate = Color.BLACK
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		add_child(label)

func _spawn_street_lamps() -> void:
	var lamp_positions = [
		Vector3(-6, 0, -4), Vector3(6, 0, -4), Vector3(-6, 0, 6), Vector3(6, 0, 6),
		Vector3(-20, 0, -20), Vector3(20, 0, -20), Vector3(-20, 0, 20), Vector3(20, 0, 20),
	]
	for pos in lamp_positions:
		var pole = CSGCylinder3D.new()
		pole.radius = 0.08
		pole.height = 4.0
		pole.position = pos + Vector3(0, 2, 0)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.1, 0.1, 0.1)
		pole.material = mat
		add_child(pole)
		
		var light = OmniLight3D.new()
		light.position = pos + Vector3(0, 4, 0)
		light.light_color = Color(1, 0.95, 0.8)
		light.light_energy = 2.0
		light.omni_range = 12.0
		add_child(light)

func _make_building_material(color_str: String) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.from_string(color_str, Color.GRAY)
	mat.roughness = 0.6
	mat.metalness = 0.1
	return mat

func _process(delta: float) -> void:
	elapsed_time += delta
	
	# Day/night cycle
	var t = fmod(elapsed_time / CYCLE_SECONDS, 1.0)
	var sun_angle = (t - 0.25) * TAU
	directional_light.rotation.x = sun_angle
	
	# Sun intensity + color by phase
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
	
	# Check for nearby building (interaction prompt)
	_check_nearby_building()

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

func _check_nearby_building() -> void:
	if GameManager.phase != "playing":
		return
	if building_panel.visible:
		return  # Don't update while panel is open
	
	var player = get_node_or_null("Player")
	if not player:
		return
	
	var nearest_id = ""
	var nearest_node: Node3D = null
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

func _on_phase_changed(new_phase: String) -> void:
	if new_phase == "menu":
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	elif new_phase == "won" or new_phase == "lost":
		get_tree().change_scene_to_file("res://scenes/EndScreen.tscn")

# Called by PlayerController when E is pressed
func on_player_interact(scheme_id: String) -> void:
	if building_panel and not building_panel.visible:
		building_panel.show_panel(scheme_id)
