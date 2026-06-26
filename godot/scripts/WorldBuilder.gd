# WorldBuilder.gd — Builds the entire world: island city with districts
# Called by GameScene on ready
class_name WorldBuilder
extends RefCounted

# ============================================================
# MAP DESIGN (D.4 — Map Layout Redesign, v2)
# ============================================================
# Island city (~800×800m playable, water surrounds it).
# Chicago/Detroit-inspired: industrial vibe, harbor at waterfront,
# downtown with skyscrapers, slums, suburbs.
#
# Layout (top-down view, +X=East, +Z=South):
#
#              NORD (Wasser)
#         ~~~~~~~~~~~~~~~~~~~~~
#         |  INDUSTRIAL (NW)   |
#         |  -400..-150, -400..-100
#         |~~~~~~~~~~~~~~~~~~~~|
#         | SUBURBS | DOWNTOWN | HARBOR
#         |  (W)    | (CENTER) | (E, waterfront)
# WASSER  | -400..  | -150..   | +200..+400  WASSER
# (WEST)  | -150,   | +200,    | -300..+300  (OST)
#         | -100..  | -150..   | water at
#         | +250    | +200     | x>+350
#         |~~~~~~~~~|~~~~~~~~~~|
#         | SLUMS (SW)         |
#         | -400..-150, +200..+400
#         ~~~~~~~~~~~~~~~~~~~~~
#              SÜD (Wasser)
#
# District polygons define boundaries (Vector2 array, x/z coords).
# All districts are flat (y=0) for clean building placement.

const MAP_SIZE: float = 800.0           # playable area (-400..+400)
const WATER_OFFSET: float = 400.0       # water starts at this distance from center
const WATER_PLANE_SIZE: float = 1600.0  # large enough to look infinite

# District definitions (built at runtime via _init_districts)
static var DISTRICTS: Dictionary = {}

static func _init_districts() -> void:
	if not DISTRICTS.is_empty():
		return
	DISTRICTS = {
		"downtown": {
			"color": "#475569", "height_min": 24, "height_max": 80, "ground": "#1a1a1a",
			"polygon": PackedVector2Array([
				Vector2(-200, -150), Vector2(200, -150), Vector2(200, 200), Vector2(-200, 200)
			])
		},
		"harbor": {
			"color": "#1c1917", "height_min": 8, "height_max": 22, "ground": "#171717",
			"polygon": PackedVector2Array([
				Vector2(200, -300), Vector2(400, -300), Vector2(400, 300),
				Vector2(350, 300), Vector2(350, -200), Vector2(200, -200), Vector2(200, 200), Vector2(250, 200)
			])
		},
		"slums": {
			"color": "#451a03", "height_min": 5, "height_max": 14, "ground": "#1a0f0a",
			"polygon": PackedVector2Array([
				Vector2(-400, 200), Vector2(-150, 200), Vector2(-150, 400), Vector2(-400, 400)
			])
		},
		"industrial": {
			"color": "#1f2937", "height_min": 9, "height_max": 24, "ground": "#161616",
			"polygon": PackedVector2Array([
				Vector2(-400, -400), Vector2(-150, -400), Vector2(-150, -100), Vector2(-400, -100)
			])
		},
		"suburbs": {
			"color": "#525252", "height_min": 4, "height_max": 9, "ground": "#1a2a1a",
			"polygon": PackedVector2Array([
				# West suburbs (between industrial and slums)
				Vector2(-400, -100), Vector2(-150, -100), Vector2(-150, 200), Vector2(-400, 200)
			])
		},
		"rural": {
			"color": "#6b5b4a", "height_min": 3, "height_max": 6, "ground": "#2a3a1a",
			# Rural is the rest of the island (between districts and water edge)
			"polygon": PackedVector2Array([])
		},
	}

# ============================================================
# SCHEME BUILDINGS — placed at thematic spots per district
# ============================================================

