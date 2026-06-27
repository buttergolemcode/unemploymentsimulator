# WorldBuilder.gd — Island map with 4 regions, built from heightmap PNG
# Modular: each region has its own build function per spec
class_name WorldBuilder
extends RefCounted

# ============================================================
# CONSTANTS
# ============================================================
const MAP_SIZE: float = 2500.0
const HEIGHTMAP_PATH: String = "res://assets/heightmap.png"
const HEIGHTMAP_WORLD_SIZE: float = 2500.0
const HEIGHTMAP_MAX_HEIGHT: float = 120.0

# NYC Downtown grid
const STREET_GRID: Array = [-200, -100, 0, 100, 200, 300]
const ROAD_HALF_WIDTH: float = 4.0
const SIDEWALK_WIDTH: float = 2.5
const SIDEWALK_HEIGHT: float = 0.15
const BLOCK_SIZE: float = 80.0
const BUILDING_MARGIN: float = 0.5

# District definitions (4 island regions)
static var DISTRICTS: Dictionary = {}

# Heightmap
static var _heightmap_img: Image = null

# ============================================================
# SCHEME BUILDINGS
# ============================================================
const SCHEME_BUILDINGS: Array = [
	# NYC Downtown (center) — skyscrapers
	{"id": "trading", "name": "Trading Floor", "emoji": "📈",
	 "x": 50, "z": -50, "w": 25, "d": 22, "h": 70, "color": "#22d3ee"},
	{"id": "wirefraud", "name": "Corporate Tower", "emoji": "💸",
	 "x": 150, "z": 50, "w": 30, "d": 25, "h": 120, "color": "#64748b"},
	{"id": "taxfraud", "name": "Accountant Office", "emoji": "🧾",
	 "x": -100, "z": 100, "w": 18, "d": 16, "h": 35, "color": "#eab308"},
	{"id": "gambling", "name": "Casino", "emoji": "🎰",
	 "x": 200, "z": -100, "w": 25, "d": 22, "h": 28, "color": "#f59e0b"},
	# Slums (W/NW) — container buildings
	{"id": "drugs", "name": "Trap House", "emoji": "💊",
	 "x": -400, "z": 200, "w": 10, "d": 8, "h": 6, "color": "#a855f7"},
	{"id": "scam", "name": "Internet Cafe", "emoji": "🎣",
	 "x": -500, "z": 300, "w": 8, "d": 7, "h": 5, "color": "#ec4899"},
	{"id": "robbery", "name": "Corner Store", "emoji": "🔫",
	 "x": -350, "z": 350, "w": 7, "d": 7, "h": 4, "color": "#ef4444"},
	# NYC Downtown — warehouse
	{"id": "ecom", "name": "E-Com Warehouse", "emoji": "📦",
	 "x": -50, "z": 200, "w": 25, "d": 22, "h": 15, "color": "#4ade80"},
]

# ============================================================
# HEIGHTMAP
# ============================================================
static func _load_heightmap() -> void:
	if _heightmap_img != null:
		return
	var path = ProjectSettings.globalize_path(HEIGHTMAP_PATH)
	_heightmap_img = Image.load_from_file(path)
	if _heightmap_img == null:
		push_warning("Heightmap not found — using flat fallback")
	else:
		print("[WorldBuilder] Heightmap loaded: ", _heightmap_img.get_width(), "x", _heightmap_img.get_height())

static func terrain_height(x: float, z: float) -> float:
	if _heightmap_img == null:
		_load_heightmap()
	if _heightmap_img != null:
		var px = int((x + HEIGHTMAP_WORLD_SIZE / 2.0) / HEIGHTMAP_WORLD_SIZE * float(_heightmap_img.get_width()))
		var pz = int((z + HEIGHTMAP_WORLD_SIZE / 2.0) / HEIGHTMAP_WORLD_SIZE * float(_heightmap_img.get_height()))
		px = clamp(px, 0, _heightmap_img.get_width() - 1)
		pz = clamp(pz, 0, _heightmap_img.get_height() - 1)
		return _heightmap_img.get_pixel(px, pz).r * HEIGHTMAP_MAX_HEIGHT
	return 0.0

# ============================================================
# DISTRICT SYSTEM
# ============================================================
static func _init_districts() -> void:
	if not DISTRICTS.is_empty():
		return
	# Polygons aligned with the organic island geography:
	#   portofino     = NE quadrant (+X, -Z)
	#   harbor        = SE quadrant (+X, +Z)
	#   slums_suburbs = W/NW (-X, both Z)
	#   nyc           = center (around origin)
	# Boundaries chosen so each polygon roughly covers its spec'd region
	# without overlapping the others.
	DISTRICTS = {
		"portofino": {
			"color": "#d4a574", "height_min": 8, "height_max": 100, "ground": "#8a7a5a",
			"polygon": PackedVector2Array([
				Vector2(0, -1200), Vector2(1300, -1200),
				Vector2(1300, 0), Vector2(0, 0)
			])
		},
		"nyc": {
			"color": "#1e293b", "height_min": 40, "height_max": 150, "ground": "#1a1a1a",
			"polygon": PackedVector2Array([
				Vector2(-400, -400), Vector2(400, -400),
				Vector2(400, 400), Vector2(-400, 400)
			])
		},
		"harbor": {
			"color": "#1c1917", "height_min": 8, "height_max": 20, "ground": "#171717",
			"polygon": PackedVector2Array([
				Vector2(0, 0), Vector2(1300, 0),
				Vector2(1300, 1300), Vector2(0, 1300)
			])
		},
		"slums_suburbs": {
			"color": "#5a4030", "height_min": 4, "height_max": 50, "ground": "#2a2a1a",
			"polygon": PackedVector2Array([
				Vector2(-1300, -1200), Vector2(0, -1200),
				Vector2(0, 1300), Vector2(-1300, 1300)
			])
		},
	}

