# WorldBuilder.gd — NYC-inspired city map with clear zone separation
# Called by GameScene on ready
class_name WorldBuilder
extends RefCounted

# ============================================================
# KÜSTENSTADT MAP DESIGN (D.4.5a)
# ============================================================
# Coastal city, 3000×3000m playable area.
# Water in East (harbor/ocean), Canyon walls in West/North/South.
#
# Layout (East → West, Küstenstreifen):
#   HARBOR (East, +600..+1500) → DOWNTOWN (+100..+800) →
#   INDUSTRIAL (-600..+200) → SUBURBS (-1000..-400) →
#   RURAL (-1500..-800, with mountains/forests)
#
# District borders: River (Downtown↔Harbor), Park (Industrial↔Downtown),
#   Highway (Suburbs↔Industrial), Elevation+Forest (Rural↔Suburbs)
# Slums: Container-slum south of Downtown/Industrial border
# Mountains: Canyon walls (80-120m, steep) at North/South/West edges

const MAP_SIZE: float = 2500.0          # playable area (-1250..+1250)
const WATER_OFFSET: float = 1250.0      # sea starts beyond island edge
const WATER_PLANE_SIZE: float = 4000.0  # ocean (larger than island)

# Street grid — NYC Downtown only
const STREET_GRID: Array = [-200, -100, 0, 100, 200, 300]
const ROAD_HALF_WIDTH: float = 4.0       # Main Avenue: 8m wide (2 lanes)
const SIDEWALK_WIDTH: float = 2.5       # 2.5m sidewalk on each side
const SIDEWALK_HEIGHT: float = 0.15     # raised sidewalk (15cm curb)
const BLOCK_SIZE: float = 80.0          # 80m blocks in Downtown grid
const BUILDING_MARGIN: float = 0.5      # buildings flush with sidewalk

# Harbor constants (SE part of island)
const HARBOR_BASIN_X: float = 400.0     # harbor basin center X (SE area)
const HARBOR_BASIN_W: float = 200.0     # basin width
const HARBOR_BASIN_D: float = 300.0     # basin depth

# Heightmap (loaded from PNG, replaces procedural terrain_height)
static var _heightmap_img: Image = null
const HEIGHTMAP_PATH: String = "res://assets/heightmap.png"
const HEIGHTMAP_SIZE: int = 1024
const HEIGHTMAP_WORLD_SIZE: float = 2500.0
const HEIGHTMAP_MAX_HEIGHT: float = 120.0

static func _load_heightmap() -> void:
	if _heightmap_img != null:
		return
	var path = ProjectSettings.globalize_path(HEIGHTMAP_PATH)
	_heightmap_img = Image.load_from_file(path)
	if _heightmap_img == null:
		push_warning("Heightmap not found — using flat fallback")
	else:
		print("[WorldBuilder] Heightmap loaded: ", _heightmap_img.get_width(), "x", _heightmap_img.get_height())

# District definitions
static var DISTRICTS: Dictionary = {}

static func _init_districts() -> void:
	if not DISTRICTS.is_empty():
		return
	DISTRICTS = {
		"portofino": {
			"color": "#d4a574", "height_min": 8, "height_max": 20, "ground": "#8a7a5a",
			# Portofino: NE part of island (x > -50, z < 100)
			"polygon": PackedVector2Array([
				Vector2(-50, -800), Vector2(800, -800), Vector2(800, 100), Vector2(-50, 100)
			])
		},
		"nyc": {
			"color": "#1e293b", "height_min": 40, "height_max": 150, "ground": "#1a1a1a",
			# NYC Downtown: center of island (-200..+300 X, -300..+400 Z)
			"polygon": PackedVector2Array([
				Vector2(-200, -300), Vector2(300, -300), Vector2(300, 400), Vector2(-200, 400)
			])
		},
		"harbor": {
			"color": "#1c1917", "height_min": 8, "height_max": 20, "ground": "#171717",
			# Harbor: SE part of island (x > 100, z > 100)
			"polygon": PackedVector2Array([
				Vector2(100, 100), Vector2(800, 100), Vector2(800, 800), Vector2(100, 800)
			])
		},
		"slums_suburbs": {
			"color": "#5a4030", "height_min": 4, "height_max": 12, "ground": "#2a2a1a",
			# Slums/Suburbs: W/NW part of island (x < -100)
			"polygon": PackedVector2Array([
				Vector2(-800, -800), Vector2(-100, -800), Vector2(-100, 800), Vector2(-800, 800)
			])
		},
	}

