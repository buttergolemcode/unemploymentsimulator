# WorldBuilder.gd — NYC-inspired city map with clear zone separation
# Called by GameScene on ready
class_name WorldBuilder
extends RefCounted

# ============================================================
# NYC-STYLE MAP DESIGN
# ============================================================
# City is a 800x800m grid (Manhattan-style).
# Clear zone hierarchy: STREET → SIDEWALK → BUILDING → GRASS
#
# Layout:
# - Streets on a 100m grid (avenues at x=-300,-200,-100,0,100,200,300)
# - Sidewalks 3m wide on each side of every street (raised 0.15m)
# - Building blocks 94x94m (between sidewalk edges) filled with 3-6 buildings
# - Rural zone outside city radius (with proper collision)
# - Mountains as walls at map edges
# - Water in east (harbor)
#
# Districts:
#   downtown: city center, tall skyscrapers
#   harbor: east waterfront, warehouses + cranes
#   slums: southwest, low brick buildings
#   industrial: northwest, factories
#   suburbs: west, small houses
#   rural: outside city, farms/forest

const MAP_SIZE: float = 800.0           # playable area (-400..+400)
const WATER_OFFSET: float = 400.0       # water starts at this distance from center
const WATER_PLANE_SIZE: float = 1600.0  # large enough to look infinite

# Street grid (NYC-style 100m blocks)
const STREET_GRID: Array = [-300, -200, -100, 0, 100, 200, 300]
const ROAD_HALF_WIDTH: float = 8.0      # street is 16m wide (4 lanes)
const SIDEWALK_WIDTH: float = 3.0       # 3m sidewalk on each side
const SIDEWALK_HEIGHT: float = 0.15     # raised sidewalk
const BLOCK_SIZE: float = 100.0         # distance between street centers
const BUILDING_MARGIN: float = 1.0      # gap between building and sidewalk

# District definitions
static var DISTRICTS: Dictionary = {}

static func _init_districts() -> void:
	if not DISTRICTS.is_empty():
		return
	DISTRICTS = {
		"downtown": {
			"color": "#475569", "height_min": 30, "height_max": 100, "ground": "#1a1a1a",
			"polygon": PackedVector2Array([
				Vector2(-200, -150), Vector2(200, -150), Vector2(200, 200), Vector2(-200, 200)
			])
		},
		"harbor": {
			"color": "#1c1917", "height_min": 8, "height_max": 22, "ground": "#171717",
			"polygon": PackedVector2Array([
				Vector2(200, -300), Vector2(400, -300), Vector2(400, 300), Vector2(200, 300)
			])
		},
		"slums": {
			"color": "#451a03", "height_min": 5, "height_max": 14, "ground": "#1a0f0a",
			"polygon": PackedVector2Array([
				Vector2(-400, 200), Vector2(-200, 200), Vector2(-200, 400), Vector2(-400, 400)
			])
		},
		"industrial": {
			"color": "#1f2937", "height_min": 9, "height_max": 24, "ground": "#161616",
			"polygon": PackedVector2Array([
				Vector2(-400, -400), Vector2(-200, -400), Vector2(-200, -150), Vector2(-400, -150)
			])
		},
		"suburbs": {
			"color": "#525252", "height_min": 4, "height_max": 9, "ground": "#1a2a1a",
			"polygon": PackedVector2Array([
				Vector2(-400, -150), Vector2(-200, -150), Vector2(-200, 200), Vector2(-400, 200)
			])
		},
		"rural": {
			"color": "#6b5b4a", "height_min": 3, "height_max": 6, "ground": "#2a3a1a",
			"polygon": PackedVector2Array([])
		},
	}

# ============================================================
# SCHEME BUILDINGS — placed at clear positions within district blocks
# ============================================================

const SCHEME_BUILDINGS: Array = [
	# Downtown (center)
	{"id": "trading", "name": "Trading Floor", "emoji": "📈",
	 "x": -50, "z": -50, "w": 18, "d": 16, "h": 50, "color": "#22d3ee"},
	{"id": "wirefraud", "name": "Corporate Tower", "emoji": "💸",
	 "x": 50, "z": -50, "w": 22, "d": 20, "h": 90, "color": "#64748b"},
	{"id": "taxfraud", "name": "Accountant Office", "emoji": "🧾",
	 "x": -150, "z": 50, "w": 14, "d": 12, "h": 28, "color": "#eab308"},
	{"id": "gambling", "name": "Casino", "emoji": "🎰",
	 "x": 150, "z": 100, "w": 20, "d": 18, "h": 22, "color": "#f59e0b"},
	# Slums (SW)
	{"id": "drugs", "name": "Trap House", "emoji": "💊",
	 "x": -350, "z": 250, "w": 12, "d": 10, "h": 10, "color": "#a855f7"},
	{"id": "scam", "name": "Internet Cafe", "emoji": "🎣",
	 "x": -250, "z": 350, "w": 10, "d": 9, "h": 8, "color": "#ec4899"},
	{"id": "robbery", "name": "Corner Store", "emoji": "🔫",
	 "x": -350, "z": 350, "w": 9, "d": 9, "h": 6, "color": "#ef4444"},
	# Industrial (NW)
	{"id": "ecom", "name": "E-Com Warehouse", "emoji": "📦",
	 "x": -350, "z": -250, "w": 20, "d": 18, "h": 14, "color": "#4ade80"},
]

