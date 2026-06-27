# Weather.gd — Rain particle system with random timing
extends Node3D

var rain_mesh: MultiMeshInstance3D
var rain_count: int = 800
var rain_area: float = 60.0
var rain_height: float = 25.0
var drops: Array = []
var rain_opacity: float = 0.0
var cloud_opacity: float = 0.0
var phase: String = "clear"
var phase_timer: float = 0.0
var next_transition: float = 0.0

# Cloud plane
var cloud_mesh: MeshInstance3D
# Ambient rain light
var rain_light: OmniLight3D

func _ready():
	_create_rain()
	_create_clouds()
	_create_light()
	_schedule_next(20, 60)  # First rain in 20-60s

func _create_rain():
	rain_mesh = MultiMeshInstance3D.new()
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _make_rain_drop_mesh()
	mm.instance_count = rain_count
	rain_mesh.multimesh = mm
	rain_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rain_mesh)
	
	drops.clear()
	for i in rain_count:
		drops.append({
			"x": (randf() - 0.5) * rain_area,
			"y": randf() * rain_height,
			"z": (randf() - 0.5) * rain_area,
			"speed": 22 + randf() * 12,
		})
		_update_drop_transform(i)

func _make_rain_drop_mesh() -> Mesh:
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.04, 0.6, 0.04)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.7, 0.85, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = mat
	return mesh

func _create_clouds():
	cloud_mesh = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(200, 200)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.07, 0.13, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	plane.material = mat
	cloud_mesh.mesh = plane
	cloud_mesh.position = Vector3(0, 30, 0)
	cloud_mesh.visible = false
	add_child(cloud_mesh)

func _create_light():
	rain_light = OmniLight3D.new()
	rain_light.light_color = Color(0.23, 0.31, 0.43)
	rain_light.light_energy = 0.0
	rain_light.omni_range = 100.0
	add_child(rain_light)

func _schedule_next(min_s: float, max_s: float):
	next_transition = randf_range(min_s, max_s)
	phase_timer = 0.0

func _process(delta):
	phase_timer += delta
	
	# State machine: clear -> fading_in -> raining -> fading_out -> clear
	match phase:
		"clear":
			if phase_timer >= next_transition:
				phase = "fading_in"
				phase_timer = 0.0
		"fading_in":
			rain_opacity = min(1.0, phase_timer / 4.0)
			cloud_opacity = min(1.0, phase_timer / 4.0 * 1.2)
			if phase_timer >= 4.0:
				phase = "raining"
				_schedule_next(30, 90)
		"raining":
			if phase_timer >= next_transition:
				phase = "fading_out"
				phase_timer = 0.0
		"fading_out":
			rain_opacity = max(0.0, 1.0 - phase_timer / 4.0)
			cloud_opacity = max(0.0, 1.0 - phase_timer / 4.0 * 0.9)
			if phase_timer >= 4.0:
				phase = "clear"
				rain_opacity = 0.0
				cloud_opacity = 0.0
				_schedule_next(20, 60)
	
	# Update visual opacity
	if rain_mesh and rain_mesh.multimesh:
		var mat = rain_mesh.multimesh.mesh.material as StandardMaterial3D
		if mat:
			mat.albedo_color.a = 0.5 * rain_opacity
		rain_mesh.visible = rain_opacity > 0.01
	
	if cloud_mesh:
		var cmat = cloud_mesh.mesh.material as StandardMaterial3D
		if cmat:
			cmat.albedo_color.a = 0.4 * cloud_opacity
		cloud_mesh.visible = cloud_opacity > 0.01
	
	if rain_light:
		rain_light.light_energy = 0.08 * rain_opacity
	
	# Update rain drops
	if rain_opacity > 0.01:
		var cam = get_viewport().get_camera_3d()
		var cam_pos = cam.global_position if cam else Vector3.ZERO
		var mm = rain_mesh.multimesh
		for i in rain_count:
			var d = drops[i]
			d.y -= d.speed * delta
			if d.y < 0:
				d.y = rain_height
				d.x = cam_pos.x + (randf() - 0.5) * rain_area
				d.z = cam_pos.z + (randf() - 0.5) * rain_area
			# Wrap around camera
			var dx = d.x - cam_pos.x
			var dz = d.z - cam_pos.z
			if abs(dx) > rain_area / 2:
				d.x = cam_pos.x - sign(dx) * rain_area / 2 + (randf() - 0.5) * 4
			if abs(dz) > rain_area / 2:
				d.z = cam_pos.z - sign(dz) * rain_area / 2 + (randf() - 0.5) * 4
			_update_drop_transform(i)

func _update_drop_transform(index: int):
	var d = drops[index]
	var t = Transform3D.IDENTITY
	t.origin = Vector3(d.x, d.y, d.z)
	rain_mesh.multimesh.set_instance_transform(index, t)