# ============================================================
# SCHEME BUILDINGS — placed at clear positions within district blocks
# ============================================================

const SCHEME_BUILDINGS: Array = [
	# NYC Downtown (center) — tall skyscrapers (40-150m)
	{"id": "trading", "name": "Trading Floor", "emoji": "📈",
	 "x": 50, "z": -50, "w": 25, "d": 22, "h": 70, "color": "#22d3ee"},
	{"id": "wirefraud", "name": "Corporate Tower", "emoji": "💸",
	 "x": 150, "z": 50, "w": 30, "d": 25, "h": 120, "color": "#64748b"},
	{"id": "taxfraud", "name": "Accountant Office", "emoji": "🧾",
	 "x": -100, "z": 100, "w": 18, "d": 16, "h": 35, "color": "#eab308"},
	{"id": "gambling", "name": "Casino", "emoji": "🎰",
	 "x": 200, "z": -100, "w": 25, "d": 22, "h": 28, "color": "#f59e0b"},
	# Slums (W/NW) — container-slum buildings (4-8m)
	{"id": "drugs", "name": "Trap House", "emoji": "💊",
	 "x": -400, "z": 200, "w": 10, "d": 8, "h": 6, "color": "#a855f7"},
	{"id": "scam", "name": "Internet Cafe", "emoji": "🎣",
	 "x": -500, "z": 300, "w": 8, "d": 7, "h": 5, "color": "#ec4899"},
	{"id": "robbery", "name": "Corner Store", "emoji": "🔫",
	 "x": -350, "z": 350, "w": 7, "d": 7, "h": 4, "color": "#ef4444"},
	# NYC Downtown — large warehouse (15m)
	{"id": "ecom", "name": "E-Com Warehouse", "emoji": "📦",
	 "x": -50, "z": 200, "w": 25, "d": 22, "h": 15, "color": "#4ade80"},
]

# ============================================================
# District lookup (polygon-based)
# ============================================================

static func get_district_at(x: float, z: float) -> String:
	_init_districts()
	var point = Vector2(x, z)
	for district_name in ["portofino", "nyc", "harbor", "slums_suburbs"]:
		var district = DISTRICTS[district_name]
		var polygon = district.get("polygon", PackedVector2Array())
		if polygon.size() >= 3 and Geometry2D.is_point_in_polygon(point, polygon):
			return district_name
	# Off-island = sea
	return "sea"

# ============================================================
# Terrain height (island terrain from heightmap PNG)
# ============================================================

static func terrain_height(x: float, z: float) -> float:
	# Read height from heightmap PNG (generated by scripts/generate_heightmap.py)
	if _heightmap_img == null:
		_load_heightmap()
	if _heightmap_img != null:
		var px = int((x + HEIGHTMAP_WORLD_SIZE / 2.0) / HEIGHTMAP_WORLD_SIZE * float(_heightmap_img.get_width()))
		var pz = int((z + HEIGHTMAP_WORLD_SIZE / 2.0) / HEIGHTMAP_WORLD_SIZE * float(_heightmap_img.get_height()))
		px = clamp(px, 0, _heightmap_img.get_width() - 1)
		pz = clamp(pz, 0, _heightmap_img.get_height() - 1)
		return _heightmap_img.get_pixel(px, pz).r * HEIGHTMAP_MAX_HEIGHT
	return 0.0

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
	_load_heightmap()
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
# Terrain — island terrain from heightmap
# ============================================================