# ============================================================
# District lookup (polygon-based)
# ============================================================

static func get_district_at(x: float, z: float) -> String:
	_init_districts()
	var point = Vector2(x, z)
	for district_name in ["downtown", "harbor", "slums", "industrial", "suburbs"]:
		var district = DISTRICTS[district_name]
		var polygon = district.get("polygon", PackedVector2Array())
		if polygon.size() >= 3 and Geometry2D.is_point_in_polygon(point, polygon):
			return district_name
	# Rural = inside city bounds but outside district polygons
	var r = sqrt(x * x + z * z)
	if r < WATER_OFFSET:
		return "rural"
	# Beyond water = water
	return "water"

# ============================================================
# Terrain height (flat city, hills at rural edge, water below)
# ============================================================

static func terrain_height(x: float, z: float) -> float:
	var r = sqrt(x * x + z * z)
	# City area: completely flat
	if r < 380:
		return 0.0
	# Rural edge: gentle hills rising toward mountains
	if r < WATER_OFFSET:
		var blend = (r - 380) / (WATER_OFFSET - 380)
		return _fractal_noise(x, z, 2) * 6 * blend
	# Water (below sea level)
	return -3.0

static func _hash2(x: float, z: float) -> float:
	var h = sin(x * 127.1 + z * 311.7) * 43758.5453
	return h - floor(h)

static func _smooth_noise(x: float, z: float) -> float:
	var ix = floor(x)
	var iz = floor(z)
	var fx = x - ix
	var fz = z - iz
	var sx = fx * fx * (3 - 2 * fx)
	var sz = fz * fz * (3 - 2 * fz)
	var n00 = _hash2(ix, iz)
	var n10 = _hash2(ix + 1, iz)
	var n01 = _hash2(ix, iz + 1)
	var n11 = _hash2(ix + 1, iz + 1)
	return n00 * (1 - sx) * (1 - sz) + n10 * sx * (1 - sz) + n01 * (1 - sx) * sz + n11 * sx * sz

static func _fractal_noise(x: float, z: float, octaves: int) -> float:
	var value = 0.0
	var amp = 1.0
	var freq = 1.0
	var max_val = 0.0
	for i in octaves:
		value += _smooth_noise(x * freq * 0.01, z * freq * 0.01) * amp
		max_val += amp
		amp *= 0.5
		freq *= 2
	return value / max_val

# ============================================================
# Build everything
# ============================================================

static func build_world(parent: Node3D) -> void:
	_init_districts()
	_build_terrain(parent)
	_build_water(parent)
	_build_roads(parent)
	_build_scheme_buildings(parent)
	_build_filler_buildings(parent)
	_build_street_lamps(parent)
	_build_dock_props(parent)
	_build_landmarks(parent)

# ============================================================
# Terrain — flat city + rural hills + mountain walls
# ============================================================