static func get_district_at(x: float, z: float) -> String:
	_init_districts()
	var point = Vector2(x, z)
	for district_name in ["portofino", "nyc", "harbor", "slums_suburbs"]:
		var district = DISTRICTS[district_name]
		var polygon = district.get("polygon", PackedVector2Array())
		if polygon.size() >= 3 and Geometry2D.is_point_in_polygon(point, polygon):
			return district_name
	return "sea"

# ============================================================
# BUILD WORLD — entry point
# ============================================================
static func build_world(parent: Node3D) -> void:
	_load_heightmap()
	_init_districts()
	_build_terrain(parent)
	_build_sea(parent)
	_build_nyc_downtown(parent)
	_build_harbor(parent)
	_build_portofino(parent)
	_build_slums_suburbs(parent)
	_build_scheme_buildings(parent)
	_build_connection_roads(parent)

# ============================================================
# TERRAIN — heightmap mesh + collision grid
# Modular sub-builders: each handles one coloring layer.
# ============================================================

# Terrain color palette — used for slope/height-based vertex coloring
const COL_DEEP_SEA   := Color(0.04, 0.18, 0.32)
const COL_SHALLOW    := Color(0.10, 0.35, 0.50)
const COL_SAND       := Color(0.78, 0.70, 0.50)
const COL_GRASS      := Color(0.30, 0.42, 0.20)
const COL_GRASS_DRY  := Color(0.55, 0.50, 0.28)
const COL_ROCK       := Color(0.45, 0.40, 0.35)
const COL_CLIFF      := Color(0.32, 0.28, 0.24)
const COL_SNOW       := Color(0.92, 0.92, 0.95)
const COL_URBAN      := Color(0.18, 0.18, 0.20)
const COL_PORTOFINO  := Color(0.68, 0.55, 0.35)
const COL_HARBOR     := Color(0.24, 0.22, 0.20)
const COL_SLUMS      := Color(0.32, 0.24, 0.18)
const COL_SUBURB     := Color(0.42, 0.48, 0.32)

static func _terrain_color_at(x: float, z: float, h: float, slope: float) -> Color:
	# Default: by region
	var dist_id = get_district_at(x, z)
	var base: Color
	match dist_id:
		"nyc":          base = COL_URBAN
		"harbor":       base = COL_HARBOR
		"portofino":    base = COL_PORTOFINO
		"slums_suburbs":
			# Suburbs (north, z<0) greener, slums (south) browner
			if z < -150:
				base = COL_SUBURB
			else:
				base = COL_SLUMS
		_:              base = COL_DEEP_SEA
	# Below sea level: water
	if h < -1.0:
		return COL_DEEP_SEA.lerp(COL_SHALLOW, clamp((-h) / 15.0, 0.0, 1.0))
	# Shallow water just below 0
	if h < 0.2:
		return COL_SHALLOW
	# Beach: sand near water and flat
	if h < 2.5 and slope < 0.25:
		return COL_SAND.lerp(base, clamp((h - 0.2) / 2.3, 0.0, 1.0))
	# Cliffs on steep slopes (regardless of region, but only above water)
	if slope > 0.65 and h > 2.0:
		return COL_CLIFF.lerp(COL_ROCK, clamp((slope - 0.65) / 0.5, 0.0, 1.0))
	# Rocky slopes
	if slope > 0.40 and h > 2.0:
		return base.lerp(COL_ROCK, clamp((slope - 0.40) / 0.25, 0.0, 1.0))
	# High peaks: rock → snow
	if h > 55.0:
		return COL_ROCK.lerp(COL_SNOW, clamp((h - 55.0) / 25.0, 0.0, 1.0))
	# Mid-elevation in portofino/suburbs: dry grass on drier slopes
	if dist_id == "portofino" and h > 25.0:
		return base.lerp(COL_GRASS_DRY, clamp((h - 25.0) / 30.0, 0.0, 1.0))
	# Default: region color
	return base