const SCHEME_BUILDINGS: Array = [
	# Downtown — financial/entertainment district (center)
	{"id": "trading", "name": "Trading Floor", "emoji": "📈",
	 "x": -100, "z": -50, "w": 14, "d": 12, "h": 42, "color": "#22d3ee"},
	{"id": "wirefraud", "name": "Corporate Tower", "emoji": "💸",
	 "x": 100, "z": -80, "w": 18, "d": 16, "h": 80, "color": "#64748b"},
	{"id": "taxfraud", "name": "Accountant Office", "emoji": "🧾",
	 "x": -150, "z": 50, "w": 12, "d": 10, "h": 24, "color": "#eab308"},
	{"id": "gambling", "name": "Casino", "emoji": "🎰",
	 "x": 120, "z": 100, "w": 16, "d": 14, "h": 14, "color": "#f59e0b"},
	# Slums — drugs/scam/robbery (SW)
	{"id": "drugs", "name": "Trap House", "emoji": "💊",
	 "x": -300, "z": 280, "w": 10, "d": 9, "h": 9, "color": "#a855f7"},
	{"id": "scam", "name": "Internet Cafe", "emoji": "🎣",
	 "x": -250, "z": 330, "w": 9, "d": 8, "h": 7, "color": "#ec4899"},
	{"id": "robbery", "name": "Corner Store", "emoji": "🔫",
	 "x": -330, "z": 350, "w": 8, "d": 8, "h": 5, "color": "#ef4444"},
	# Industrial — e-com warehouse (NW)
	{"id": "ecom", "name": "E-Com Warehouse", "emoji": "📦",
	 "x": -280, "z": -250, "w": 16, "d": 14, "h": 11, "color": "#4ade80"},
]

# ============================================================
# District lookup (polygon-based)
# ============================================================

static func get_district_at(x: float, z: float) -> String:
	_init_districts()
	var point = Vector2(x, z)
	# Check each district polygon
	for district_name in ["downtown", "harbor", "slums", "industrial", "suburbs"]:
		var district = DISTRICTS[district_name]
		var polygon = district.get("polygon", PackedVector2Array())
		if polygon.size() >= 3 and Geometry2D.is_point_in_polygon(point, polygon):
			return district_name
	# Everything else on the island is rural
	var r = sqrt(x * x + z * z)
	if r < WATER_OFFSET:
		return "rural"
	# Beyond water offset = water (no district)
	return "water"

# ============================================================
# Terrain height (flat city, hills at edge)
# ============================================================

static func terrain_height(x: float, z: float) -> float:
	var r = sqrt(x * x + z * z)
	# Completely flat for the playable city area (within ±350)
	if r < 350:
		return 0.0
	# Gentle hills at the island edges (rural zone, before water)
	if r < WATER_OFFSET:
		var blend = (r - 350) / (WATER_OFFSET - 350)
		return _fractal_noise(x, z, 2) * 8 * blend
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
# Terrain (flat island)
# ============================================================

static func _build_terrain(parent: Node3D) -> void:
	var size = 900  # slightly larger than playable area
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
		var r = sqrt(v.x * v.x + v.z * v.z)
		var col: Color
		if h < -1:
			# Water
			col = Color(0.08, 0.18, 0.32)
		elif r > 350:
			# Rural edge (green/dirt)
			col = Color(0.32, 0.38, 0.22)
		else:
			# District-based color
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
				_:
					col = Color(0.18, 0.20, 0.18)
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
	
	# === COLLISION: Multi-part system ===
	# 1) City ground (flat BoxShape3D covering the city area)
	var city_body = StaticBody3D.new()
	city_body.name = "CityGround"
	var city_col = CollisionShape3D.new()
	var city_shape = BoxShape3D.new()
	city_shape.size = Vector3(900, 1.0, 900)  # 900x900 flat ground at y=-0.5
	city_col.shape = city_shape
	city_col.position = Vector3(0, -0.5, 0)
	city_body.add_child(city_col)
	parent.add_child(city_body)
	
	# 2) Mountain walls (N and S) - tall boxes that block vehicle passage
	# North mountain wall (z < -400)
	var north_body = StaticBody3D.new()
	north_body.name = "MountainNorth"
	var north_col = CollisionShape3D.new()
	var north_shape = BoxShape3D.new()
	north_shape.size = Vector3(1200, 80, 200)  # 1200 wide, 80 tall, 200 deep
	north_col.shape = north_shape
	north_col.position = Vector3(0, 40, -500)  # centered at z=-500, 40 high
	north_body.add_child(north_col)
	parent.add_child(north_body)
	# South mountain wall (z > 400)
	var south_body = StaticBody3D.new()
	south_body.name = "MountainSouth"
	var south_col = CollisionShape3D.new()
	var south_shape = BoxShape3D.new()
	south_shape.size = Vector3(1200, 80, 200)
	south_col.shape = south_shape
	south_col.position = Vector3(0, 40, 500)
	south_body.add_child(south_col)
	parent.add_child(south_body)
	# West mountain wall (x < -400)
	var west_body = StaticBody3D.new()
	west_body.name = "MountainWest"
	var west_col = CollisionShape3D.new()
	var west_shape = BoxShape3D.new()
	west_shape.size = Vector3(200, 80, 1200)
	west_col.shape = west_shape
	west_col.position = Vector3(-500, 40, 0)
	west_body.add_child(west_col)
	parent.add_child(west_body)
	# East harbor wall (water barrier at x > 400) - lower, blocks ground vehicles
	var east_body = StaticBody3D.new()
	east_body.name = "HarborBarrier"
	var east_col = CollisionShape3D.new()
	var east_shape = BoxShape3D.new()
	east_shape.size = Vector3(50, 3, 1200)  # low wall, blocks cars but visible over
	east_col.shape = east_shape
	east_col.position = Vector3(425, 1.5, 0)  # at x=425, 1.5 high
	east_body.add_child(east_col)
	parent.add_child(east_body)
	
	parent.add_child(mi)