static func _build_terrain(parent: Node3D) -> void:
	# Visual terrain mesh with height variation
	var size = 900
	var segs = 100
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(size, size)
	mesh.subdivide_width = segs
	mesh.subdivide_depth = segs
	
	var surf = SurfaceTool.new()
	surf.create_from(mesh, 0)
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(surf.commit(), 0)
	
	for i in mdt.get_vertex_count():
		var v = mdt.get_vertex(i)
		var h = terrain_height(v.x, v.z)
		v.y = h
		mdt.set_vertex(i, v)
		# Vertex color based on district / height
		var col: Color
		if h < -1:
			col = Color(0.08, 0.18, 0.32)  # water
		else:
			var dist_id = get_district_at(v.x, v.z)
			match dist_id:
				"downtown":
					col = Color(0.12, 0.12, 0.14)
				"harbor":
					col = Color(0.14, 0.14, 0.14)
				"slums":
					col = Color(0.18, 0.12, 0.08)
				"industrial":
					col = Color(0.14, 0.15, 0.16)
				"suburbs":
					col = Color(0.20, 0.30, 0.18)
				"rural":
					col = Color(0.25, 0.35, 0.18)  # green grass
				_:
					col = Color(0.08, 0.18, 0.32)  # water
		mdt.set_vertex_color(i, col)
	
	var final_mesh = ArrayMesh.new()
	mdt.commit_to_surface(final_mesh)
	
	var mi = MeshInstance3D.new()
	mi.mesh = final_mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	mi.material_override = mat
	
	# === COLLISION SYSTEM (proper — covers all terrain) ===
	# 1) City ground (flat, covers entire city + rural area at y=0)
	var city_body = StaticBody3D.new()
	city_body.name = "CityGround"
	var city_col = CollisionShape3D.new()
	var city_shape = BoxShape3D.new()
	city_shape.size = Vector3(800, 1.0, 800)  # 800x800 flat ground at y=-0.5
	city_col.shape = city_shape
	city_col.position = Vector3(0, -0.5, 0)
	city_body.add_child(city_col)
	parent.add_child(city_body)
	
	# 2) Rural raised collision (4 boxes at corners, matching terrain_height)
	var rural_body = StaticBody3D.new()
	rural_body.name = "RuralGround"
	# Add multiple collision boxes around the rural perimeter
	for angle_deg in range(0, 360, 30):
		var angle = deg_to_rad(angle_deg)
		var rx = cos(angle) * 390.0  # radius just inside water
		var rz = sin(angle) * 390.0
		var rcol = CollisionShape3D.new()
		var rshape = BoxShape3D.new()
		rshape.size = Vector3(80, 1.0, 80)
		rcol.shape = rshape
		var h_at = terrain_height(rx, rz)
		rcol.position = Vector3(rx, h_at - 0.5, rz)
		rural_body.add_child(rcol)
	parent.add_child(rural_body)
	
	# 3) Mountain walls (impassable barriers at map edges)
	# North wall (z < -400)
	var north_body = StaticBody3D.new()
	north_body.name = "MountainNorth"
	var north_col = CollisionShape3D.new()
	var north_shape = BoxShape3D.new()
	north_shape.size = Vector3(1200, 100, 200)
	north_col.shape = north_shape
	north_col.position = Vector3(0, 50, -500)
	north_body.add_child(north_col)
	parent.add_child(north_body)
	# South wall (z > 400)
	var south_body = StaticBody3D.new()
	south_body.name = "MountainSouth"
	var south_col = CollisionShape3D.new()
	var south_shape = BoxShape3D.new()
	south_shape.size = Vector3(1200, 100, 200)
	south_col.shape = south_shape
	south_col.position = Vector3(0, 50, 500)
	south_body.add_child(south_col)
	parent.add_child(south_body)
	# West wall (x < -400)
	var west_body = StaticBody3D.new()
	west_body.name = "MountainWest"
	var west_col = CollisionShape3D.new()
	var west_shape = BoxShape3D.new()
	west_shape.size = Vector3(200, 100, 1200)
	west_col.shape = west_shape
	west_col.position = Vector3(-500, 50, 0)
	west_body.add_child(west_col)
	parent.add_child(west_body)
	# East harbor wall (low barrier to block ground vehicles from water)
	var east_body = StaticBody3D.new()
	east_body.name = "HarborBarrier"
	var east_col = CollisionShape3D.new()
	var east_shape = BoxShape3D.new()
	east_shape.size = Vector3(20, 4, 1200)
	east_col.shape = east_shape
	east_col.position = Vector3(410, 2, 0)
	east_body.add_child(east_col)
	parent.add_child(east_body)
	
	parent.add_child(mi)

# ============================================================
# Water (east harbor)
# ============================================================

static func _build_water(parent: Node3D) -> void:
	var plane = PlaneMesh.new()
	plane.size = Vector2(WATER_PLANE_SIZE, WATER_PLANE_SIZE)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.22, 0.35, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.15
	mat.metalness = 0.4
	plane.material = mat
	var mi = MeshInstance3D.new()
	mi.mesh = plane
	mi.position = Vector3(800, -3.0, 0)  # east side, below ground
	parent.add_child(mi)

# ============================================================
# Roads — NYC grid with clear sidewalks
# ============================================================

static func _build_roads(parent: Node3D) -> void:
	# Streets at every position in STREET_GRID (every 100m)
	# Each street has: asphalt + 2 raised sidewalks + lane markings
	for pos in STREET_GRID:
		# East-West street (along x-axis, at z=pos)
		_make_street(parent, "x", pos)
		# North-South street (along z-axis, at x=pos)
		_make_street(parent, "z", pos)