static func _build_terrain(parent: Node3D) -> void:
	var size = 2700
	var segs = 250  # higher resolution for smoother terrain features
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(size, size)
	mesh.subdivide_width = segs
	mesh.subdivide_depth = segs
	var surf = SurfaceTool.new()
	surf.create_from(mesh, 0)
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(surf.commit(), 0)

	# Pass 1: assign Y from heightmap
	for i in mdt.get_vertex_count():
		var v = mdt.get_vertex(i)
		v.y = terrain_height(v.x, v.z)
		mdt.set_vertex(i, v)

	# Pass 2: compute slope per vertex (gradient from neighbors)
	# We sample terrain at small offset to compute slope.
	var sample_step = size / float(segs) * 0.6
	for i in mdt.get_vertex_count():
		var v = mdt.get_vertex(i)
		# Sample heights in +X and +Z direction
		var hx1 = terrain_height(v.x + sample_step, v.z)
		var hx0 = terrain_height(v.x - sample_step, v.z)
		var hz1 = terrain_height(v.x, v.z + sample_step)
		var hz0 = terrain_height(v.x, v.z - sample_step)
		var dx = (hx1 - hx0) / (2.0 * sample_step)
		var dz = (hz1 - hz0) / (2.0 * sample_step)
		# Slope magnitude (rise / run); 0 = flat, 1 = 45°, >1 = steeper
		var slope = sqrt(dx * dx + dz * dz)
		var col = _terrain_color_at(v.x, v.z, v.y, slope)
		mdt.set_vertex_color(i, col)

	# Recompute normals so lighting looks smooth
	var tmp_mesh = ArrayMesh.new()
	mdt.commit_to_surface(tmp_mesh)
	var surf2 = SurfaceTool.new()
	surf2.create_from(tmp_mesh, 0)
	surf2.recalculate_normals()
	surf2.recalculate_tangents()
	var final_mesh = surf2.commit()

	var mi = MeshInstance3D.new()
	mi.mesh = final_mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DISABLED
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	mat.metalness = 0.0
	mi.material_override = mat

	# Collision: terrain-following grid (smaller cells for cliffs/bays)
	var terrain_body = StaticBody3D.new()
	terrain_body.name = "TerrainGround"
	var grid = 35  # finer collision grid for cliffs and bays
	for gx in range(-1350, 1351, grid):
		for gz in range(-1350, 1351, grid):
			var h = terrain_height(gx, gz)
			if h < -1.5:
				continue  # sea — no collision (water plane handles it)
			var rcol = CollisionShape3D.new()
			var rshape = BoxShape3D.new()
			rshape.size = Vector3(grid, 1.5, grid)
			rcol.shape = rshape
			rcol.position = Vector3(gx, h - 0.75, gz)
			terrain_body.add_child(rcol)
	parent.add_child(terrain_body)
	parent.add_child(mi)

# ============================================================
# SEA — large water plane around island
# ============================================================
static func _build_sea(parent: Node3D) -> void:
	var plane = PlaneMesh.new()
	plane.size = Vector2(4500, 4500)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.06, 0.28, 0.42, 0.88)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.12
	mat.metalness = 0.55
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	plane.material = mat
	var mi = MeshInstance3D.new()
	mi.mesh = plane
	mi.position = Vector3(0, -2.8, 0)
	parent.add_child(mi)

# ============================================================
# NYC DOWNTOWN — grid, skyscrapers, sidewalks, crosswalks
# Spec: map-design-nyc-downtown.md
# ============================================================
static func _build_nyc_downtown(parent: Node3D) -> void:
	# Streets (grid at STREET_GRID positions)
	for pos in STREET_GRID:
		_build_nyc_street(parent, "x", pos)
		_build_nyc_street(parent, "z", pos)
	# Crosswalks at intersections
	for x_pos in STREET_GRID:
		for z_pos in STREET_GRID:
			_build_crosswalk(parent, x_pos, z_pos)
	# Filler buildings (2x2 per block)
	var block_centers = [-150, -50, 50, 150, 250]
	for bx in block_centers:
		for bz in block_centers:
			_build_nyc_block(parent, bx, bz)
	# Skyline landmarks
	_build_skyscraper(parent, 200, -100, 20, 110, "#1e293b")
	_build_skyscraper(parent, 230, -100, 20, 140, "#0f172a")
	_build_skyscraper(parent, 260, -100, 20, 120, "#1e293b")
	# Central park
	_build_park(parent, 0, 150, 80, 50)
	# Street lamps
	_build_nyc_lamps(parent)

static func _build_nyc_street(parent: Node3D, axis: String, pos: float) -> void:
	var length = 800.0
	var base_y = terrain_height(0, pos) if axis == "x" else terrain_height(pos, 0)
	# Asphalt
	var asphalt = MeshInstance3D.new()
	var a_mesh = BoxMesh.new()
	if axis == "x":
		a_mesh.size = Vector3(length, 0.04, ROAD_HALF_WIDTH * 2)
		asphalt.position = Vector3(0, base_y + 0.03, pos)
	else:
		a_mesh.size = Vector3(ROAD_HALF_WIDTH * 2, 0.04, length)
		asphalt.position = Vector3(pos, base_y + 0.03, 0)
	asphalt.mesh = a_mesh
	var amat = StandardMaterial3D.new()
	amat.albedo_color = Color(0.08, 0.08, 0.08)
	amat.roughness = 0.95
	asphalt.material_override = amat
	parent.add_child(asphalt)
	# Sidewalks (5cm collision, 15cm visual)
	for side in [-1, 1]:
		var prev = -length / 2
		for cross in STREET_GRID:
			var seg_end = cross - ROAD_HALF_WIDTH - SIDEWALK_WIDTH
			var seg_len = seg_end - prev
			if seg_len > 1:
				_build_sidewalk_seg(parent, axis, pos, side, prev, seg_len, base_y)
			prev = cross + ROAD_HALF_WIDTH + SIDEWALK_WIDTH
		var seg_len = (length / 2) - prev
		if seg_len > 1:
			_build_sidewalk_seg(parent, axis, pos, side, prev, seg_len, base_y)
	# Lane markings
	var dash_spacing = 5.0
	for cross_idx in range(STREET_GRID.size()):
		var cs = -length / 2 if cross_idx == 0 else STREET_GRID[cross_idx - 1] + ROAD_HALF_WIDTH + 1
		var ce = STREET_GRID[cross_idx] - ROAD_HALF_WIDTH - 1 if cross_idx < STREET_GRID.size() - 1 else length / 2
		var sl = ce - cs
		if sl > 1:
			var count = int(sl / dash_spacing)
			for i in count:
				var t = cs + (i + 0.5) * dash_spacing
				if t > ce: break
				_build_dash(parent, axis, pos, t, base_y)