# ============================================================
# Water (surrounds the island)
# ============================================================

static func _build_water(parent: Node3D) -> void:
	# Large water plane centered at origin, surrounds the island
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
	mi.position = Vector3(0, -3.0, 0)  # below the island surface
	parent.add_child(mi)

# ============================================================
# Roads (Chicago grid with main avenues)
# ============================================================

const ROAD_HALF_MAIN = 8.0    # 4-lane main avenue (16m wide)
const ROAD_HALF_SIDE = 5.5    # 2-lane side street (11m wide)
const SIDEWALK = 3.0

static func _build_roads(parent: Node3D) -> void:
	# Main avenues (4-lane) cross at the city center
	# East-West main roads at z = -100, z = +100
	# North-South main roads at x = -100, x = +100
	for pos in [-100, 100]:
		_make_road(parent, "x", pos, ROAD_HALF_MAIN, SIDEWALK, true)
		_make_road(parent, "z", pos, ROAD_HALF_MAIN, SIDEWALK, true)
	
	# Secondary streets (2-lane) every 50m in the city grid
	for p in range(-300, 301, 50):
		if abs(p) == 100:
			continue  # already done as main avenue
		if abs(p) > 350:
			continue  # outside city
		_make_road(parent, "x", p, ROAD_HALF_SIDE, SIDEWALK, false)
		_make_road(parent, "z", p, ROAD_HALF_SIDE, SIDEWALK, false)

static func _make_road(parent: Node3D, axis: String, pos: float, half_w: float, sw: float, _is_main: bool):
	var length = 720.0  # slightly less than map size to fit island
	# Asphalt
	var asphalt = MeshInstance3D.new()
	var a_mesh = BoxMesh.new()
	if axis == "x":
		a_mesh.size = Vector3(length, 0.02, half_w * 2)
		asphalt.position = Vector3(0, 0.02, pos)
	else:
		a_mesh.size = Vector3(half_w * 2, 0.02, length)
		asphalt.position = Vector3(pos, 0.02, 0)
	asphalt.mesh = a_mesh
	var amat = StandardMaterial3D.new()
	amat.albedo_color = Color(0.09, 0.09, 0.09)
	amat.roughness = 0.95
	asphalt.material_override = amat
	parent.add_child(asphalt)
	
	# Sidewalks
	if sw > 0:
		for side in [-1, 1]:
			var sidewalk = MeshInstance3D.new()
			var s_mesh = BoxMesh.new()
			if axis == "x":
				s_mesh.size = Vector3(length, 0.06, sw)
				sidewalk.position = Vector3(0, 0.03, pos + side * (half_w + sw / 2))
			else:
				s_mesh.size = Vector3(sw, 0.06, length)
				sidewalk.position = Vector3(pos + side * (half_w + sw / 2), 0.03, 0)
			sidewalk.mesh = s_mesh
			var smat = StandardMaterial3D.new()
			smat.albedo_color = Color(0.23, 0.23, 0.23)
			smat.roughness = 0.9
			sidewalk.material_override = smat
			parent.add_child(sidewalk)
	
	# Center line markings (dashed yellow on main avenues)
	if _is_main:
		var dash_spacing = 4.0
		var count = int(length / dash_spacing)
		for i in count:
			var t = (i - (count - 1) / 2.0) * dash_spacing
			var dash = MeshInstance3D.new()
			var d_mesh = BoxMesh.new()
			if axis == "x":
				d_mesh.size = Vector3(2.0, 0.01, 0.2)
				dash.position = Vector3(t, 0.04, pos)
			else:
				d_mesh.size = Vector3(0.2, 0.01, 2.0)
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
# Filler buildings (density per district)
# ============================================================