static func _make_street(parent: Node3D, axis: String, pos: float) -> void:
	var length = 800.0  # spans entire city
	# === ASPHALT (street surface) ===
	var asphalt = MeshInstance3D.new()
	var a_mesh = BoxMesh.new()
	if axis == "x":
		a_mesh.size = Vector3(length, 0.02, ROAD_HALF_WIDTH * 2)
		asphalt.position = Vector3(0, 0.02, pos)
	else:
		a_mesh.size = Vector3(ROAD_HALF_WIDTH * 2, 0.02, length)
		asphalt.position = Vector3(pos, 0.02, 0)
	asphalt.mesh = a_mesh
	var amat = StandardMaterial3D.new()
	amat.albedo_color = Color(0.08, 0.08, 0.08)  # dark asphalt
	amat.roughness = 0.95
	asphalt.material_override = amat
	parent.add_child(asphalt)
	
	# === SIDEWALKS (raised, on both sides) ===
	for side in [-1, 1]:
		var sidewalk = MeshInstance3D.new()
		var s_mesh = BoxMesh.new()
		if axis == "x":
			s_mesh.size = Vector3(length, SIDEWALK_HEIGHT, SIDEWALK_WIDTH)
			sidewalk.position = Vector3(0, SIDEWALK_HEIGHT / 2, pos + side * (ROAD_HALF_WIDTH + SIDEWALK_WIDTH / 2))
		else:
			s_mesh.size = Vector3(SIDEWALK_WIDTH, SIDEWALK_HEIGHT, length)
			sidewalk.position = Vector3(pos + side * (ROAD_HALF_WIDTH + SIDEWALK_WIDTH / 2), SIDEWALK_HEIGHT / 2, 0)
		sidewalk.mesh = s_mesh
		var smat = StandardMaterial3D.new()
		smat.albedo_color = Color(0.55, 0.55, 0.55)  # light gray sidewalk (NYC concrete)
		smat.roughness = 0.9
		sidewalk.material_override = smat
		parent.add_child(sidewalk)
	
	# === LANE MARKINGS (dashed yellow center line) ===
	var dash_spacing = 5.0
	var count = int(length / dash_spacing)
	for i in count:
		var t = (i - (count - 1) / 2.0) * dash_spacing
		var dash = MeshInstance3D.new()
		var d_mesh = BoxMesh.new()
		if axis == "x":
			d_mesh.size = Vector3(2.5, 0.01, 0.3)
			dash.position = Vector3(t, 0.04, pos)
		else:
			d_mesh.size = Vector3(0.3, 0.01, 2.5)
			dash.position = Vector3(pos, 0.04, t)
		dash.mesh = d_mesh
		var dmat = StandardMaterial3D.new()
		dmat.albedo_color = Color(0.95, 0.85, 0.2)
		dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		dash.material_override = dmat
		parent.add_child(dash)

# ============================================================
# Scheme buildings (8 thematic spots)
# ============================================================

static func _build_scheme_buildings(parent: Node3D) -> void:
	for b in SCHEME_BUILDINGS:
		var mesh = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()
		b_mesh.size = Vector3(b.w, b.h, b.d)
		mesh.mesh = b_mesh
		mesh.position = Vector3(b.x, b.h / 2.0, b.z)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color.from_string(b.color, Color.GRAY)
		mat.roughness = 0.6
		mat.metalness = 0.1
		mesh.material_override = mat
		mesh.add_to_group("scheme_building")
		mesh.set_meta("scheme_id", b.id)
		mesh.set_meta("scheme_name", b.name)
		mesh.set_meta("scheme_emoji", b.emoji)
		parent.add_child(mesh)
		
		# Collision
		var body = StaticBody3D.new()
		body.position = Vector3(b.x, b.h / 2.0, b.z)
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(b.w, b.h, b.d)
		col.shape = shape
		body.add_child(col)
		parent.add_child(body)
		
		# Label
		var label = Label3D.new()
		label.text = "%s %s" % [b.emoji, b.name]
		label.position = Vector3(b.x, b.h + 2, b.z)
		label.font_size = 48
		label.outline_size = 6
		label.outline_modulate = Color.BLACK
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		parent.add_child(label)

# ============================================================
# Filler buildings — NYC dense grid placement
# ============================================================

static func _build_filler_buildings(parent: Node3D) -> void:
	# NYC-style: every block (100x100m between streets) is fully built
	# Each block has 2-4 buildings depending on district
	# Buildings sit flush against sidewalk (no setback)
	
	# Block centers (between streets, at -250, -50, 50, 250)
	# (because streets are at -300, -200, -100, 0, 100, 200, 300,
	#  block centers are at -250, -150, -50, 50, 150, 250)
	var block_centers = [-250, -150, -50, 50, 150, 250]
	
	for bx in block_centers:
		for bz in block_centers:
			_build_block(parent, bx, bz)