static func _build_sidewalk_seg(parent: Node3D, axis: String, pos: float, side: int, seg_start: float, seg_len: float, base_y: float) -> void:
	var seg_center = seg_start + seg_len / 2
	var col_h = 0.05
	# Visual (15cm)
	var sw = MeshInstance3D.new()
	var s_mesh = BoxMesh.new()
	if axis == "x":
		s_mesh.size = Vector3(seg_len, SIDEWALK_HEIGHT, SIDEWALK_WIDTH)
		sw.position = Vector3(seg_center, base_y + SIDEWALK_HEIGHT / 2, pos + side * (ROAD_HALF_WIDTH + SIDEWALK_WIDTH / 2))
	else:
		s_mesh.size = Vector3(SIDEWALK_WIDTH, SIDEWALK_HEIGHT, seg_len)
		sw.position = Vector3(pos + side * (ROAD_HALF_WIDTH + SIDEWALK_WIDTH / 2), base_y + SIDEWALK_HEIGHT / 2, seg_center)
	sw.mesh = s_mesh
	var smat = StandardMaterial3D.new()
	smat.albedo_color = Color(0.55, 0.55, 0.55)
	smat.roughness = 0.9
	sw.material_override = smat
	parent.add_child(sw)
	# Collision (5cm)
	var body = StaticBody3D.new()
	var sx = seg_center if axis == "x" else pos + side * (ROAD_HALF_WIDTH + SIDEWALK_WIDTH / 2)
	var sz = pos + side * (ROAD_HALF_WIDTH + SIDEWALK_WIDTH / 2) if axis == "x" else seg_center
	body.position = Vector3(sx, base_y + col_h / 2, sz)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	if axis == "x":
		shape.size = Vector3(seg_len, col_h, SIDEWALK_WIDTH)
	else:
		shape.size = Vector3(SIDEWALK_WIDTH, col_h, seg_len)
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)

static func _build_dash(parent: Node3D, axis: String, pos: float, t: float, base_y: float) -> void:
	var dash = MeshInstance3D.new()
	var d_mesh = BoxMesh.new()
	if axis == "x":
		d_mesh.size = Vector3(2.5, 0.01, 0.3)
		dash.position = Vector3(t, base_y + 0.04, pos)
	else:
		d_mesh.size = Vector3(0.3, 0.01, 2.5)
		dash.position = Vector3(pos, base_y + 0.04, t)
	dash.mesh = d_mesh
	var dmat = StandardMaterial3D.new()
	dmat.albedo_color = Color(0.95, 0.85, 0.2)
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dash.material_override = dmat
	parent.add_child(dash)

static func _build_crosswalk(parent: Node3D, x_pos: float, z_pos: float) -> void:
	var base_y = terrain_height(x_pos, z_pos)
	# 4 crosswalks + 4 corners
	for dx in [-1, 1]:
		for dz in [-1, 1]:
			# Corner sidewalk piece
			var cx = x_pos + dx * (ROAD_HALF_WIDTH + SIDEWALK_WIDTH / 2)
			var cz = z_pos + dz * (ROAD_HALF_WIDTH + SIDEWALK_WIDTH / 2)
			var corner = MeshInstance3D.new()
			var c_mesh = BoxMesh.new()
			c_mesh.size = Vector3(SIDEWALK_WIDTH, SIDEWALK_HEIGHT, SIDEWALK_WIDTH)
			corner.mesh = c_mesh
			corner.position = Vector3(cx, base_y + SIDEWALK_HEIGHT / 2, cz)
			var smat = StandardMaterial3D.new()
			smat.albedo_color = Color(0.55, 0.55, 0.55)
			smat.roughness = 0.9
			corner.material_override = smat
			parent.add_child(corner)
			var cbody = StaticBody3D.new()
			cbody.position = Vector3(cx, base_y + 0.025, cz)
			var ccol = CollisionShape3D.new()
			var cshape = BoxShape3D.new()
			cshape.size = Vector3(SIDEWALK_WIDTH, 0.05, SIDEWALK_WIDTH)
			ccol.shape = cshape
			cbody.add_child(ccol)
			parent.add_child(cbody)
	# Crosswalk stripes (4 legs)
	for leg in ["n", "s", "e", "w"]:
		var stripe_count = 6
		var stripe_w = 0.6
		var stripe_l = ROAD_HALF_WIDTH * 2 - 0.5
		for i in stripe_count:
			var off = (i - (stripe_count - 1) / 2.0) * 0.8
			var stripe = MeshInstance3D.new()
			var s_mesh = BoxMesh.new()
			match leg:
				"n":
					s_mesh.size = Vector3(stripe_w, 0.02, stripe_l)
					stripe.position = Vector3(x_pos + off, base_y + 0.05, z_pos - ROAD_HALF_WIDTH - 1.5)
				"s":
					s_mesh.size = Vector3(stripe_w, 0.02, stripe_l)
					stripe.position = Vector3(x_pos + off, base_y + 0.05, z_pos + ROAD_HALF_WIDTH + 1.5)
				"e":
					s_mesh.size = Vector3(stripe_l, 0.02, stripe_w)
					stripe.position = Vector3(x_pos + ROAD_HALF_WIDTH + 1.5, base_y + 0.05, z_pos + off)
				"w":
					s_mesh.size = Vector3(stripe_l, 0.02, stripe_w)
					stripe.position = Vector3(x_pos - ROAD_HALF_WIDTH - 1.5, base_y + 0.05, z_pos + off)
			stripe.mesh = s_mesh
			var smat = StandardMaterial3D.new()
			smat.albedo_color = Color(0.95, 0.95, 0.95)
			smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			stripe.material_override = smat
			parent.add_child(stripe)