static func _build_terrain(parent: Node3D) -> void:
	# Visual terrain mesh with height variation
	var size = 3200  # 3000m playable + 100m margin  # larger terrain mesh for bigger map
	var segs = 150
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
				"nyc":
					col = Color(0.12, 0.12, 0.14)
				"harbor":
					col = Color(0.14, 0.14, 0.14)
				"slums_suburbs":
					col = Color(0.18, 0.12, 0.08)
				"harbor":
					col = Color(0.14, 0.15, 0.16)
				"portofino":
					col = Color(0.20, 0.30, 0.18)
				"sea":
					col = Color(0.25, 0.35, 0.18)  # green grass
				"canyon":
					col = Color(0.35, 0.30, 0.25)  # mountain rock
				_:
					col = Color(0.08, 0.18, 0.32)  # water
		mdt.set_vertex_color(i, col)
	
	var final_mesh = ArrayMesh.new()
	mdt.commit_to_surface(final_mesh)
	
	var mi = MeshInstance3D.new()
	mi.mesh = final_mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Lower terrain mesh by 0.05m to prevent z-fighting with asphalt (y=0.02)
	# and sidewalk (y=0.075) layers above it.
	mi.position.y = -0.05
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	# Disable depth write to prevent z-fighting with overlapping ground layers
	mi.material_override = mat
	
	# === COLLISION: terrain-following grid (60m cells) ===
	var terrain_body = StaticBody3D.new()
	terrain_body.name = "TerrainGround"
	var terrain_grid = 60
	for gx in range(-1300, 1301, terrain_grid):
		for gz in range(-1300, 1301, terrain_grid):
			if gx > 1250:
				continue
			# Skip deep water (handled by terrain_height returning negative)
			var h_at = terrain_height(gx, gz)
			if h_at < -1:
				continue
			var rcol = CollisionShape3D.new()
			var rshape = BoxShape3D.new()
			rshape.size = Vector3(terrain_grid, 1.0, terrain_grid)
			rcol.shape = rshape
			rcol.position = Vector3(gx, h_at - 0.5, gz)
			terrain_body.add_child(rcol)
	parent.add_child(terrain_body)
	
	# Mountain walls removed — island uses sea as border

	var east_body = StaticBody3D.new()
	east_body.name = "HarborBarrier"
	var east_col = CollisionShape3D.new()
	var east_shape = BoxShape3D.new()
	east_shape.size = Vector3(20, 4, 3600)
	east_col.shape = east_shape
	east_col.position = Vector3(1510, 2, 0)
	east_body.add_child(east_col)
	parent.add_child(east_body)
	
	parent.add_child(mi)

# ============================================================
# Water (east harbor)
# ============================================================

static func _build_water(parent: Node3D) -> void:
	# Sea on east side (harbor) + surrounding ocean
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
	mi.position = Vector3(3000, -3.0, 0)  # far east ocean, larger offset for bigger map
	parent.add_child(mi)

# ============================================================
# Roads — NYC grid with clear sidewalks
# ============================================================

static func _build_roads(parent: Node3D) -> void:
	# Streets at every position in STREET_GRID (every 100m)
	# Each street has: asphalt + 2 raised sidewalks (broken at intersections)
	# + lane markings + crosswalks at intersections
	for pos in STREET_GRID:
		# East-West street (along x-axis, at z=pos)
		_make_street(parent, "x", pos)
		# North-South street (along z-axis, at x=pos)
		_make_street(parent, "z", pos)
	# Add crosswalks at every intersection
	_build_crosswalks(parent)

static func _make_street(parent: Node3D, axis: String, pos: float) -> void:
	var length = 800.0  # spans NYC Downtown grid
	# === ASPHALT (street surface, full length — runs through intersections) ===
	var asphalt = MeshInstance3D.new()
	var a_mesh = BoxMesh.new()
	if axis == "x":
		a_mesh.size = Vector3(length, 0.04, ROAD_HALF_WIDTH * 2)
		asphalt.position = Vector3(0, terrain_height(0, pos) + 0.03, pos)  # raised to clear terrain (y=-0.05)
	else:
		a_mesh.size = Vector3(ROAD_HALF_WIDTH * 2, 0.04, length)
		asphalt.position = Vector3(pos, terrain_height(pos, 0) + 0.03, 0)
	asphalt.mesh = a_mesh
	var amat = StandardMaterial3D.new()
	amat.albedo_color = Color(0.08, 0.08, 0.08)  # dark asphalt
	amat.roughness = 0.95
	asphalt.material_override = amat
	parent.add_child(asphalt)
	
	# === SIDEWALKS (raised, on both sides, BROKEN at intersections) ===
	# At each cross-street position, the sidewalk is interrupted so it doesn't
	# run through the intersection. The gap is filled by a crosswalk (zebra).
	for side in [-1, 1]:
		# Build sidewalk in segments between intersections
		var prev_pos = -length / 2
		for cross_pos in STREET_GRID:
			# Segment from prev_pos to (cross_pos - ROAD_HALF_WIDTH - SIDEWALK_WIDTH)
			var seg_end = cross_pos - ROAD_HALF_WIDTH - SIDEWALK_WIDTH
			var seg_start = prev_pos
			var seg_len = seg_end - seg_start
			if seg_len > 1:
				_make_sidewalk_segment(parent, axis, pos, side, seg_start, seg_len)
			# Update prev_pos to skip the intersection gap
			prev_pos = cross_pos + ROAD_HALF_WIDTH + SIDEWALK_WIDTH
		# Last segment after final cross street
		var seg_start = prev_pos
		var seg_len = (length / 2) - seg_start
		if seg_len > 1:
			_make_sidewalk_segment(parent, axis, pos, side, seg_start, seg_len)
	
	# === LANE MARKINGS (dashed yellow center line, BROKEN at intersections) ===
	var dash_spacing = 5.0
	for cross_idx in range(STREET_GRID.size()):
		var cross_start = -length / 2 if cross_idx == 0 else STREET_GRID[cross_idx - 1] + ROAD_HALF_WIDTH + 1
		var cross_end = STREET_GRID[cross_idx] - ROAD_HALF_WIDTH - 1
		if cross_idx == STREET_GRID.size() - 1:
			cross_end = length / 2
		else:
			# Will continue in next iteration
			pass
		# Draw dashes from cross_start to cross_end
		var seg_len = cross_end - cross_start
		if seg_len > 1:
			var count = int(seg_len / dash_spacing)
			for i in count:
				var t = cross_start + (i + 0.5) * dash_spacing
				if t > cross_end:
					break
				_make_dash(parent, axis, pos, t)