static func _build_block(parent: Node3D, bx: float, bz: float) -> void:
	# District at block center
	var dist_id = get_district_at(bx, bz)
	if dist_id == "water" or dist_id == "rural":
		return  # no buildings in water/rural
	
	# Block bounds (100x100m block, with sidewalk + margin subtracted)
	var road_buffer = ROAD_HALF_WIDTH + SIDEWALK_WIDTH + BUILDING_MARGIN
	var block_inner = BLOCK_SIZE - 2 * road_buffer  # ~84m
	if block_inner < 10:
		return
	
	var bx_min = bx - block_inner / 2
	var bz_min = bz - block_inner / 2
	
	# Number of buildings per block depends on district
	var buildings_per_side: int
	match dist_id:
		"downtown":
			buildings_per_side = 2  # 2x2 = 4 large towers per block
		"industrial":
			buildings_per_side = 2  # 2x2 = 4 medium factories
		"harbor":
			buildings_per_side = 2  # 2x2 = 4 warehouses
		"slums":
			buildings_per_side = 3  # 3x3 = 9 small houses (dense slums)
		"suburbs":
			buildings_per_side = 2  # 2x2 = 4 small houses
		_:
			buildings_per_side = 2
	
	var cell_w = block_inner / buildings_per_side
	var cell_d = block_inner / buildings_per_side
	
	# Hash for deterministic variation per block
	var seed_val = abs((int(bx) * 73856093) ^ (int(bz) * 19349663)) % 99991
	var rng = func(salt): return float((seed_val * (salt + 1) * 9301 + 49297) % 233280) / 233280
	
	for ix in range(buildings_per_side):
		for iz in range(buildings_per_side):
			# Cell center
			var cx = bx_min + cell_w * (ix + 0.5)
			var cz = bz_min + cell_d * (iz + 0.5)
			
			# Skip if too close to scheme building
			var too_close = false
			for b in SCHEME_BUILDINGS:
				if sqrt((cx - b.x) ** 2 + (cz - b.z) ** 2) < max(b.w, b.d) / 2 + 8:
					too_close = true
					break
			if too_close:
				continue
			
			# Skip chance per district (for variety)
			var skip = 0.0
			match dist_id:
				"downtown": skip = 0.10
				"harbor": skip = 0.25
				"slums": skip = 0.10
				"industrial": skip = 0.20
				"suburbs": skip = 0.35
			if rng.call((ix * 7 + iz * 13) % 100) < skip:
				continue
			
			# Building dimensions — fill cell
			var margin = 1.5
			var max_w = cell_w - margin * 2
			var max_d = cell_d - margin * 2
			var dist = DISTRICTS[dist_id]
			var w: float
			var d: float
			var h: float
			match dist_id:
				"downtown":
					w = min(max_w, 25 + rng.call(ix + 1) * 10)
					d = min(max_d, 22 + rng.call(iz + 1) * 10)
					h = dist.height_min + rng.call(ix + iz + 1) * (dist.height_max - dist.height_min)
				"industrial":
					w = min(max_w, 25 + rng.call(ix + 1) * 8)
					d = min(max_d, 22 + rng.call(iz + 1) * 8)
					h = dist.height_min + rng.call(ix + iz + 1) * (dist.height_max - dist.height_min)
				"harbor":
					w = min(max_w, 25 + rng.call(ix + 1) * 8)
					d = min(max_d, 22 + rng.call(iz + 1) * 8)
					h = dist.height_min + rng.call(ix + iz + 1) * (dist.height_max - dist.height_min)
				"slums":
					w = min(max_w, 10 + rng.call(ix + 1) * 4)
					d = min(max_d, 9 + rng.call(iz + 1) * 4)
					h = dist.height_min + rng.call(ix + iz + 1) * (dist.height_max - dist.height_min)
				_:
					w = min(max_w, 10 + rng.call(ix + 1) * 4)
					d = min(max_d, 9 + rng.call(iz + 1) * 4)
					h = dist.height_min + rng.call(ix + iz + 1) * (dist.height_max - dist.height_min)
			
			_make_district_building(parent, cx, cz, w, d, h, dist_id, rng)

# ============================================================
# District-specific building styles
# ============================================================