static func _build_nyc_block(parent: Node3D, bx: float, bz: float) -> void:
	var road_buf = ROAD_HALF_WIDTH + SIDEWALK_WIDTH + BUILDING_MARGIN
	var inner = BLOCK_SIZE - 2 * road_buf
	if inner < 10: return
	var bps = 2  # buildings per side
	var cell_w = inner / bps
	var cell_d = inner / bps
	for ix in range(bps):
		for iz in range(bps):
			var cx = (bx - inner / 2) + cell_w * (ix + 0.5)
			var cz = (bz - inner / 2) + cell_d * (iz + 0.5)
			# Skip near scheme buildings
			var skip = false
			for b in SCHEME_BUILDINGS:
				if sqrt((cx - b.x) ** 2 + (cz - b.z) ** 2) < max(b.w, b.d) / 2 + 8:
					skip = true; break
			if skip: continue
			# Random-ish (deterministic)
			var seed_val = abs((int(cx) * 73856093) ^ (int(cz) * 19349663)) % 99991
			var rng = func(s): return float((seed_val * (s + 1) * 9301 + 49297) % 233280) / 233280
			if rng.call(99) < 0.10: continue
			var w = min(cell_w - 3, 20 + rng.call(1) * 8)
			var d = min(cell_d - 3, 18 + rng.call(2) * 8)
			var h = 40 + rng.call(3) * 110
			_build_nyc_building(parent, cx, cz, w, d, h, rng)

static func _build_nyc_building(parent: Node3D, x: float, z: float, w: float, d: float, h: float, rng: Callable) -> void:
	var base_y = terrain_height(x, z)
	var mesh = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(w, h, d)
	mesh.mesh = b_mesh
	mesh.position = Vector3(x, base_y + h / 2, z)
	var mat = StandardMaterial3D.new()
	var colors = ["#1e293b", "#0f172a", "#1e3a5f", "#1e293b", "#0c4a6e"]
	mat.albedo_color = Color.from_string(colors[int(rng.call(1) * 5) % 5], Color.DIM_GRAY)
	mat.metalness = 0.7
	mat.roughness = 0.2
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.5, 0.7)
	mat.emission_energy_multiplier = 0.25
	mesh.material_override = mat
	parent.add_child(mesh)
	var body = StaticBody3D.new()
	body.position = Vector3(x, base_y + h / 2, z)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(w, h, d)
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)

static func _build_nyc_lamps(parent: Node3D) -> void:
	var positions = [
		Vector3(-150, 0, -50), Vector3(-50, 0, -50), Vector3(50, 0, -50), Vector3(150, 0, -50),
		Vector3(-150, 0, 50), Vector3(-50, 0, 50), Vector3(50, 0, 50), Vector3(150, 0, 50),
		Vector3(250, 0, -50), Vector3(250, 0, 50),
		Vector3(-100, 0, -150), Vector3(100, 0, -150), Vector3(-100, 0, 150), Vector3(100, 0, 150),
	]
	for pos in positions:
		var base_y = terrain_height(pos.x, pos.z)
		var pole = MeshInstance3D.new()
		var p_mesh = CylinderMesh.new()
		p_mesh.top_radius = 0.08
		p_mesh.bottom_radius = 0.08
		p_mesh.height = 4
		pole.mesh = p_mesh
		pole.position = pos + Vector3(0, base_y + 2, 0)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.06, 0.06, 0.06)
		pole.material_override = mat
		parent.add_child(pole)
		var light = OmniLight3D.new()
		light.position = pos + Vector3(0, base_y + 4, 0)
		light.light_color = Color(1, 0.95, 0.8)
		light.light_energy = 2.0
		light.omni_range = 12.0
		parent.add_child(light)

static func _build_skyscraper(parent: Node3D, x: float, z: float, w: float, h: float, color: String) -> void:
	var base_y = terrain_height(x, z)
	var mesh = MeshInstance3D.new()
	var s_mesh = BoxMesh.new()
	s_mesh.size = Vector3(w, h, w)
	mesh.mesh = s_mesh
	mesh.position = Vector3(x, base_y + h / 2, z)
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
	body.position = Vector3(x, base_y + h / 2, z)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(w, h, w)
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)

static func _build_park(parent: Node3D, x: float, z: float, w: float, d: float) -> void:
	var base_y = terrain_height(x, z)
	var grass = MeshInstance3D.new()
	var g_mesh = BoxMesh.new()
	g_mesh.size = Vector3(w, 0.12, d)
	grass.mesh = g_mesh
	grass.position = Vector3(x, base_y + 0.06, z)
	var gmat = StandardMaterial3D.new()
	gmat.albedo_color = Color(0.18, 0.35, 0.15)
	gmat.roughness = 1.0
	grass.material_override = gmat
	parent.add_child(grass)
	var gbody = StaticBody3D.new()
	gbody.position = Vector3(x, base_y + 0.025, z)
	var gcol = CollisionShape3D.new()
	var gshape = BoxShape3D.new()
	gshape.size = Vector3(w, 0.05, d)
	gcol.shape = gshape
	gbody.add_child(gcol)
	parent.add_child(gbody)
	# Trees
	for i in range(6):
		var tx = x + (randf() - 0.5) * (w - 8)
		var tz = z + (randf() - 0.5) * (d - 8)
		_build_tree(parent, tx, tz, 0.8 + randf() * 0.5)