static func _build_filler_buildings(parent: Node3D) -> void:
	# Place buildings on a grid, skipping roads and scheme-building areas
	# Dense layout: 15m grid (was 25m), smaller gaps, bigger buildings
	var grid = 15  # 15m grid spacing (denser than 25m)
	var half = 380  # cover city area
	for gx in range(-half, half + 1, grid):
		for gz in range(-half, half + 1, grid):
			var cx = gx + grid / 2.0
			var cz = gz + grid / 2.0
			var r = sqrt(cx * cx + cz * cz)
			if r > 390:
				continue  # outside city
			if _is_on_road(cx, cz):
				continue
			# Skip near scheme buildings
			var too_close = false
			for b in SCHEME_BUILDINGS:
				if sqrt((cx - b.x) ** 2 + (cz - b.z) ** 2) < max(b.w, b.d) / 2 + 4:
					too_close = true
					break
			if too_close:
				continue
			
			var dist_id = get_district_at(cx, cz)
			if dist_id == "water" or dist_id == "rural":
				continue  # no filler buildings in water/rural
			
			# Hash-based random for deterministic placement
			var seed_val = abs((gx * 73856093) ^ (gz * 19349663)) % 99991
			var rng = func(salt): return float((seed_val * (salt + 1) * 9301 + 49297) % 233280) / 233280
			
			# Gap chance — REDUCED for higher density
			var gap = 0.10
			match dist_id:
				"downtown": gap = 0.05  # very dense (was 0.10)
				"harbor": gap = 0.25    # (was 0.40)
				"slums": gap = 0.10     # (was 0.20)
				"industrial": gap = 0.20  # (was 0.30)
				"suburbs": gap = 0.35   # (was 0.50)
			if rng.call(99) < gap:
				continue
			
			# Building dimensions per district — BIGGER for better fill
			var w: float
			var d: float
			var h: float
			var dist = DISTRICTS[dist_id]
			if dist_id == "downtown":
				w = 10 + rng.call(1) * 4  # 10-14m (was 12-20)
				d = 9 + rng.call(2) * 4
				h = dist.height_min + rng.call(3) * (dist.height_max - dist.height_min)
			elif dist_id == "industrial":
				w = 11 + rng.call(1) * 4
				d = 10 + rng.call(2) * 4
				h = dist.height_min + rng.call(3) * (dist.height_max - dist.height_min)
			elif dist_id == "harbor":
				w = 12 + rng.call(1) * 4
				d = 11 + rng.call(2) * 4
				h = dist.height_min + rng.call(3) * (dist.height_max - dist.height_min)
			elif dist_id == "slums":
				w = 7 + rng.call(1) * 4
				d = 6 + rng.call(2) * 4
				h = dist.height_min + rng.call(3) * (dist.height_max - dist.height_min)
			else:  # suburbs
				w = 7 + rng.call(1) * 3
				d = 6 + rng.call(2) * 3
				h = dist.height_min + rng.call(3) * (dist.height_max - dist.height_min)
			
			# Offset within grid cell (small, to fill the cell tightly)
			var margin = 1.0
			var max_off = max(0, (grid - w - margin * 2) / 2)
			var ox = (rng.call(4) - 0.5) * max_off
			var oz = (rng.call(5) - 0.5) * max_off
			var fx = cx + ox
			var fz = cz + oz
			
			# Skip if corners overlap road
			if _is_on_road(fx - w / 2, fz - d / 2) or _is_on_road(fx + w / 2, fz + d / 2):
				continue
			if _is_on_road(fx - w / 2, fz + d / 2) or _is_on_road(fx + w / 2, fz - d / 2):
				continue
			
			# Build it
			var mesh = MeshInstance3D.new()
			var f_mesh = BoxMesh.new()
			f_mesh.size = Vector3(w, h, d)
			mesh.mesh = f_mesh
			mesh.position = Vector3(fx, h / 2, fz)
			var mat = StandardMaterial3D.new()
			# Color palette per district
			var palette: Array
			match dist_id:
				"downtown":
					palette = ["#475569", "#334155", "#1e293b", "#64748b", "#3f3f46"]
				"harbor":
					palette = ["#1c1917", "#292524", "#44403c", "#1f2937"]
				"slums":
					palette = ["#7c2d12", "#9a3412", "#451a03", "#1c1917", "#57534e"]
				"industrial":
					palette = ["#3f3f46", "#525252", "#27272a", "#404040"]
				_:
					palette = ["#525252", "#737373", "#404040", "#a3a3a3"]
			mat.albedo_color = Color.from_string(palette[int(rng.call(6) * palette.size()) % palette.size()], Color.GRAY)
			mat.roughness = 0.85
			mesh.material_override = mat
			parent.add_child(mesh)
			
			# Collision
			var body = StaticBody3D.new()
			body.position = Vector3(fx, h / 2, fz)
			var col = CollisionShape3D.new()
			var shape = BoxShape3D.new()
			shape.size = Vector3(w, h, d)
			col.shape = shape
			body.add_child(col)
			parent.add_child(body)