static func _make_district_building(parent: Node3D, x: float, z: float,
		w: float, d: float, h: float, dist_id: String, rng: Callable) -> void:
	var mesh = MeshInstance3D.new()
	var body = StaticBody3D.new()
	body.position = Vector3(x, h / 2, z)
	
	match dist_id:
		"downtown":
			# Tall glass skyscraper — emissive blue windows
			var b_mesh = BoxMesh.new()
			b_mesh.size = Vector3(w, h, d)
			mesh.mesh = b_mesh
			mesh.position = Vector3(x, h / 2, z)
			var mat = StandardMaterial3D.new()
			var colors = ["#1e293b", "#0f172a", "#1e3a5f", "#1e293b", "#0c4a6e"]
			mat.albedo_color = Color.from_string(colors[int(rng.call(1) * 5) % 5], Color.DIM_GRAY)
			mat.metalness = 0.7
			mat.roughness = 0.2
			mat.emission_enabled = true
			mat.emission = Color(0.3, 0.5, 0.7)
			mat.emission_energy_multiplier = 0.25
			mesh.material_override = mat
		"harbor":
			# Low warehouse — dark, flat roof
			var b_mesh = BoxMesh.new()
			b_mesh.size = Vector3(w, h, d)
			mesh.mesh = b_mesh
			mesh.position = Vector3(x, h / 2, z)
			var mat = StandardMaterial3D.new()
			var colors = ["#1c1917", "#292524", "#44403c", "#1f2937", "#0c0a09"]
			mat.albedo_color = Color.from_string(colors[int(rng.call(1) * 5) % 5], Color.DIM_GRAY)
			mat.roughness = 0.95
			mesh.material_override = mat
		"slums":
			# Small rundown house — brown/red brick
			var b_mesh = BoxMesh.new()
			b_mesh.size = Vector3(w, h, d)
			mesh.mesh = b_mesh
			mesh.position = Vector3(x, h / 2, z)
			var mat = StandardMaterial3D.new()
			var colors = ["#7c2d12", "#9a3412", "#451a03", "#57534e", "#78350f", "#5b2c0f"]
			mat.albedo_color = Color.from_string(colors[int(rng.call(1) * 6) % 6], Color.DIM_GRAY)
			mat.roughness = 1.0
			mesh.material_override = mat
		"industrial":
			# Factory — gray, metallic
			var b_mesh = BoxMesh.new()
			b_mesh.size = Vector3(w, h, d)
			mesh.mesh = b_mesh
			mesh.position = Vector3(x, h / 2, z)
			var mat = StandardMaterial3D.new()
			var colors = ["#3f3f46", "#525252", "#27272a", "#404040", "#52525b"]
			mat.albedo_color = Color.from_string(colors[int(rng.call(1) * 5) % 5], Color.DIM_GRAY)
			mat.metalness = 0.4
			mat.roughness = 0.7
			mesh.material_override = mat
		_:
			# Suburbs — light-colored small house
			var b_mesh = BoxMesh.new()
			b_mesh.size = Vector3(w, h, d)
			mesh.mesh = b_mesh
			mesh.position = Vector3(x, h / 2, z)
			var mat = StandardMaterial3D.new()
			var colors = ["#a3a3a3", "#d4d4d4", "#f5f5f5", "#e5e5e5", "#bfbfbf", "#d1d5db"]
			mat.albedo_color = Color.from_string(colors[int(rng.call(1) * 6) % 6], Color.DIM_GRAY)
			mat.roughness = 0.9
			mesh.material_override = mat
	
	parent.add_child(mesh)
	# Collision
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(w, h, d)
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)

# ============================================================
# Helper: check if point is on a street
# ============================================================

static func _is_on_road(x: float, z: float) -> bool:
	# Streets are at STREET_GRID positions (-300, -200, -100, 0, 100, 200, 300)
	# with sidewalk buffer
	var road_buffer = ROAD_HALF_WIDTH + SIDEWALK_WIDTH
	for pos in STREET_GRID:
		if abs(z - pos) < road_buffer and abs(x) < 400:
			return true
		if abs(x - pos) < road_buffer and abs(z) < 400:
			return true
	return false

# ============================================================
# Trees (used by park + scattered in rural areas)
# ============================================================

static func _make_tree(parent: Node3D, x: float, z: float, s: float):
	var ground_y = terrain_height(x, z)
	# Trunk
	var trunk = MeshInstance3D.new()
	var trunk_mesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.2
	trunk_mesh.bottom_radius = 0.3
	trunk_mesh.height = 3
	trunk.mesh = trunk_mesh
	trunk.position = Vector3(x, ground_y + 1.5, z)
	var tmat = StandardMaterial3D.new()
	tmat.albedo_color = Color(0.29, 0.23, 0.1)
	tmat.roughness = 0.9
	trunk.material_override = tmat
	trunk.scale = Vector3(s, s, s)
	parent.add_child(trunk)
	# Foliage (cone)
	var foliage = MeshInstance3D.new()
	var fol_mesh = PrismMesh.new()
	fol_mesh.size = Vector3(3.6, 4, 3.6)
	foliage.mesh = fol_mesh
	foliage.position = Vector3(x, ground_y + 3.5, z)
	var fmat = StandardMaterial3D.new()
	fmat.albedo_color = Color(0.17, 0.29, 0.1)
	fmat.roughness = 0.85
	foliage.material_override = fmat
	foliage.scale = Vector3(s, s, s)
	parent.add_child(foliage)

# ============================================================
# Street lamps
# ============================================================

static func _build_street_lamps(parent: Node3D) -> void:
	var positions = [
		Vector3(-6, 0, -4), Vector3(6, 0, -4), Vector3(-6, 0, 6), Vector3(6, 0, 6),
		Vector3(-20, 0, -20), Vector3(20, 0, -20), Vector3(-20, 0, 20), Vector3(20, 0, 20),
		Vector3(-30, 0, -40), Vector3(-45, 0, -15), Vector3(30, 0, -40), Vector3(45, 0, -15),
		Vector3(-30, 0, 40), Vector3(-45, 0, 15), Vector3(30, 0, 40), Vector3(45, 0, 15),
	]
	for pos in positions:
		var pole = MeshInstance3D.new()
		var p_mesh = CylinderMesh.new()
		p_mesh.top_radius = 0.08
		p_mesh.bottom_radius = 0.08
		p_mesh.height = 4
		pole.mesh = p_mesh
		pole.position = pos + Vector3(0, 2, 0)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.06, 0.06, 0.06)
		pole.material_override = mat
		parent.add_child(pole)
		var light = OmniLight3D.new()
		light.position = pos + Vector3(0, 4, 0)
		light.light_color = Color(1, 0.95, 0.8)
		light.light_energy = 2.0
		light.omni_range = 12.0
		parent.add_child(light)