# ============================================================
# HARBOR — piers, ships, cranes, containers, warehouses
# Spec: map-design-harbor.md
# ============================================================
static func _build_harbor(parent: Node3D) -> void:
	# Harbor basin
	var basin = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(200, 0.1, 300)
	basin.mesh = b_mesh
	basin.position = Vector3(400, -2.0, 300)
	var bmat = StandardMaterial3D.new()
	bmat.albedo_color = Color(0.05, 0.15, 0.28)
	bmat.roughness = 0.1
	bmat.metalness = 0.6
	basin.material_override = bmat
	parent.add_child(basin)
	# Piers
	for i in range(3):
		var pz = 200 + i * 100
		_build_pier(parent, 400, pz)
	# Ships
	for i in range(3):
		var sz = 200 + i * 100
		_build_ship(parent, 440, sz + 15)
	# Cranes
	for i in range(6):
		var ci = i % 3
		var cz = 200 + ci * 100
		var cx = 380 + (i / 3) * 30
		_build_crane(parent, cx, cz)
	# Containers
	for i in range(60):
		var ci = i % 3
		var cz = 200 + ci * 100
		var cx = 360 + (i / 3) % 5 * 12
		_build_container(parent, cx, cz, i)
	# Warehouse buildings
	for i in range(8):
		var wx = 200 + (i % 4) * 50
		var wz = 500 + (i / 4) * 60
		_build_warehouse(parent, wx, wz)
	# Lighthouse at north mole
	_build_lighthouse(parent, 400, 100)

static func _build_pier(parent: Node3D, x: float, z: float) -> void:
	var base_y = terrain_height(x, z)
	var pier = MeshInstance3D.new()
	var p_mesh = BoxMesh.new()
	p_mesh.size = Vector3(120, 1.0, 20)
	pier.mesh = p_mesh
	pier.position = Vector3(x, base_y + 0.5, z)
	var pmat = StandardMaterial3D.new()
	pmat.albedo_color = Color(0.5, 0.5, 0.5)
	pmat.roughness = 0.95
	pier.material_override = pmat
	parent.add_child(pier)
	var body = StaticBody3D.new()
	body.position = Vector3(x, base_y + 0.5, z)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(120, 1.0, 20)
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)

static func _build_ship(parent: Node3D, x: float, z: float) -> void:
	var base_y = terrain_height(x, z)
	var ship = MeshInstance3D.new()
	var s_mesh = BoxMesh.new()
	s_mesh.size = Vector3(80, 8, 15)
	ship.mesh = s_mesh
	ship.position = Vector3(x, base_y + 4, z)
	var smat = StandardMaterial3D.new()
	smat.albedo_color = Color(0.12, 0.23, 0.54)
	smat.roughness = 0.4
	smat.metalness = 0.5
	ship.material_override = smat
	parent.add_child(ship)
	# Bridge
	var bridge = MeshInstance3D.new()
	var br_mesh = BoxMesh.new()
	br_mesh.size = Vector3(15, 6, 12)
	bridge.mesh = br_mesh
	bridge.position = Vector3(x, base_y + 12, z)
	var brmat = StandardMaterial3D.new()
	brmat.albedo_color = Color.WHITE
	brmat.roughness = 0.3
	bridge.material_override = brmat
	parent.add_child(bridge)

static func _build_crane(parent: Node3D, x: float, z: float) -> void:
	var base_y = terrain_height(x, z)
	var root = Node3D.new()
	root.position = Vector3(x, base_y, z)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.3, 0.1)
	mat.roughness = 0.7
	# Base
	var base_m = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(4, 2, 4)
	base_m.mesh = b_mesh
	base_m.position = Vector3(0, 1, 0)
	base_m.material_override = mat
	root.add_child(base_m)
	# Tower
	var tower = MeshInstance3D.new()
	var t_mesh = BoxMesh.new()
	t_mesh.size = Vector3(2, 20, 2)
	tower.mesh = t_mesh
	tower.position = Vector3(0, 12, 0)
	tower.material_override = mat
	root.add_child(tower)
	# Arm
	var arm = MeshInstance3D.new()
	var a_mesh = BoxMesh.new()
	a_mesh.size = Vector3(15, 1.5, 1.5)
	arm.mesh = a_mesh
	arm.position = Vector3(5, 22, 0)
	arm.material_override = mat
	root.add_child(arm)
	parent.add_child(root)

static func _build_container(parent: Node3D, x: float, z: float, idx: int) -> void:
	var base_y = terrain_height(x, z)
	var c = MeshInstance3D.new()
	var c_mesh = BoxMesh.new()
	c_mesh.size = Vector3(12, 2.5, 2.5)
	c.mesh = c_mesh
	var stack_h = int(randf() * 3) * 2.6
	c.position = Vector3(x, base_y + 1.5 + stack_h, z)
	var mat = StandardMaterial3D.new()
	var colors = ["#dc2626", "#2563eb", "#16a34a", "#eab308", "#ea580c", "#7c3aed", "#0891b2"]
	mat.albedo_color = Color.from_string(colors[idx % 7], Color.GRAY)
	mat.roughness = 0.7
	c.material_override = mat
	parent.add_child(c)