static func _is_on_road(x: float, z: float) -> bool:
	# Main avenues at ±100
	for pos in [-100, 100]:
		if abs(z - pos) < ROAD_HALF_MAIN + SIDEWALK and abs(x) < 360:
			return true
		if abs(x - pos) < ROAD_HALF_MAIN + SIDEWALK and abs(z) < 360:
			return true
	# Secondary streets every 50m
	for p in range(-300, 301, 50):
		if p == -100 or p == 100:
			continue
		if abs(z - p) < ROAD_HALF_SIDE + SIDEWALK and abs(x) < 360:
			return true
		if abs(x - p) < ROAD_HALF_SIDE + SIDEWALK and abs(z) < 360:
			return true
	return false

# ============================================================
# Harbor dock props (cranes, containers)
# ============================================================

static func _build_dock_props(parent: Node3D) -> void:
	# Place cargo containers in the harbor district
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
		# Stack containers
		var stack_h = int(randf() * 3) * 2.6
		container.position = Vector3(x, 1.3 + stack_h, z)
		var mat = StandardMaterial3D.new()
		var colors = ["#dc2626", "#2563eb", "#16a34a", "#eab308", "#ea580c", "#7c3aed"]
		mat.albedo_color = Color.from_string(colors[randi() % colors.size()], Color.GRAY)
		mat.roughness = 0.7
		container.material_override = mat
		parent.add_child(container)
	
	# Cranes at the dock edge
	for i in range(4):
		var x = 380
		var z = -200 + i * 130
		var crane = _make_crane()
		crane.position = Vector3(x, 0, z)
		parent.add_child(crane)

static func _make_crane() -> Node3D:
	var root = Node3D.new()
	# Base
	var base = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(4, 2, 4)
	base.mesh = b_mesh
	base.position = Vector3(0, 1, 0)
	var bmat = StandardMaterial3D.new()
	bmat.albedo_color = Color(0.95, 0.4, 0.1)
	bmat.roughness = 0.7
	base.material_override = bmat
	root.add_child(base)
	# Tower
	var tower = MeshInstance3D.new()
	var t_mesh = BoxMesh.new()
	t_mesh.size = Vector3(2, 25, 2)
	tower.mesh = t_mesh
	tower.position = Vector3(0, 14.5, 0)
	tower.material_override = bmat
	root.add_child(tower)
	# Horizontal arm
	var arm = MeshInstance3D.new()
	var a_mesh = BoxMesh.new()
	a_mesh.size = Vector3(20, 1.5, 1.5)
	arm.mesh = a_mesh
	arm.position = Vector3(8, 25, 0)
	arm.material_override = bmat
	root.add_child(arm)
	return root

# ============================================================
# Street lamps
# ============================================================

