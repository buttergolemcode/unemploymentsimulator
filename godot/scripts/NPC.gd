# NPC.gd — A pedestrian or merchant NPC
extends CharacterBody3D

var npc_color: String = "#4b5563"
var speed: float = 1.5
var target_pos: Vector3 = Vector3.ZERO
var district: String = "downtown"
var facing: float = 0.0
var is_merchant: bool = false
var walk_phase: float = 0.0

@onready var mesh: Node3D = $NPCMesh

func _ready():
	_build_mesh()
	if is_merchant:
		add_to_group("merchant")
	else:
		add_to_group("pedestrian")

func _build_mesh():
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
	
	# Merchant badge
	if is_merchant:
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

func _physics_process(delta):
	if is_merchant:
		return
	
	var dx = target_pos.x - global_position.x
	var dz = target_pos.z - global_position.z
	var dist = sqrt(dx * dx + dz * dz)
	
	if dist < 0.5:
		_pick_new_target()
	else:
		velocity = Vector3(dx / dist * speed, 0, dz / dist * speed)
		facing = atan2(dx, dz)
		rotation.y = facing
		walk_phase += delta * 8
		mesh.position.y = abs(sin(walk_phase)) * 0.06
		move_and_slide()

func _pick_new_target():
	var angle = randf() * TAU
	var dist = 15 + randf() * 25
	target_pos = global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