static func _build_warehouse(parent: Node3D, x: float, z: float) -> void:
	var base_y = terrain_height(x, z)
	var w = 30 + randf() * 10
	var d = 25 + randf() * 8
	var h = 12 + randf() * 8
	var mesh = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(w, h, d)
	mesh.mesh = b_mesh
	mesh.position = Vector3(x, base_y + h / 2, z)
	var mat = StandardMaterial3D.new()
	var colors = ["#1c1917", "#292524", "#44403c"]
	mat.albedo_color = Color.from_string(colors[randi() % 3], Color.DIM_GRAY)
	mat.roughness = 0.95
	mesh.material_override = mat
	parent.add_child(mesh)
	var body = StaticBody3D.new()
	body.position = Vector3(x, base_y + h / 2, z)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(w, h, d)
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)

static func _build_lighthouse(parent: Node3D, x: float, z: float) -> void:
	var base_y = terrain_height(x, z)
	# Tower
	var tower = MeshInstance3D.new()
	var t_mesh = CylinderMesh.new()
	t_mesh.top_radius = 1.5
	t_mesh.bottom_radius = 2.0
	t_mesh.height = 25
	tower.mesh = t_mesh
	tower.position = Vector3(x, base_y + 12.5, z)
	var tmat = StandardMaterial3D.new()
	tmat.albedo_color = Color.WHITE
	tmat.roughness = 0.6
	tower.material_override = tmat
	parent.add_child(tower)
	# Light
	var light = OmniLight3D.new()
	light.position = Vector3(x, base_y + 25, z)
	light.light_color = Color(1, 0.9, 0.6)
	light.light_energy = 3.0
	light.omni_range = 50.0
	parent.add_child(light)

# ============================================================
# PORTOFINO — pastell houses on hill, pines, cliffs, fortress
# Spec: map-design-portofino.md
# ============================================================
static func _build_portofino(parent: Node3D) -> void:
	# Pastell houses on the hillside
	var pastell_colors = ["#d4a574", "#e8c89a", "#d49a9a", "#c97b50", "#e8b8b8", "#d4c8a0"]
	for i in range(40):
		var angle = randf() * TAU
		var dist = 200 + randf() * 400
		var px = 300 + cos(angle) * dist * 0.5
		var pz = -300 + sin(angle) * dist * 0.4
		if get_district_at(px, pz) != "portofino":
			continue
		var base_y = terrain_height(px, pz)
		if base_y < 1:
			continue
		var w = 8 + randf() * 4
		var d = 7 + randf() * 4
		var h = 6 + randf() * 6
		var mesh = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()
		b_mesh.size = Vector3(w, h, d)
		mesh.mesh = b_mesh
		mesh.position = Vector3(px, base_y + h / 2, pz)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color.from_string(pastell_colors[randi() % pastell_colors.size()], Color.GRAY)
		mat.roughness = 0.85
		mesh.material_override = mat
		parent.add_child(mesh)
		var body = StaticBody3D.new()
		body.position = Vector3(px, base_y + h / 2, pz)
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(w, h, d)
		col.shape = shape
		body.add_child(col)
		parent.add_child(body)
	# Pines
	for i in range(30):
		var angle = randf() * TAU
		var dist = 100 + randf() * 500
		var tx = 300 + cos(angle) * dist * 0.4
		var tz = -300 + sin(angle) * dist * 0.4
		if get_district_at(tx, tz) != "portofino":
			continue
		var base_y = terrain_height(tx, tz)
		if base_y < 1:
			continue
		_build_tree(parent, tx, tz, 1.0 + randf() * 0.5)
	# Fortress on hill (Castle Brown)
	_build_fortress(parent, 500, -500)

static func _build_fortress(parent: Node3D, x: float, z: float) -> void:
	var base_y = terrain_height(x, z)
	var stone = StandardMaterial3D.new()
	stone.albedo_color = Color(0.45, 0.4, 0.35)
	stone.roughness = 0.95
	# Keep
	var keep = MeshInstance3D.new()
	var k_mesh = BoxMesh.new()
	k_mesh.size = Vector3(15, 18, 15)
	keep.mesh = k_mesh
	keep.position = Vector3(x, base_y + 9, z)
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
		tower.position = Vector3(x + offset.x, base_y + 11, z + offset.y)
		tower.material_override = stone
		parent.add_child(tower)