static func _make_sidewalk_segment(parent: Node3D, axis: String, pos: float,
		side: int, seg_start: float, seg_len: float) -> void:
	# Center of segment along the street direction
	var seg_center = seg_start + seg_len / 2
	var sidewalk = MeshInstance3D.new()
	var s_mesh = BoxMesh.new()
	var sx: float
	var sz: float
	if axis == "x":
		s_mesh.size = Vector3(seg_len, SIDEWALK_HEIGHT, SIDEWALK_WIDTH)
		sx = seg_center
		sz = pos + side * (ROAD_HALF_WIDTH + SIDEWALK_WIDTH / 2)
		sidewalk.position = Vector3(sx, SIDEWALK_HEIGHT / 2, sz)
	else:
		s_mesh.size = Vector3(SIDEWALK_WIDTH, SIDEWALK_HEIGHT, seg_len)
		sx = pos + side * (ROAD_HALF_WIDTH + SIDEWALK_WIDTH / 2)
		sz = seg_center
		sidewalk.position = Vector3(sx, SIDEWALK_HEIGHT / 2, sz)
	sidewalk.mesh = s_mesh
	var smat = StandardMaterial3D.new()
	smat.albedo_color = Color(0.55, 0.55, 0.55)
	smat.roughness = 0.9
	sidewalk.material_override = smat
	parent.add_child(sidewalk)
	# COLLISION: StaticBody3D with LOW collision height (5cm)
	# Visual sidewalk is 15cm tall, but collision is only 5cm — small enough
	# for floor_snap (0.5m) to reliably pull cars/players up onto it.
	# This avoids the need for ramps or slope collision shapes.
	var collision_height = 0.05  # 5cm collision (visual stays 15cm)
	var body = StaticBody3D.new()
	body.position = Vector3(sx, collision_height / 2, sz)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	if axis == "x":
		shape.size = Vector3(seg_len, collision_height, SIDEWALK_WIDTH)
	else:
		shape.size = Vector3(SIDEWALK_WIDTH, collision_height, seg_len)
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)

static func _make_dash(parent: Node3D, axis: String, pos: float, t: float) -> void:
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

static func _build_crosswalks(parent: Node3D) -> void:
	# At each intersection, add: 4 crosswalks + 4 corner sidewalk pieces
	for x_pos in STREET_GRID:
		for z_pos in STREET_GRID:
			# 4 crosswalks (zebra stripes) — one per street leg
			_make_crosswalk(parent, x_pos, z_pos - ROAD_HALF_WIDTH - 1.5, "x")  # north
			_make_crosswalk(parent, x_pos, z_pos + ROAD_HALF_WIDTH + 1.5, "x")  # south
			_make_crosswalk(parent, x_pos - ROAD_HALF_WIDTH - 1.5, z_pos, "z")  # west
			_make_crosswalk(parent, x_pos + ROAD_HALF_WIDTH + 1.5, z_pos, "z")  # east
			# 4 corner sidewalk pieces (fill the gaps at intersection corners)
			for cx_sign in [-1, 1]:
				for cz_sign in [-1, 1]:
					var corner_x = x_pos + cx_sign * (ROAD_HALF_WIDTH + SIDEWALK_WIDTH / 2)
					var corner_z = z_pos + cz_sign * (ROAD_HALF_WIDTH + SIDEWALK_WIDTH / 2)
					_make_sidewalk_corner(parent, corner_x, corner_z)