static func _build_street_lamps(parent: Node3D) -> void:
	var positions = [
		Vector3(-110, 0, -50), Vector3(110, 0, -50), Vector3(-110, 0, 50), Vector3(110, 0, 50),
		Vector3(-50, 0, -110), Vector3(50, 0, -110), Vector3(-50, 0, 110), Vector3(50, 0, 110),
		Vector3(-150, 0, 0), Vector3(150, 0, 0), Vector3(0, 0, -150), Vector3(0, 0, 150),
		# Slums lamps
		Vector3(-200, 0, 250), Vector3(-300, 0, 280), Vector3(-250, 0, 330),
		# Harbor lamps
		Vector3(220, 0, -100), Vector3(280, 0, 0), Vector3(220, 0, 100),
		# Industrial lamps
		Vector3(-250, 0, -200), Vector3(-300, 0, -300),
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
# Landmarks (visual points of interest)
# ============================================================

static func _build_landmarks(parent: Node3D) -> void:
	# 1. Central Park (large green area in downtown-south)
	_park(parent, -50, 100, 80, 50)
	# 2. Skyline / Skyscraper row (3 tall towers in downtown-east)
	_skyscraper(parent, 150, -100, 12, 90, "#1e293b")
	_skyscraper(parent, 175, -100, 12, 110, "#0f172a")
	_skyscraper(parent, 200, -100, 12, 95, "#1e293b")
	# 3. Bridge connecting harbor piers
	_bridge(parent, 250, 0, 0)  # bridge at harbor entrance
	# 4. Fortress on west hill (rural area, visible from far)
	_fortress(parent, -300, -300)
	# 5. Stadium (in industrial/suburbs border)
	_stadium(parent, -250, 100)
	# 6. Church tower in downtown center
	_church_tower(parent, 0, 0)
	# 7. Bus station (downtown-east, near main avenue)
	_bus_station(parent, 100, 150)
	# 8. Gas station (industrial, near highway)
	_gas_station(parent, -200, -200)
	_gas_station(parent, 200, 200)  # second one in slums/harbor border

static func _park(parent: Node3D, x: float, z: float, w: float, d: float) -> void:
	# Green park area with trees
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
	# Trees scattered in park
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
	# Emissive windows look
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.5, 0.6)
	mat.emission_energy_multiplier = 0.15
	mesh.material_override = mat
	parent.add_child(mesh)
	# Collision
	var body = StaticBody3D.new()
	body.position = Vector3(x, h / 2, z)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(w, h, w)
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)

static func _bridge(parent: Node3D, x: float, z: float, _rot: float) -> void:
	# Bridge spanning harbor entrance
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
	# Suspension towers
	for tx in [x - 25, x + 25]:
		var tower = MeshInstance3D.new()
		var t_mesh = BoxMesh.new()
		t_mesh.size = Vector3(2, 12, 2)
		tower.mesh = t_mesh
		tower.position = Vector3(tx, 6, z)
		tower.material_override = dmat
		parent.add_child(tower)

static func _fortress(parent: Node3D, x: float, z: float) -> void:
	# Stone fortress on a hill
	var stone = StandardMaterial3D.new()
	stone.albedo_color = Color(0.45, 0.4, 0.35)
	stone.roughness = 0.95
	# Main keep
	var keep = MeshInstance3D.new()
	var k_mesh = BoxMesh.new()
	k_mesh.size = Vector3(15, 18, 15)
	keep.mesh = k_mesh
	keep.position = Vector3(x, 9, z)
	keep.material_override = stone
	parent.add_child(keep)
	# Corner towers
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
	# Oval stadium — represented as a ring of boxes
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
	# Tall church tower in downtown
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.8, 0.7)
	mat.roughness = 0.9
	# Tower base
	var base = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(8, 30, 8)
	base.mesh = b_mesh
	base.position = Vector3(x, 15, z)
	base.material_override = mat
	parent.add_child(base)
	# Spire on top
	var spire = MeshInstance3D.new()
	var s_mesh = PrismMesh.new()
	s_mesh.size = Vector3(6, 12, 6)
	spire.mesh = s_mesh
	spire.position = Vector3(x, 36, z)
	spire.material_override = mat
	parent.add_child(spire)

static func _bus_station(parent: Node3D, x: float, z: float) -> void:
	# Flat-roof bus station building
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
	# Sign
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
	# Small gas station with canopy
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
	# Canopy supports
	for sx in [x - 5, x + 5]:
		for sz in [z - 3, z + 3]:
			var post = MeshInstance3D.new()
			var p_mesh = BoxMesh.new()
			p_mesh.size = Vector3(0.3, 5, 0.3)
			post.mesh = p_mesh
			post.position = Vector3(sx, 2.5, sz)
			post.material_override = cmat
			parent.add_child(post)
	# Small shop building
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
