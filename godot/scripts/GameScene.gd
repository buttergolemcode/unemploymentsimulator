# GameScene.gd — Main game scene controller
# Spawns buildings, manages day/night, handles scene setup
extends Node3D

@onready var directional_light: DirectionalLight3D = $DirectionalLight3D
@onready var world_env: WorldEnvironment = $WorldEnvironment

var elapsed_time: float = 0.0
const CYCLE_SECONDS: float = 720.0  # 12 min = 24h

func _ready() -> void:
	# Setup environment
	var env = Environment.new()
	env.background_color = Color(0.04, 0.05, 0.1, 1)
	env.ambient_light_color = Color(0.3, 0.3, 0.4, 1)
	env.ambient_light_energy = 0.4
	env.fog_enabled = true
	env.fog_light_color = Color(0.04, 0.05, 0.1, 1)
	env.fog_density = 0.003
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	world_env.environment = env
	
	# Spawn scheme buildings
	_spawn_buildings()
	
	# Spawn parked vehicles
	_spawn_vehicles()

func _process(delta: float) -> void:
	elapsed_time += delta
	
	# Day/night cycle
	var t = fmod(elapsed_time / CYCLE_SECONDS, 1.0)  # 0..1
	var sun_angle = (t - 0.25) * TAU  # dawn at t=0.25
	directional_light.rotation.x = sun_angle
	
	# Sun intensity
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

func _spawn_buildings() -> void:
	var schemes = SchemeData.get_all_schemes()
	for scheme in schemes:
		var building = CSGBox3D.new()
		building.size = Vector3(8, scheme.get("height", 10), 8)
		building.position = Vector3(scheme.get("x", 0), scheme.get("height", 10) / 2.0, scheme.get("z", 0))
		building.material = _make_building_material(scheme)
		building.add_to_group("scheme_building")
		building.set_meta("scheme_id", scheme.id)
		building.set_meta("scheme_name", scheme.name)
		
		# Add collision
		var body = StaticBody3D.new()
		body.position = building.position
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = building.size
		col.shape = shape
		body.add_child(col)
		
		add_child(body)
		add_child(building)

func _make_building_material(scheme: Dictionary) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.from_string(scheme.get("color", "#4ade80"), Color.GREEN)
	mat.roughness = 0.6
	mat.metalness = 0.1
	return mat

func _spawn_vehicles() -> void:
	# Placeholder — vehicles will be added in Phase 3
	pass
