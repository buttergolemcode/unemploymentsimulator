# NPC.gd — A pedestrian or merchant NPC
# Uses Quaternius Modular Characters CC0 FBX models, falls back to capsule.
extends CharacterBody3D

var npc_color: String = "#4b5563"
var npc_model: String = ""  # character name (e.g. "Casual") — picked randomly if empty
var speed: float = 1.5
var target_pos: Vector3 = Vector3.ZERO
var district: String = "downtown"
var facing: float = 0.0
var is_merchant: bool = false
var walk_phase: float = 0.0
var is_down: bool = false  # knocked down by vehicle
var down_timer: float = 0.0  # seconds remaining down

@onready var mesh: Node3D = $NPCMesh

# Available character models (Quaternius Modular Characters, CC0)
const CHARACTER_MODELS: Array = [
	"Adventurer", "Beach", "Casual", "Casual2", "Farmer",
	"King", "Punk", "Spacesuit", "Suit", "Swat", "Worker",
]

static func get_model_path(model_name: String) -> String:
	return "res://assets/quaternius_modular_chars/FBX/%s.fbx" % model_name

func _ready():
	_build_mesh()
	if is_merchant:
		add_to_group("merchant")
	else:
		add_to_group("pedestrian")

func _build_mesh():
	# Pick a random character model if none specified
	if npc_model == "":
		npc_model = CHARACTER_MODELS[randi() % CHARACTER_MODELS.size()]

	# Try loading the real FBX model
	var model_path = get_model_path(npc_model)
	var packed_scene = load(model_path)
	if packed_scene != null:
		var instance = packed_scene.instantiate()
		# Quaternius characters are roughly 1.8m tall, scale to match our collision
		instance.scale = Vector3(1.0, 1.0, 1.0)
		# Pragmatic fix: rotate mesh by PI to face movement direction.
		# Despite Godot's -Z forward convention, the facing = atan2(-dx, -dz)
		# formula produces opposite orientation for this FBX. PI fixes it.
		instance.rotation.y = PI
		mesh.add_child(instance)
		# Add merchant badge if applicable
		if is_merchant:
			_add_merchant_badge()
		return

	# Fallback: build simple capsule mesh
	push_warning("NPC: could not load model '%s', falling back to capsule" % npc_model)
	_build_capsule_mesh()

func _add_merchant_badge():
	var badge = MeshInstance3D.new()
	var bg_mesh = SphereMesh.new()
	bg_mesh.radius = 0.1
	bg_mesh.height = 0.2
	badge.mesh = bg_mesh
	badge.position = Vector3(0, 2.0, 0)
	var bmat = StandardMaterial3D.new()
	bmat.albedo_color = Color.from_string(npc_color, Color.GREEN)
	bmat.emission_enabled = true
	bmat.emission = Color.from_string(npc_color, Color.GREEN)
	bmat.emission_energy_multiplier = 1.2
	badge.material_override = bmat
	mesh.add_child(badge)

func _build_capsule_mesh():
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.from_string(npc_color, Color.GRAY)
	mat.roughness = 0.8

	# Body (cylinder)
	var body = MeshInstance3D.new()
	var b_mesh = CylinderMesh.new()
	b_mesh.top_radius = 0.22
	b_mesh.bottom_radius = 0.22
	b_mesh.height = 1.0
	body.mesh = b_mesh
	body.position = Vector3(0, 0.95, 0)
	body.material_override = mat
	mesh.add_child(body)

	# Head (sphere)
	var head = MeshInstance3D.new()
	var h_mesh = SphereMesh.new()
	h_mesh.radius = 0.13
	h_mesh.height = 0.26
	head.mesh = h_mesh
	head.position = Vector3(0, 1.65, 0)
	var hmat = StandardMaterial3D.new()
	hmat.albedo_color = Color(0.99, 0.9, 0.55)
	hmat.roughness = 0.6
	head.material_override = hmat
	mesh.add_child(head)

	# Hat/hair (half sphere = scaled sphere)
	var hat = MeshInstance3D.new()
	var hat_mesh = SphereMesh.new()
	hat_mesh.radius = 0.14
	hat_mesh.height = 0.28
	hat.mesh = hat_mesh
	hat.position = Vector3(0, 1.71, 0)
	hat.scale = Vector3(1, 0.5, 1)  # flatten to half-sphere
	var hatmat = StandardMaterial3D.new()
	hatmat.albedo_color = Color(0.11, 0.1, 0.09)
	hatmat.roughness = 0.9
	hat.material_override = hatmat
	mesh.add_child(hat)

	if is_merchant:
		_add_merchant_badge()

func _physics_process(delta):
	if is_merchant:
		return

	# Handle knockdown state
	if is_down:
		down_timer -= delta
		mesh.rotation.x = lerp(mesh.rotation.x, -PI / 2, delta * 5)
		velocity = Vector3.ZERO
		move_and_slide()
		if down_timer <= 0:
			is_down = false
			mesh.rotation.x = 0
			_pick_new_target()
		return

	# Check for nearby vehicles (get run over)
	for vehicle in get_tree().get_nodes_in_group("vehicle"):
		var vd = global_position.distance_to(vehicle.global_position)
		if vd < 2.5 and abs(vehicle.speed) > 3.0:
			is_down = true
			down_timer = 4.0
			var kb_dir = (global_position - vehicle.global_position).normalized()
			velocity = kb_dir * 5.0
			move_and_slide()
			return

	var dx = target_pos.x - global_position.x
	var dz = target_pos.z - global_position.z
	var dist = sqrt(dx * dx + dz * dz)

	if dist < 0.5:
		_pick_new_target()
	else:
		# Check if next position would be on a street — if so, pick new target
		var next_x = global_position.x + (dx / dist) * 2.0
		var next_z = global_position.z + (dz / dist) * 2.0
		if _is_on_street(next_x, next_z):
			_pick_new_target()
			return
		velocity = Vector3(dx / dist * speed, 0, dz / dist * speed)
		facing = atan2(-dx, -dz)
		rotation.y = facing
		walk_phase += delta * 8
		mesh.position.y = abs(sin(walk_phase)) * 0.03
		mesh.rotation.x = lerp(mesh.rotation.x, 0.08, delta * 5.0)
		move_and_slide()

# Streets are at positions [-300, -200, -100, 0, 100, 200, 300] in both axes
# with ROAD_HALF_WIDTH (4m) buffer. NPCs should stay on sidewalks (outside this buffer).
static var STREET_POSITIONS: Array = [200, 300, 400, 500, 600, 700]
static var ROAD_HALF: float = 5.5  # 4m half-width + 1.5m buffer (keep NPCs on sidewalk)

static func _is_on_street(x: float, z: float) -> bool:
	# Check if position is on a street (within road half-width of any street line)
	for pos in STREET_POSITIONS:
		# East-West street at z=pos
		if abs(z - pos) < ROAD_HALF and abs(x) > 50 and abs(x) < 850:
			return true
		# North-South street at x=pos
		if abs(x - pos) < ROAD_HALF and abs(z) > -600 and abs(z) < 600:
			return true
	return false

func _pick_new_target():
	# Try to find a target that's NOT on a street (keep NPC on sidewalks/buildings)
	for attempt in range(20):
		var angle = randf() * TAU
		var dist = 8 + randf() * 20  # shorter range, stay near current block
		var candidate = global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		# Skip if candidate is on a street
		if not _is_on_street(candidate.x, candidate.z):
			target_pos = candidate
			return
	# Fallback: just pick any nearby point (NPC may briefly cross street)
	var angle = randf() * TAU
	var dist = 8 + randf() * 15
	target_pos = global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