# ============================================================
# SLUMS / SUBURBS — containers + cul-de-sac houses
# Spec: map-design-slums-suburbs.md
# ============================================================
static func _build_slums_suburbs(parent: Node3D) -> void:
	# Slums: stacked containers (south part of region, z > 0)
	var slum_colors = ["#5a4030", "#404040", "#6b5b3a", "#4a3a2a", "#553d28"]
	for i in range(80):
		var sx = -700 + randf() * 500
		var sz = 50 + randf() * 600
		if get_district_at(sx, sz) != "slums_suburbs":
			continue
		var base_y = terrain_height(sx, sz)
		if base_y < 0: continue
		var stack = int(randf() * 3)
		var rot = randf() > 0.5
		var w = 12 if rot else 2.5
		var d = 2.5 if rot else 12
		var h = 2.5
		for s in range(stack + 1):
			var c = MeshInstance3D.new()
			var c_mesh = BoxMesh.new()
			c_mesh.size = Vector3(w, h, d)
			c.mesh = c_mesh
			c.position = Vector3(sx + (randf() - 0.5) * 1, base_y + h / 2 + s * h, sz + (randf() - 0.5) * 1)
			c.rotation.y = randf() * 0.3
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color.from_string(slum_colors[randi() % slum_colors.size()], Color.GRAY)
			mat.roughness = 1.0
			c.material_override = mat
			parent.add_child(c)
	# Suburbs: small houses with gardens (north part, z < 0)
	var suburb_colors = ["#e8dcc8", "#d4c8b0", "#f5f5f5", "#e5e5e5", "#d1d5db"]
	for i in range(30):
		var hx = -700 + randf() * 500
		var hz = -600 + randf() * 500
		if get_district_at(hx, hz) != "slums_suburbs":
			continue
		var base_y = terrain_height(hx, hz)
		if base_y < 0: continue
		var w = 8 + randf() * 4
		var d = 7 + randf() * 3
		var h = 5 + randf() * 5
		var mesh = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()
		b_mesh.size = Vector3(w, h, d)
		mesh.mesh = b_mesh
		mesh.position = Vector3(hx, base_y + h / 2, hz)
		mesh.rotation.y = randf() * 0.5
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color.from_string(suburb_colors[randi() % suburb_colors.size()], Color.GRAY)
		mat.roughness = 0.9
		mesh.material_override = mat
		parent.add_child(mesh)
		var body = StaticBody3D.new()
		body.position = Vector3(hx, base_y + h / 2, hz)
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(w, h, d)
		col.shape = shape
		body.add_child(col)
		parent.add_child(body)
		# Garden fence (simple box around house)
		var fence = MeshInstance3D.new()
		var f_mesh = BoxMesh.new()
		f_mesh.size = Vector3(w + 4, 1.5, 0.1)
		fence.mesh = f_mesh
		fence.position = Vector3(hx, base_y + 0.75, hz + d / 2 + 2)
		fence.rotation.y = mesh.rotation.y
		var fmat = StandardMaterial3D.new()
		fmat.albedo_color = Color(0.54, 0.42, 0.23)
		fmat.roughness = 0.9
		fence.material_override = fmat
		parent.add_child(fence)

# ============================================================
# SCHEME BUILDINGS — placed in their respective regions
# ============================================================
static func _build_scheme_buildings(parent: Node3D) -> void:
	for b in SCHEME_BUILDINGS:
		var base_y = terrain_height(b.x, b.z)
		var mesh = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()
		b_mesh.size = Vector3(b.w, b.h, b.d)
		mesh.mesh = b_mesh
		mesh.position = Vector3(b.x, base_y + b.h / 2.0, b.z)
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
		var body = StaticBody3D.new()
		body.position = Vector3(b.x, base_y + b.h / 2.0, b.z)
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(b.w, b.h, b.d)
		col.shape = shape
		body.add_child(col)
		parent.add_child(body)
		var label = Label3D.new()
		label.text = "%s %s" % [b.emoji, b.name]
		label.position = Vector3(b.x, base_y + b.h + 2, b.z)
		label.font_size = 48
		label.outline_size = 6
		label.outline_modulate = Color.BLACK
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		parent.add_child(label)

# ============================================================
# CONNECTION ROADS — between regions
# ============================================================
static func _build_connection_roads(parent: Node3D) -> void:
	# NYC → Harbor (south)
	_build_simple_road(parent, Vector3(0, 0, 300), Vector3(200, 0, 500))
	# NYC → Slums (west)
	_build_simple_road(parent, Vector3(-200, 0, 0), Vector3(-500, 0, 100))
	# Harbor → Slums (southwest coast)
	_build_simple_road(parent, Vector3(200, 0, 600), Vector3(-300, 0, 600))
	# Portofino → NYC (northeast to center)
	_build_simple_road(parent, Vector3(300, 0, -200), Vector3(100, 0, -100))

static func _build_simple_road(parent: Node3D, from: Vector3, to: Vector3) -> void:
	var dir = (to - from)
	var length = dir.length()
	var mid = (from + to) / 2
	var base_y = terrain_height(mid.x, mid.z)
	mid.y = base_y + 0.03
	var road = MeshInstance3D.new()
	var r_mesh = BoxMesh.new()
	r_mesh.size = Vector3(length, 0.04, 6)
	road.mesh = r_mesh
	road.position = mid
	road.look_at(to)
	road.rotate_x(PI / 2)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.12, 0.12)
	mat.roughness = 0.95
	road.material_override = mat
	parent.add_child(road)

# ============================================================
# TREES — shared utility
# ============================================================
static func _build_tree(parent: Node3D, x: float, z: float, s: float) -> void:
	var base_y = terrain_height(x, z)
	# Trunk
	var trunk = MeshInstance3D.new()
	var t_mesh = CylinderMesh.new()
	t_mesh.top_radius = 0.2
	t_mesh.bottom_radius = 0.3
	t_mesh.height = 3
	trunk.mesh = t_mesh
	trunk.position = Vector3(x, base_y + 1.5, z)
	var tmat = StandardMaterial3D.new()
	tmat.albedo_color = Color(0.29, 0.23, 0.1)
	tmat.roughness = 0.9
	trunk.material_override = tmat
	trunk.scale = Vector3(s, s, s)
	parent.add_child(trunk)
	# Foliage
	var fol = MeshInstance3D.new()
	var f_mesh = PrismMesh.new()
	f_mesh.size = Vector3(3.6, 4, 3.6)
	fol.mesh = f_mesh
	fol.position = Vector3(x, base_y + 3.5, z)
	var fmat = StandardMaterial3D.new()
	fmat.albedo_color = Color(0.17, 0.29, 0.1)
	fmat.roughness = 0.85
	fol.material_override = fmat
	fol.scale = Vector3(s, s, s)
	parent.add_child(fol)