# ============================================================
# Harbor dock props (cranes, containers)
# ============================================================

static func _build_dock_props(parent: Node3D) -> void:
	# Cargo containers in harbor district
	for i in range(40):
		var x = 220 + randf() * 150
		var z = -250 + randf() * 500
		if get_district_at(x, z) != "harbor":
			continue
		var container = MeshInstance3D.new()
		var c_mesh = BoxMesh.new()
		var rot = randf() > 0.5
		if rot:
			c_mesh.size = Vector3(12, 2.5, 2.5)
		else:
			c_mesh.size = Vector3(2.5, 2.5, 12)
		container.mesh = c_mesh
		var stack_h = int(randf() * 3) * 2.6
		container.position = Vector3(x, 1.3 + stack_h, z)
		var mat = StandardMaterial3D.new()
		var colors = ["#dc2626", "#2563eb", "#16a34a", "#eab308", "#ea580c", "#7c3aed"]
		mat.albedo_color = Color.from_string(colors[randi() % colors.size()], Color.GRAY)
		mat.roughness = 0.7
		container.material_override = mat
		parent.add_child(container)
	# Cargo cranes (visual landmarks at harbor)
	for i in range(4):
		var cx = 230 + i * 30
		var cz = -100 + (i % 2) * 200
		var crane = _make_crane()
		crane.position = Vector3(cx, 0, cz)
		parent.add_child(crane)

static func _make_crane() -> Node3D:
	var root = Node3D.new()
	# Base
	var base = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(4, 2, 4)
	base.mesh = b_mesh
	base.position = Vector3(0, 1, 0)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.3, 0.1)
	mat.roughness = 0.7
	base.material_override = mat
	root.add_child(base)
	# Tower
	var tower = MeshInstance3D.new()
	var t_mesh = BoxMesh.new()
	t_mesh.size = Vector3(2, 20, 2)
	tower.mesh = t_mesh
	tower.position = Vector3(0, 12, 0)
	tower.material_override = mat
	root.add_child(tower)
	# Horizontal arm
	var arm = MeshInstance3D.new()
	var a_mesh = BoxMesh.new()
	a_mesh.size = Vector3(15, 1.5, 1.5)
	arm.mesh = a_mesh
	arm.position = Vector3(5, 22, 0)
	arm.material_override = mat
	root.add_child(arm)
	return root

# ============================================================
# Landmarks (visual points of interest)
# ============================================================

static func _build_landmarks(parent: Node3D) -> void:
	# Central Park (large green area in downtown)
	_park(parent, -50, 100, 80, 50)
	# Skyline row (3 tall towers)
	_skyscraper(parent, 150, -100, 12, 90, "#1e293b")
	_skyscraper(parent, 175, -100, 12, 110, "#0f172a")
	_skyscraper(parent, 200, -100, 12, 95, "#1e293b")
	# Bridge at harbor
	_bridge(parent, 250, 0, 0)
	# Fortress on west hill
	_fortress(parent, -300, -300)
	# Stadium
	_stadium(parent, -250, 100)
	# Church tower
	_church_tower(parent, 0, 0)
	# Bus station
	_bus_station(parent, 100, 150)
	# Gas stations
	_gas_station(parent, -200, -200)
	_gas_station(parent, 200, 200)

static func _park(parent: Node3D, x: float, z: float, w: float, d: float) -> void:
	var grass = MeshInstance3D.new()
	var g_mesh = BoxMesh.new()
	g_mesh.size = Vector3(w, 0.1, d)
	grass.mesh = g_mesh
	grass.position = Vector3(x, 0.05, z)
	var gmat = StandardMaterial3D.new()
	gmat.albedo_color = Color(0.18, 0.35, 0.15)
	gmat.roughness = 1.0
	grass.material_override = gmat
	parent.add_child(grass)
	for i in range(8):
		var tx = x + (randf() - 0.5) * w * 0.8
		var tz = z + (randf() - 0.5) * d * 0.8
		_make_tree(parent, tx, tz, 0.8 + randf() * 0.5)

static func _skyscraper(parent: Node3D, x: float, z: float, w: float, h: float, color: String) -> void:
	var mesh = MeshInstance3D.new()
	var s_mesh = BoxMesh.new()
	s_mesh.size = Vector3(w, h, w)
	mesh.mesh = s_mesh
	mesh.position = Vector3(x, h / 2, z)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.from_string(color, Color.DIM_GRAY)
	mat.metalness = 0.7
	mat.roughness = 0.2
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.5, 0.6)
	mat.emission_energy_multiplier = 0.15
	mesh.material_override = mat
	parent.add_child(mesh)
	var body = StaticBody3D.new()
	body.position = Vector3(x, h / 2, z)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(w, h, w)
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)