static func _make_sidewalk_corner(parent: Node3D, x: float, z: float) -> void:
	# Square sidewalk piece at intersection corner (fills gap between
	# the two perpendicular sidewalks that were broken at intersection)
	var corner = MeshInstance3D.new()
	var c_mesh = BoxMesh.new()
	c_mesh.size = Vector3(SIDEWALK_WIDTH, SIDEWALK_HEIGHT, SIDEWALK_WIDTH)
	corner.mesh = c_mesh
	corner.position = Vector3(x, SIDEWALK_HEIGHT / 2, z)
	var smat = StandardMaterial3D.new()
	smat.albedo_color = Color(0.55, 0.55, 0.55)
	smat.roughness = 0.9
	corner.material_override = smat
	parent.add_child(corner)
	# COLLISION: StaticBody3D with LOW collision height (5cm, matches segments)
	var collision_height = 0.05
	var body = StaticBody3D.new()
	body.position = Vector3(x, collision_height / 2, z)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(SIDEWALK_WIDTH, collision_height, SIDEWALK_WIDTH)
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)

static func _make_crosswalk(parent: Node3D, x: float, z: float, axis: String) -> void:
	# Zebra stripes: white bars across the FULL width of the street
	var stripe_width = 0.6  # wider stripes (more visible)
	var stripe_count = 6    # fewer stripes, more spacing
	var stripe_length = ROAD_HALF_WIDTH * 2 - 0.5  # spans almost full street width
	var stripe_spacing = 0.8  # space between stripes along crosswalk direction
	for i in range(stripe_count):
		var offset = (i - (stripe_count - 1) / 2.0) * stripe_spacing
		var stripe = MeshInstance3D.new()
		var s_mesh = BoxMesh.new()
		if axis == "x":
			# Crosswalk runs east-west (along x), stripes perpendicular (along z)
			s_mesh.size = Vector3(stripe_width, 0.02, stripe_length)
			stripe.position = Vector3(x + offset, 0.05, z)
		else:
			# Crosswalk runs north-south (along z), stripes perpendicular (along x)
			s_mesh.size = Vector3(stripe_length, 0.02, stripe_width)
			stripe.position = Vector3(x, 0.05, z + offset)
		stripe.mesh = s_mesh
		var smat = StandardMaterial3D.new()
		smat.albedo_color = Color(0.95, 0.95, 0.95)  # white
		smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		stripe.material_override = smat
		parent.add_child(stripe)

# ============================================================
# Scheme buildings (8 thematic spots)
# ============================================================

static func _build_scheme_buildings(parent: Node3D) -> void:
	for b in SCHEME_BUILDINGS:
		var mesh = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()
		b_mesh.size = Vector3(b.w, b.h, b.d)
		mesh.mesh = b_mesh
		mesh.position = Vector3(b.x, terrain_height(b.x, b.z) + b.h / 2.0, b.z)
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
		body.position = Vector3(b.x, terrain_height(b.x, b.z) + b.h / 2.0, b.z)
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(b.w, b.h, b.d)
		col.shape = shape
		body.add_child(col)
		parent.add_child(body)
		
		# Label
		var label = Label3D.new()
		label.text = "%s %s" % [b.emoji, b.name]
		label.position = Vector3(b.x, terrain_height(b.x, b.z) + b.h + 2, b.z)
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
	var block_centers = [-150, -50, 50, 150, 250]  # NYC Downtown grid
	
	for bx in block_centers:
		for bz in block_centers:
			_build_block(parent, bx, bz)

