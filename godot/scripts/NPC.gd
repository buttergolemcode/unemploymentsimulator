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
	# Body capsule
	var body = CSGCylinder3D.new()
	body.radius = 0.22
	body.height = 1.0
	body.position = Vector3(0, 0.95, 0)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.from_string(npc_color, Color.GRAY)
	mat.roughness = 0.8
	body.material = mat
	mesh.add_child(body)
	
	# Head
	var head = CSGSphere3D.new()
	head.radius = 0.13
	head.position = Vector3(0, 1.65, 0)
	var hmat = StandardMaterial3D.new()
	hmat.albedo_color = Color(0.99, 0.9, 0.55)
	hmat.roughness = 0.6
	head.material = hmat
	mesh.add_child(head)
	
	# Hat/hair
	var hat = CSGSphere3D.new()
	hat.radius = 0.14
	hat.position = Vector3(0, 1.71, 0)
	hat.material = hmat
	mesh.add_child(hat)
	
	# Merchant badge
	if is_merchant:
		var badge = CSGSphere3D.new()
		badge.radius = 0.1
		badge.position = Vector3(0, 2.0, 0)
		var bmat = StandardMaterial3D.new()
		bmat.albedo_color = Color.from_string(npc_color, Color.GREEN)
		bmat.emission_enabled = true
		bmat.emission = Color.from_string(npc_color, Color.GREEN)
		bmat.emission_energy_multiplier = 1.2
		badge.material = bmat
		mesh.add_child(badge)

func _physics_process(delta):
	if is_merchant:
		return
	
	# Move toward target
	var dx = target_pos.x - global_position.x
	var dz = target_pos.z - global_position.z
	var dist = sqrt(dx * dx + dz * dz)
	
	if dist < 0.5:
		# Pick new target
		_pick_new_target()
	else:
		velocity = Vector3(dx / dist * speed, 0, dz / dist * speed)
		facing = atan2(dx, dz)
		rotation.y = facing
		walk_phase += delta * 8
		mesh.position.y = abs(sin(walk_phase)) * 0.06
		move_and_slide()

func _pick_new_target():
	# Pick a random point within 30m
	var angle = randf() * TAU
	var dist = 15 + randf() * 25
	target_pos = global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