static func _bridge(parent: Node3D, x: float, z: float, _rot: float) -> void:
	var deck = MeshInstance3D.new()
	var d_mesh = BoxMesh.new()
	d_mesh.size = Vector3(60, 1, 8)
	deck.mesh = d_mesh
	deck.position = Vector3(x, 5, z)
	var dmat = StandardMaterial3D.new()
	dmat.albedo_color = Color(0.3, 0.3, 0.3)
	dmat.roughness = 0.9
	deck.material_override = dmat
	parent.add_child(deck)
	for tx in [x - 25, x + 25]:
		var tower = MeshInstance3D.new()
		var t_mesh = BoxMesh.new()
		t_mesh.size = Vector3(2, 12, 2)
		tower.mesh = t_mesh
		tower.position = Vector3(tx, 6, z)
		tower.material_override = dmat
		parent.add_child(tower)

static func _fortress(parent: Node3D, x: float, z: float) -> void:
	var stone = StandardMaterial3D.new()
	stone.albedo_color = Color(0.45, 0.4, 0.35)
	stone.roughness = 0.95
	var keep = MeshInstance3D.new()
	var k_mesh = BoxMesh.new()
	k_mesh.size = Vector3(15, 18, 15)
	keep.mesh = k_mesh
	keep.position = Vector3(x, 9, z)
	keep.material_override = stone
	parent.add_child(keep)
	for offset in [Vector2(-10, -10), Vector2(10, -10), Vector2(-10, 10), Vector2(10, 10)]:
		var tower = MeshInstance3D.new()
		var t_mesh = CylinderMesh.new()
		t_mesh.top_radius = 2.5
		t_mesh.bottom_radius = 3
		t_mesh.height = 22
		tower.mesh = t_mesh
		tower.position = Vector3(x + offset.x, 11, z + offset.y)
		tower.material_override = stone
		parent.add_child(tower)

static func _stadium(parent: Node3D, x: float, z: float) -> void:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.55, 0.55)
	mat.roughness = 0.85
	for i in range(24):
		var angle = i * TAU / 24
		var px = x + cos(angle) * 35
		var pz = z + sin(angle) * 25
		var stand = MeshInstance3D.new()
		var s_mesh = BoxMesh.new()
		s_mesh.size = Vector3(10, 12, 8)
		stand.mesh = s_mesh
		stand.position = Vector3(px, 6, pz)
		stand.rotation.y = angle
		stand.material_override = mat
		parent.add_child(stand)

static func _church_tower(parent: Node3D, x: float, z: float) -> void:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.8, 0.7)
	mat.roughness = 0.9
	var base = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(8, 30, 8)
	base.mesh = b_mesh
	base.position = Vector3(x, 15, z)
	base.material_override = mat
	parent.add_child(base)
	var spire = MeshInstance3D.new()
	var s_mesh = PrismMesh.new()
	s_mesh.size = Vector3(6, 12, 6)
	spire.mesh = s_mesh
	spire.position = Vector3(x, 36, z)
	spire.material_override = mat
	parent.add_child(spire)

static func _bus_station(parent: Node3D, x: float, z: float) -> void:
	var mesh = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(20, 6, 12)
	mesh.mesh = b_mesh
	mesh.position = Vector3(x, 3, z)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.7, 0.7)
	mat.roughness = 0.8
	mesh.material_override = mat
	parent.add_child(mesh)
	var sign = Label3D.new()
	sign.text = "🚌 BUS"
	sign.position = Vector3(x, 7, z)
	sign.font_size = 48
	sign.outline_size = 6
	sign.outline_modulate = Color.BLACK
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.no_depth_test = true
	parent.add_child(sign)

static func _gas_station(parent: Node3D, x: float, z: float) -> void:
	var canopy = MeshInstance3D.new()
	var c_mesh = BoxMesh.new()
	c_mesh.size = Vector3(12, 0.5, 8)
	canopy.mesh = c_mesh
	canopy.position = Vector3(x, 5, z)
	var cmat = StandardMaterial3D.new()
	cmat.albedo_color = Color(0.2, 0.2, 0.2)
	cmat.roughness = 0.7
	canopy.material_override = cmat
	parent.add_child(canopy)
	for sx in [x - 5, x + 5]:
		for sz in [z - 3, z + 3]:
			var post = MeshInstance3D.new()
			var p_mesh = BoxMesh.new()
			p_mesh.size = Vector3(0.3, 5, 0.3)
			post.mesh = p_mesh
			post.position = Vector3(sx, 2.5, sz)
			post.material_override = cmat
			parent.add_child(post)
	var shop = MeshInstance3D.new()
	var s_mesh = BoxMesh.new()
	s_mesh.size = Vector3(6, 4, 5)
	shop.mesh = s_mesh
	shop.position = Vector3(x + 10, 2, z)
	var smat = StandardMaterial3D.new()
	smat.albedo_color = Color(0.85, 0.85, 0.85)
	smat.roughness = 0.85
	shop.material_override = smat
	parent.add_child(shop)