static func _build_block(parent: Node3D, bx: float, bz: float) -> void:
	# District at block center
	var dist_id = get_district_at(bx, bz)
	if dist_id == "sea" or dist_id == "portofino":
		return  # no buildings in sea/portofino
	
	# Block bounds (BLOCK_SIZE wide, with sidewalk + margin subtracted)
	var road_buffer = ROAD_HALF_WIDTH + SIDEWALK_WIDTH + BUILDING_MARGIN
	var block_inner = BLOCK_SIZE - 2 * road_buffer  # ~70m for 80m block
	if block_inner < 10:
		return
	
	var bx_min = bx - block_inner / 2
	var bz_min = bz - block_inner / 2
	
	# Number of buildings per block depends on district
	var buildings_per_side: int
	match dist_id:
		"nyc":
			buildings_per_side = 2  # 2x2 = 4 large towers per block
		"harbor":
			buildings_per_side = 2  # 2x2 = 4 medium factories
		"harbor":
			buildings_per_side = 2  # 2x2 = 4 warehouses
		"slums_suburbs":
			buildings_per_side = 3  # 3x3 = 9 small houses (dense slums)
		"portofino":
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
				"nyc": skip = 0.10
				"harbor": skip = 0.25
				"slums_suburbs": skip = 0.10
				"harbor": skip = 0.20
				"portofino": skip = 0.35
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
				"nyc":
					w = min(max_w, 25 + rng.call(ix + 1) * 10)
					d = min(max_d, 22 + rng.call(iz + 1) * 10)
					h = dist.height_min + rng.call(ix + iz + 1) * (dist.height_max - dist.height_min)
				"harbor":
					w = min(max_w, 25 + rng.call(ix + 1) * 8)
					d = min(max_d, 22 + rng.call(iz + 1) * 8)
					h = dist.height_min + rng.call(ix + iz + 1) * (dist.height_max - dist.height_min)
				"harbor":
					w = min(max_w, 25 + rng.call(ix + 1) * 8)
					d = min(max_d, 22 + rng.call(iz + 1) * 8)
					h = dist.height_min + rng.call(ix + iz + 1) * (dist.height_max - dist.height_min)
				"slums_suburbs":
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
		"nyc":
			# Tall glass skyscraper — emissive blue windows
			var b_mesh = BoxMesh.new()
			b_mesh.size = Vector3(w, h, d)
			mesh.mesh = b_mesh
			mesh.position = Vector3(x, terrain_height(x, z) + h / 2, z)
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
			mesh.position = Vector3(x, terrain_height(x, z) + h / 2, z)
			var mat = StandardMaterial3D.new()
			var colors = ["#1c1917", "#292524", "#44403c", "#1f2937", "#0c0a09"]
			mat.albedo_color = Color.from_string(colors[int(rng.call(1) * 5) % 5], Color.DIM_GRAY)
			mat.roughness = 0.95
			mesh.material_override = mat
		"slums_suburbs":
			# Small rundown house — brown/red brick
			var b_mesh = BoxMesh.new()
			b_mesh.size = Vector3(w, h, d)
			mesh.mesh = b_mesh
			mesh.position = Vector3(x, terrain_height(x, z) + h / 2, z)
			var mat = StandardMaterial3D.new()
			var colors = ["#7c2d12", "#9a3412", "#451a03", "#57534e", "#78350f", "#5b2c0f"]
			mat.albedo_color = Color.from_string(colors[int(rng.call(1) * 6) % 6], Color.DIM_GRAY)
			mat.roughness = 1.0
			mesh.material_override = mat
		"harbor":
			# Factory — gray, metallic
			var b_mesh = BoxMesh.new()
			b_mesh.size = Vector3(w, h, d)
			mesh.mesh = b_mesh
			mesh.position = Vector3(x, terrain_height(x, z) + h / 2, z)
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
			mesh.position = Vector3(x, terrain_height(x, z) + h / 2, z)
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
		if abs(z - pos) < road_buffer and abs(x) > -250 and abs(x) < 350:
			return true
		if abs(x - pos) < road_buffer and abs(z) > -350 and abs(z) < 450:
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
		Vector3(-150, 0, -50), Vector3(-50, 0, -50), Vector3(50, 0, -50), Vector3(150, 0, -50),
		Vector3(-150, 0, 50), Vector3(-50, 0, 50), Vector3(50, 0, 50), Vector3(150, 0, 50),
		Vector3(250, 0, -50), Vector3(250, 0, 50),
		Vector3(-100, 0, -150), Vector3(100, 0, -150), Vector3(-100, 0, 150), Vector3(100, 0, 150),
	]
	for pos in positions:
		var pole = MeshInstance3D.new()
		var p_mesh = CylinderMesh.new()
		p_mesh.top_radius = 0.08
		p_mesh.bottom_radius = 0.08
		p_mesh.height = 4
		pole.mesh = p_mesh
		pole.position = pos + Vector3(0, terrain_height(pos.x, pos.z) + 2, 0)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.06, 0.06, 0.06)
		pole.material_override = mat
		parent.add_child(pole)
		var light = OmniLight3D.new()
		light.position = pos + Vector3(0, terrain_height(pos.x, pos.z) + 4, 0)
		light.light_color = Color(1, 0.95, 0.8)
		light.light_energy = 2.0
		light.omni_range = 12.0
		parent.add_child(light)

# ============================================================
# Harbor dock props (cranes, containers)
# ============================================================

