#!/usr/bin/env python3
"""D.4.5a Phase 1: Update map constants, district polygons, scheme positions
for the new 3000m Küstenstadt layout. Keep all other functions intact."""

PATH = "/home/z/my-project/godot/scripts/WorldBuilder.gd"
with open(PATH) as f:
    c = f.read()

# 1. Update header comment
old_header = """# ============================================================
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
#   rural: outside city, farms/forest"""

new_header = """# ============================================================
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
# Mountains: Canyon walls (80-120m, steep) at North/South/West edges"""

assert old_header in c, "old_header not found"
c = c.replace(old_header, new_header)

# 2. Update map constants
old_consts = """const MAP_SIZE: float = 1200.0          # playable area (-600..+600)
const WATER_OFFSET: float = 600.0       # water starts at this distance from center
const WATER_PLANE_SIZE: float = 2400.0  # large enough to look infinite

# Street grid (NYC-style 100m blocks)
const STREET_GRID: Array = [-300, -200, -100, 0, 100, 200, 300]
const ROAD_HALF_WIDTH: float = 4.0       # street is 8m wide (2 lanes of 4m)
const SIDEWALK_WIDTH: float = 2.5       # 2.5m sidewalk on each side (realistic)
const SIDEWALK_HEIGHT: float = 0.15     # raised sidewalk (15cm curb)
const BLOCK_SIZE: float = 80.0          # 80m blocks (was 100m, more NYC-like)
const BUILDING_MARGIN: float = 0.5      # buildings flush with sidewalk (NYC-style)"""

new_consts = """const MAP_SIZE: float = 3000.0          # playable area (-1500..+1500)
const WATER_OFFSET: float = 1500.0      # water starts at x=+1500 (East coast)
const WATER_PLANE_SIZE: float = 3000.0  # ocean size

# Street grid — Downtown only (other districts have different layouts)
const STREET_GRID: Array = [200, 300, 400, 500, 600, 700]
const ROAD_HALF_WIDTH: float = 4.0       # Main Avenue: 8m wide (2 lanes)
const SIDEWALK_WIDTH: float = 2.5       # 2.5m sidewalk on each side
const SIDEWALK_HEIGHT: float = 0.15     # raised sidewalk (15cm curb)
const BLOCK_SIZE: float = 80.0          # 80m blocks in Downtown grid
const BUILDING_MARGIN: float = 0.5      # buildings flush with sidewalk

# Highway constants
const HIGHWAY_HALF_WIDTH: float = 8.0   # 16m wide (4 lanes)
const HIGHWAY_BARRIER: float = 0.5      # center barrier width

# Canyon/Mountain constants
const CANYON_HEIGHT: float = 100.0      # 100m tall canyon walls
const CANYON_EDGE_NORTH: float = -1200.0  # canyon starts at z=-1200
const CANYON_EDGE_SOUTH: float = 1200.0   # canyon starts at z=+1200
const CANYON_EDGE_WEST: float = -1200.0   # canyon starts at x=-1200

# Harbor constants
const HARBOR_BASIN_X: float = 1200.0    # harbor basin center X
const HARBOR_BASIN_W: float = 300.0     # basin width (E-W)
const HARBOR_BASIN_D: float = 600.0     # basin depth (N-S)"""

assert old_consts in c, "old_consts not found"
c = c.replace(old_consts, new_consts)

# 3. Update district polygons (Küstenstreifen layout)
old_districts = """	DISTRICTS = {
		"downtown": {
			"color": "#475569", "height_min": 40, "height_max": 150, "ground": "#1a1a1a",
			"polygon": PackedVector2Array([
				Vector2(-200, -150), Vector2(200, -150), Vector2(200, 200), Vector2(-200, 200)
			])
		},
		"harbor": {
			"color": "#1c1917", "height_min": 10, "height_max": 25, "ground": "#171717",
			"polygon": PackedVector2Array([
				Vector2(400, -400), Vector2(600, -400), Vector2(600, 400), Vector2(400, 400)
			])
		},
		"slums": {
			"color": "#451a03", "height_min": 4, "height_max": 10, "ground": "#1a0f0a",
			"polygon": PackedVector2Array([
				Vector2(-400, 200), Vector2(-200, 200), Vector2(-200, 400), Vector2(-400, 400)
			])
		},
		"industrial": {
			"color": "#1f2937", "height_min": 10, "height_max": 30, "ground": "#161616",
			"polygon": PackedVector2Array([
				Vector2(-400, -400), Vector2(-200, -400), Vector2(-200, -150), Vector2(-400, -150)
			])
		},
		"suburbs": {
			"color": "#525252", "height_min": 5, "height_max": 10, "ground": "#1a2a1a",
			"polygon": PackedVector2Array([
				Vector2(-400, -150), Vector2(-200, -150), Vector2(-200, 200), Vector2(-400, 200)
			])
		},
		"rural": {
			"color": "#6b5b4a", "height_min": 3, "height_max": 6, "ground": "#2a3a1a",
			"polygon": PackedVector2Array([])
		},
	}"""