static func _build_dock_props(parent: Node3D) -> void:
	# === HARBOR BASIN (water inlet for ships) ===
	# Cut a rectangular basin into the harbor area for ships to dock
	var basin = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(200, 0.1, 300)  # 200x300m harbor basin
	basin.mesh = b_mesh
	basin.position = Vector3(400, -2.0, 300)  # harbor basin at new coast plane (y=-3.0) to avoid z-fight
	var basin_mat = StandardMaterial3D.new()
	basin_mat.albedo_color = Color(0.05, 0.15, 0.28)  # dark water
	basin_mat.roughness = 0.1
	basin_mat.metalness = 0.6
	basin.material_override = basin_mat
	parent.add_child(basin)
	
	# === DOCKS (concrete piers extending into basin) ===
	# 3 piers running east-west into the basin
	for pier_idx in range(3):
		var pier_z = -100 + pier_idx * 100  # piers at z = -100, 0, 100
		var pier = MeshInstance3D.new()
		var p_mesh = BoxMesh.new()
		p_mesh.size = Vector3(120, 1.0, 20)  # 120m long, 20m wide pier
		pier.mesh = p_mesh
		pier.position = Vector3(400, 0.5, pier_z)
		var pier_mat = StandardMaterial3D.new()
		pier_mat.albedo_color = Color(0.5, 0.5, 0.5)  # concrete gray
		pier_mat.roughness = 0.95
		pier.material_override = pier_mat
		parent.add_child(pier)
		# Collision for pier (so cars can drive on it)
		var pier_body = StaticBody3D.new()
		pier_body.position = Vector3(400, 0.5, pier_z)
		var pier_col = CollisionShape3D.new()
		var pier_shape = BoxShape3D.new()
		pier_shape.size = Vector3(120, 1.0, 20)
		pier_col.shape = pier_shape
		pier_body.add_child(pier_col)
		parent.add_child(pier_body)
	
	# === CARGO SHIPS (large box-shaped ships docked at piers) ===
	for ship_idx in range(3):
		var ship_z = -100 + ship_idx * 100
		var ship = MeshInstance3D.new()
		var s_mesh = BoxMesh.new()
		s_mesh.size = Vector3(80, 8, 15)  # 80m long, 8m tall, 15m wide ship
		ship.mesh = s_mesh
		ship.position = Vector3(440, 4, ship_z + 15)  # next to pier at new harbor
		var ship_mat = StandardMaterial3D.new()
		var ship_colors = ["#1e3a5f", "#1e293b", "#0c4a6e", "#1e3a5f"]
		ship_mat.albedo_color = Color.from_string(ship_colors[ship_idx % 4], Color(0.12, 0.23, 0.54))
		ship_mat.roughness = 0.4
		ship_mat.metalness = 0.5
		ship.material_override = ship_mat
		parent.add_child(ship)
		# Ship superstructure (bridge tower)
		var bridge = MeshInstance3D.new()
		var br_mesh = BoxMesh.new()
		br_mesh.size = Vector3(15, 6, 12)
		bridge.mesh = br_mesh
		bridge.position = Vector3(440, 12, ship_z + 15)
		var bridge_mat = StandardMaterial3D.new()
		bridge_mat.albedo_color = Color.WHITE
		bridge_mat.roughness = 0.3
		bridge.material_override = bridge_mat
		parent.add_child(bridge)
	
	# === CARGO CONTAINERS (stacked on piers, not floating) ===
	for i in range(60):
		# Place containers ON the piers (at pier height y=1.5)
		var pier_idx = i % 3
		var pier_z = -100 + pier_idx * 100
		var cx = 360 + (i / 3) % 5 * 12  # along pier length
		var cz = pier_z + ((i / 3) / 5) % 2 * 6 - 3  # across pier width
		var container = MeshInstance3D.new()
		var c_mesh = BoxMesh.new()
		c_mesh.size = Vector3(12, 2.5, 2.5)  # standard container size
		container.mesh = c_mesh
		var stack_h = int(randf() * 3) * 2.6  # stack 0-2 high
		container.position = Vector3(cx, 1.5 + stack_h, cz)
		var mat = StandardMaterial3D.new()
		var colors = ["#dc2626", "#2563eb", "#16a34a", "#eab308", "#ea580c", "#7c3aed", "#0891b2"]
		mat.albedo_color = Color.from_string(colors[randi() % colors.size()], Color.GRAY)
		mat.roughness = 0.7
		container.material_override = mat
		parent.add_child(container)
	
	# === CARGO CRANES (large, on piers, loading ships) ===
	for i in range(6):
		var crane_idx = i % 3
		var crane_z = -100 + crane_idx * 100
		var crane_x = 380 + (i / 3) * 30
		var crane = _make_crane()
		crane.position = Vector3(crane_x, 1.0, crane_z)  # on pier
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
	# Central Park (Downtown, between skyscrapers)
	_park(parent, 0, 150, 80, 50)
	# Skyline row (3 tall towers in Downtown East, near harbor)
	_skyscraper(parent, 200, -100, 20, 110, "#1e293b")
	_skyscraper(parent, 230, -100, 20, 140, "#0f172a")
	_skyscraper(parent, 260, -100, 20, 120, "#1e293b")
	# Bridge at harbor entrance
	_bridge(parent, 500, 200, 0)
	# Fortress on west canyon rim
	_fortress(parent, 500, -500)
	# Stadium in Industrial area
	_stadium(parent, -300, -200)
	# Bus station in Downtown
	_bus_station(parent, 100, -200)
	# Gas stations (Industrial + Harbor)
	_gas_station(parent, -200, 100)
	_gas_station(parent, 400, 350)

static func _park(parent: Node3D, x: float, z: float, w: float, d: float) -> void:
	# Park with clear boundary (sidewalk-style border) like a building block
	# Grass surface (slightly raised like sidewalk)
	var grass = MeshInstance3D.new()
	var g_mesh = BoxMesh.new()
	g_mesh.size = Vector3(w, 0.12, d)
	grass.mesh = g_mesh
	grass.position = Vector3(x, terrain_height(x, z) + 0.06, z)
	var gmat = StandardMaterial3D.new()
	gmat.albedo_color = Color(0.18, 0.35, 0.15)
	gmat.roughness = 1.0
	grass.material_override = gmat
	parent.add_child(grass)
	# COLLISION: StaticBody3D so cars/player can walk on park grass
	var grass_body = StaticBody3D.new()
	grass_body.position = Vector3(x, terrain_height(x, z) + 0.06, z)
	var grass_col = CollisionShape3D.new()
	var grass_shape = BoxShape3D.new()
	grass_shape.size = Vector3(w, 0.12, d)
	grass_col.shape = grass_shape
	grass_body.add_child(grass_col)
	parent.add_child(grass_body)
	# Border curb (raised edge around the park, like sidewalk edge)
	var curb_height = 0.2
	var curb_width = 0.3
	var curb_mat = StandardMaterial3D.new()
	curb_mat.albedo_color = Color(0.5, 0.5, 0.5)  # gray concrete curb
	curb_mat.roughness = 0.9
	# 4 curbs (N, S, E, W edges of park)
	for side in ["N", "S", "E", "W"]:
		var curb = MeshInstance3D.new()
		var c_mesh = BoxMesh.new()
		match side:
			"N":  # north edge (z = z - d/2)
				c_mesh.size = Vector3(w, curb_height, curb_width)
				curb.position = Vector3(x, curb_height / 2, z - d / 2)
			"S":  # south edge (z = z + d/2)
				c_mesh.size = Vector3(w, curb_height, curb_width)
				curb.position = Vector3(x, curb_height / 2, z + d / 2)
			"E":  # east edge (x = x + w/2)
				c_mesh.size = Vector3(curb_width, curb_height, d)
				curb.position = Vector3(x + w / 2, curb_height / 2, z)
			"W":  # west edge (x = x - w/2)
				c_mesh.size = Vector3(curb_width, curb_height, d)
				curb.position = Vector3(x - w / 2, curb_height / 2, z)
		curb.mesh = c_mesh
		curb.material_override = curb_mat
		parent.add_child(curb)
	# Trees scattered inside park (with margin from curb)
	var margin = 4.0
	for i in range(8):
		var tx = x + (randf() - 0.5) * (w - margin * 2)
		var tz = z + (randf() - 0.5) * (d - margin * 2)
		_make_tree(parent, tx, tz, 0.8 + randf() * 0.5)
	# Park label
	var label = Label3D.new()
	label.text = "🌳 PARK"
	label.position = Vector3(x, 2, z)
	label.font_size = 36
	label.outline_size = 6
	label.outline_modulate = Color.BLACK
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	parent.add_child(label)

static func _skyscraper(parent: Node3D, x: float, z: float, w: float, h: float, color: String) -> void:
	var mesh = MeshInstance3D.new()
	var s_mesh = BoxMesh.new()
	s_mesh.size = Vector3(w, h, w)
	mesh.mesh = s_mesh
	mesh.position = Vector3(x, terrain_height(x, z) + h / 2, z)
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
	body.position = Vector3(x, terrain_height(x, z) + h / 2, z)
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