new_districts = """	DISTRICTS = {
		"downtown": {
			"color": "#475569", "height_min": 40, "height_max": 150, "ground": "#1a1a1a",
			# Downtown: +100..+800 X, -500..+500 Z
			"polygon": PackedVector2Array([
				Vector2(100, -500), Vector2(800, -500), Vector2(800, 500), Vector2(100, 500)
			])
		},
		"harbor": {
			"color": "#1c1917", "height_min": 10, "height_max": 25, "ground": "#171717",
			# Harbor: +600..+1500 X, -600..+600 Z (overlaps downtown east edge for waterfront)
			"polygon": PackedVector2Array([
				Vector2(600, -600), Vector2(1500, -600), Vector2(1500, 600), Vector2(600, 600)
			])
		},
		"slums": {
			"color": "#451a03", "height_min": 4, "height_max": 10, "ground": "#1a0f0a",
			# Slums: +50..+300 X, +300..+800 Z (south of Downtown/Industrial border)
			"polygon": PackedVector2Array([
				Vector2(50, 300), Vector2(300, 300), Vector2(300, 800), Vector2(50, 800)
			])
		},
		"industrial": {
			"color": "#1f2937", "height_min": 10, "height_max": 30, "ground": "#161616",
			# Industrial: -600..+200 X, -500..+500 Z
			"polygon": PackedVector2Array([
				Vector2(-600, -500), Vector2(200, -500), Vector2(200, 500), Vector2(-600, 500)
			])
		},
		"suburbs": {
			"color": "#525252", "height_min": 5, "height_max": 10, "ground": "#1a2a1a",
			# Suburbs: -1000..-400 X, -500..+500 Z
			"polygon": PackedVector2Array([
				Vector2(-1000, -500), Vector2(-400, -500), Vector2(-400, 500), Vector2(-1000, 500)
			])
		},
		"rural": {
			"color": "#6b5b4a", "height_min": 3, "height_max": 6, "ground": "#2a3a1a",
			# Rural: everything west of -800 (between suburbs and canyon walls)
			"polygon": PackedVector2Array([
				Vector2(-1200, -1200), Vector2(-800, -1200), Vector2(-800, 1200), Vector2(-1200, 1200)
			])
		},
	}"""

assert old_districts in c, "old_districts not found"
c = c.replace(old_districts, new_districts)

# 4. Update scheme building positions for new layout
old_schemes = """const SCHEME_BUILDINGS: Array = [
	# Downtown (center) — tall skyscrapers (40-120m)
	{"id": "trading", "name": "Trading Floor", "emoji": "📈",
	 "x": -50, "z": -50, "w": 25, "d": 22, "h": 70, "color": "#22d3ee"},
	{"id": "wirefraud", "name": "Corporate Tower", "emoji": "💸",
	 "x": 50, "z": -50, "w": 30, "d": 25, "h": 120, "color": "#64748b"},
	{"id": "taxfraud", "name": "Accountant Office", "emoji": "🧾",
	 "x": -150, "z": 50, "w": 18, "d": 16, "h": 35, "color": "#eab308"},
	{"id": "gambling", "name": "Casino", "emoji": "🎰",
	 "x": 150, "z": 100, "w": 25, "d": 22, "h": 28, "color": "#f59e0b"},
	# Slums (SW) — small rundown houses (4-8m)
	{"id": "drugs", "name": "Trap House", "emoji": "💊",
	 "x": -350, "z": 250, "w": 10, "d": 8, "h": 6, "color": "#a855f7"},
	{"id": "scam", "name": "Internet Cafe", "emoji": "🎣",
	 "x": -250, "z": 350, "w": 8, "d": 7, "h": 5, "color": "#ec4899"},
	{"id": "robbery", "name": "Corner Store", "emoji": "🔫",
	 "x": -350, "z": 350, "w": 7, "d": 7, "h": 4, "color": "#ef4444"},
	# Industrial (NW) — large warehouse (15m)
	{"id": "ecom", "name": "E-Com Warehouse", "emoji": "📦",
	 "x": -350, "z": -250, "w": 25, "d": 22, "h": 15, "color": "#4ade80"},
]"""

new_schemes = """const SCHEME_BUILDINGS: Array = [
	# Downtown (+100..+800 X) — tall skyscrapers (40-150m)
	{"id": "trading", "name": "Trading Floor", "emoji": "📈",
	 "x": 300, "z": -100, "w": 25, "d": 22, "h": 70, "color": "#22d3ee"},
	{"id": "wirefraud", "name": "Corporate Tower", "emoji": "💸",
	 "x": 500, "z": 100, "w": 30, "d": 25, "h": 120, "color": "#64748b"},
	{"id": "taxfraud", "name": "Accountant Office", "emoji": "🧾",
	 "x": 200, "z": 200, "w": 18, "d": 16, "h": 35, "color": "#eab308"},
	{"id": "gambling", "name": "Casino", "emoji": "🎰",
	 "x": 600, "z": -200, "w": 25, "d": 22, "h": 28, "color": "#f59e0b"},
	# Slums (+50..+300 X, +300..+800 Z) — container-slum buildings (4-8m)
	{"id": "drugs", "name": "Trap House", "emoji": "💊",
	 "x": 100, "z": 500, "w": 10, "d": 8, "h": 6, "color": "#a855f7"},
	{"id": "scam", "name": "Internet Cafe", "emoji": "🎣",
	 "x": 50, "z": 600, "w": 8, "d": 7, "h": 5, "color": "#ec4899"},
	{"id": "robbery", "name": "Corner Store", "emoji": "🔫",
	 "x": 150, "z": 550, "w": 7, "d": 7, "h": 4, "color": "#ef4444"},
	# Industrial (-600..+200 X) — large warehouse (15m)
	{"id": "ecom", "name": "E-Com Warehouse", "emoji": "📦",
	 "x": -200, "z": -100, "w": 25, "d": 22, "h": 15, "color": "#4ade80"},
]"""

assert old_schemes in c, "old_schemes not found"
c = c.replace(old_schemes, new_schemes)

# 5. Update terrain_height for new 3000m map
old_terrain = """static func terrain_height(x: float, z: float) -> float:
	var r = sqrt(x * x + z * z)
	# City area: EXACTLY flat (no noise — prevents z-fighting with asphalt/sidewalk)
	if r < 580:
		return 0.0
	# Rural edge: gentle hills rising toward mountains (extended range)
	if r < WATER_OFFSET:
		var blend = (r - 580) / (WATER_OFFSET - 580)
		return _fractal_noise(x, z, 2) * 8 * blend
	# Water (below sea level)
	return -3.0"""

new_terrain = """static func terrain_height(x: float, z: float) -> float:
	# City area (Downtown to Harbor): completely flat
	if x > -800 and x < 1500 and z > -600 and z < 600:
		return 0.0
	# Rural zone: hills rising toward canyon walls
	if x > -1200 and x < -800:
		var blend = clamp((-800 - x) / 400.0, 0, 1)
		return _fractal_noise(x, z, 2) * 10 * blend
	# Beyond canyon edges: mountain height
	if x < CANYON_EDGE_WEST or z < CANYON_EDGE_NORTH or z > CANYON_EDGE_SOUTH:
		var dist = 0.0
		if x < CANYON_EDGE_WEST:
			dist = max(dist, CANYON_EDGE_WEST - x)
		if z < CANYON_EDGE_NORTH:
			dist = max(dist, CANYON_EDGE_NORTH - z)
		if z > CANYON_EDGE_SOUTH:
			dist = max(dist, z - CANYON_EDGE_SOUTH)
		return CANYON_HEIGHT * clamp(dist / 300.0, 0, 1) + _fractal_noise(x, z, 3) * 20
	# Water (east of harbor)
	if x > WATER_OFFSET:
		return -3.0 - clamp((x - WATER_OFFSET) / 200.0, 0, 1) * 15
	return 0.0"""

assert old_terrain in c, "old_terrain not found"
c = c.replace(old_terrain, new_terrain)

# 6. Update get_district_at for new layout (rural is now a polygon, not "everything else")
old_get_district = """static func get_district_at(x: float, z: float) -> String:
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
	return "water\""""

new_get_district = """static func get_district_at(x: float, z: float) -> String:
	_init_districts()
	var point = Vector2(x, z)
	# Check all districts including rural (now has a polygon)
	for district_name in ["downtown", "harbor", "slums", "industrial", "suburbs", "rural"]:
		var district = DISTRICTS[district_name]
		var polygon = district.get("polygon", PackedVector2Array())
		if polygon.size() >= 3 and Geometry2D.is_point_in_polygon(point, polygon):
			return district_name
	# Water (east of coast)
	if x > WATER_OFFSET:
		return "water"
	# Canyon/mountains (beyond playable area)
	return "canyon\""""

assert old_get_district in c, "old_get_district not found"
c = c.replace(old_get_district, new_get_district)

with open(PATH, 'w') as f:
    f.write(c)
print("OK — Map constants, districts, scheme positions, terrain, get_district_at updated for 3000m Küstenstadt")
