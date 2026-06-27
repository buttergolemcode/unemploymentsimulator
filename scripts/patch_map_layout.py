#!/usr/bin/env python3
"""Update WorldBuilder.gd with new canyon/coastal map layout:
- Larger 1000x1000 city area
- Mountains N/S as walls
- Big harbor in East
- Full terrain collision (HeightmapShape3D)
- Updated district polygons
- New scheme building positions
- Landmarks
"""

PATH = "/home/z/my-project/godot/scripts/WorldBuilder.gd"

with open(PATH) as f:
    c = f.read()

# 1. Replace _init_districts with new large layout
old1 = '''static func _init_districts() -> void:
\tif not DISTRICTS.is_empty():
\t\treturn  # already initialized
\tDISTRICTS = {
\t\t"downtown": {
\t\t\t"color": "#475569", "height_min": 24, "height_max": 80, "ground": "#1a1a1a",
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(-80, -80), Vector2(80, -80), Vector2(80, 80), Vector2(-80, 80)
\t\t\t])
\t\t},
\t\t"harbor": {
\t\t\t"color": "#1c1917", "height_min": 8, "height_max": 22, "ground": "#171717",
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(80, -100), Vector2(260, -100), Vector2(260, 180),
\t\t\t\tVector2(180, 180), Vector2(180, -60), Vector2(80, -60), Vector2(80, 80), Vector2(120, 80)
\t\t\t])
\t\t},
\t\t"slums": {
\t\t\t"color": "#451a03", "height_min": 5, "height_max": 14, "ground": "#1a0f0a",
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(-180, 40), Vector2(-80, 40), Vector2(-80, 180), Vector2(-180, 180)
\t\t\t])
\t\t},
\t\t"industrial": {
\t\t\t"color": "#1f2937", "height_min": 9, "height_max": 24, "ground": "#161616",
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(-180, -120), Vector2(-80, -120), Vector2(-80, 40), Vector2(-180, 40)
\t\t\t])
\t\t},
\t\t"suburbs": {
\t\t\t"color": "#525252", "height_min": 4, "height_max": 9, "ground": "#1a2a1a",
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(-180, -120), Vector2(-80, -120), Vector2(-80, 40), Vector2(-180, 40),
\t\t\t\tVector2(80, -80), Vector2(120, -80), Vector2(120, 80), Vector2(80, 80)
\t\t\t])
\t\t},
\t\t"rural": {
\t\t\t"color": "#6b5b4a", "height_min": 3, "height_max": 6, "ground": "#2a3a1a",
\t\t\t"polygon": PackedVector2Array([])
\t\t},
\t}'''

new1 = '''static func _init_districts() -> void:
\tif not DISTRICTS.is_empty():
\t\treturn  # already initialized
\t# Canyon/coastal layout: 1000x1000 city area (-500 to +500)
\t# Mountains N/S, sea in east, forest in west
\tDISTRICTS = {
\t\t"downtown": {
\t\t\t"color": "#475569", "height_min": 24, "height_max": 80, "ground": "#1a1a1a",
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(-150, -150), Vector2(200, -150), Vector2(200, 150), Vector2(-150, 150)
\t\t\t])
\t\t},
\t\t"harbor": {
\t\t\t"color": "#1c1917", "height_min": 8, "height_max": 22, "ground": "#171717",
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(200, -300), Vector2(500, -300), Vector2(500, 300), Vector2(200, 300)
\t\t\t])
\t\t},
\t\t"slums": {
\t\t\t"color": "#451a03", "height_min": 5, "height_max": 14, "ground": "#1a0f0a",
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(-150, 150), Vector2(500, 150), Vector2(500, 400), Vector2(-150, 400)
\t\t\t])
\t\t},
\t\t"industrial": {
\t\t\t"color": "#1f2937", "height_min": 9, "height_max": 24, "ground": "#161616",
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(-150, -400), Vector2(200, -400), Vector2(200, -150), Vector2(-150, -150)
\t\t\t])
\t\t},
\t\t"suburbs": {
\t\t\t"color": "#525252", "height_min": 4, "height_max": 9, "ground": "#1a2a1a",
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(-500, -400), Vector2(-150, -400), Vector2(-150, -150), Vector2(-500, -150)
\t\t\t])
\t\t},
\t\t"rural": {
\t\t\t"color": "#6b5b4a", "height_min": 3, "height_max": 6, "ground": "#2a3a1a",
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(-500, -150), Vector2(-150, -150), Vector2(-150, 150), Vector2(-500, 150)
\t\t\t])
\t\t},
\t\t"military": {
\t\t\t"color": "#3f3f1f", "height_min": 6, "height_max": 15, "ground": "#1a1a0a",
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(-500, 150), Vector2(-150, 150), Vector2(-150, 400), Vector2(-500, 400)
\t\t\t])
\t\t},
\t}'''

assert old1 in c, "old1 not found"
c = c.replace(old1, new1)

# 2. Update constants for larger map
old2 = '''const CITY_RADIUS = 80.0  # legacy — used by terrain_height
const WORLD_RADIUS = 250.0
const ROAD_HALF_MAIN = 8.0
const ROAD_HALF_SIDE = 5.5
const SIDEWALK = 3.0

# Water starts at this X coordinate (east edge of city)
const WATER_X_START = 180.0'''

new2 = '''const CITY_RADIUS = 500.0  # half-extent of city area
const WORLD_RADIUS = 800.0  # half-extent of total world (incl. mountains)
const ROAD_HALF_MAIN = 10.0
const ROAD_HALF_SIDE = 6.0
const SIDEWALK = 3.0

# Water starts at this X coordinate (east edge of city)
const WATER_X_START = 500.0
# Mountain walls start at these Z coordinates
const MOUNTAIN_NORTH_Z = -400.0
const MOUNTAIN_SOUTH_Z = 400.0
# Mountain height
const MOUNTAIN_HEIGHT = 80.0'''

assert old2 in c, "old2 not found"
c = c.replace(old2, new2)

# 3. Update scheme building positions for new layout
old3 = '''const SCHEME_BUILDINGS: Array = [
\t# Downtown — financial/entertainment district (center)
\t{"id": "trading", "name": "Trading Floor", "emoji": "📈",
\t "x": -40, "z": -40, "w": 14, "d": 12, "h": 42, "color": "#22d3ee"},
\t{"id": "wirefraud", "name": "Corporate Tower", "emoji": "💸",
\t "x": 30, "z": -50, "w": 18, "d": 16, "h": 80, "color": "#64748b"},
\t{"id": "taxfraud", "name": "Accountant Office", "emoji": "🧾",
\t "x": -60, "z": -10, "w": 12, "d": 10, "h": 24, "color": "#eab308"},
\t{"id": "gambling", "name": "Casino", "emoji": "🎰",
\t "x": 50, "z": 30, "w": 16, "d": 14, "h": 14, "color": "#f59e0b"},
\t# Slums — drugs/scam/robbery (SW)
\t{"id": "drugs", "name": "Trap House", "emoji": "💊",
\t "x": -150, "z": 80, "w": 10, "d": 9, "h": 9, "color": "#a855f7"},
\t{"id": "scam", "name": "Internet Cafe", "emoji": "🎣",
\t "x": -120, "z": 140, "w": 9, "d": 8, "h": 7, "color": "#ec4899"},
\t{"id": "robbery", "name": "Corner Store", "emoji": "🔫",
\t "x": -160, "z": 150, "w": 8, "d": 8, "h": 5, "color": "#ef4444"},
\t# Industrial — e-com warehouse (NW)
\t{"id": "ecom", "name": "E-Com Warehouse", "emoji": "📦",
\t "x": -130, "z": -60, "w": 16, "d": 14, "h": 11, "color": "#4ade80"},
]'''

new3 = '''const SCHEME_BUILDINGS: Array = [
\t# Downtown — financial/entertainment district (center, -150..200 x -150..150)
\t{"id": "trading", "name": "Trading Floor", "emoji": "📈",
\t "x": -50, "z": -50, "w": 16, "d": 14, "h": 50, "color": "#22d3ee"},
\t{"id": "wirefraud", "name": "Corporate Tower", "emoji": "💸",
\t "x": 100, "z": -80, "w": 22, "d": 20, "h": 100, "color": "#64748b"},
\t{"id": "taxfraud", "name": "Accountant Office", "emoji": "🧾",
\t "x": -100, "z": 50, "w": 14, "d": 12, "h": 28, "color": "#eab308"},
\t{"id": "gambling", "name": "Casino", "emoji": "🎰",
\t "x": 150, "z": 80, "w": 20, "d": 18, "h": 18, "color": "#f59e0b"},
\t# Slums — drugs/scam/robbery (south, -150..500 x 150..400)
\t{"id": "drugs", "name": "Trap House", "emoji": "💊",
\t "x": -50, "z": 250, "w": 12, "d": 10, "h": 10, "color": "#a855f7"},
\t{"id": "scam", "name": "Internet Cafe", "emoji": "🎣",
\t "x": 200, "z": 250, "w": 10, "d": 9, "h": 8, "color": "#ec4899"},
\t{"id": "robbery", "name": "Corner Store", "emoji": "🔫",
\t "x": -100, "z": 320, "w": 9, "d": 9, "h": 6, "color": "#ef4444"},
\t# Industrial — e-com warehouse (north of downtown)
\t{"id": "ecom", "name": "E-Com Warehouse", "emoji": "📦",
\t "x": 50, "z": -250, "w": 20, "d": 18, "h": 14, "color": "#4ade80"},
]'''

assert old3 in c, "old3 not found"
c = c.replace(old3, new3)

# 4. Update terrain_height for new large map (mountains N/S, sea east, flat city)
old4 = '''static func terrain_height(x: float, z: float) -> float:
\tvar r = sqrt(x * x + z * z)
\tif r < 80:
\t\treturn 0.0
\tvar blend = clamp((r - 80) / 20, 0, 1)
\tvar h = 0.0
\tif r < 150:
\t\th = _fractal_noise(x, z, 1) * 4
\telif r < 220:
\t\th = 5 + _fractal_noise(x, z, 2) * 15
\telse:
\t\tif z < -120:
\t\t\tvar mf = max(0, (r - 220) / 30)
\t\t\th = 25 + _fractal_noise(x, z, 3) * 30 * min(1, mf)
\t\telif z > 120:
\t\t\th = -2 - max(0, (r - 220) / 20) * 8
\t\telse:
\t\t\th = 10 + _fractal_noise(x, z, 2) * 15
\treturn h * blend'''

new4 = '''static func terrain_height(x: float, z: float) -> float:
\t# Flat city area (-500..500 in both axes) at y=0
\t# Mountains rise sharply at N (z < -400) and S (z > 400)
\t# Sea floor drops east of x=500
\t# Forest/west has gentle hills
\tvar h = 0.0
\t# North mountain wall (z < -400)
\tif z < MOUNTAIN_NORTH_Z:
\t\tvar dist_into_mountain = MOUNTAIN_NORTH_Z - z  # positive
\t\th = MOUNTAIN_HEIGHT * clamp(dist_into_mountain / 200.0, 0, 1)
\t\th += _fractal_noise(x, z, 3) * 20  # rugged surface
\t# South mountain wall (z > 400)
\telif z > MOUNTAIN_SOUTH_Z:
\t\tvar dist_into_mountain = z - MOUNTAIN_SOUTH_Z
\t\th = MOUNTAIN_HEIGHT * clamp(dist_into_mountain / 200.0, 0, 1)
\t\th += _fractal_noise(x, z, 3) * 20
\t# Sea floor (east of city, x > 500)
\telif x > WATER_X_START:
\t\tvar dist_into_sea = x - WATER_X_START
\t\th = -3.0 - clamp(dist_into_sea / 100.0, 0, 1) * 15  # drops to -18m
\t# Forest area (west of city, x < -500)
\telif x < -CITY_RADIUS:
\t\tvar dist_into_forest = -CITY_RADIUS - x
\t\th = _fractal_noise(x, z, 2) * 5  # gentle forest hills
\t\th += clamp(dist_into_forest / 200.0, 0, 1) * 15  # rises toward mountains
\t# City area: flat with tiny noise for texture
\telse:
\t\th = _fractal_noise(x, z, 1) * 0.3  # almost flat, just texture
\treturn h'''

assert old4 in c, "old4 not found"
c = c.replace(old4, new4)

# 5. Update _build_water for larger sea in east
old5 = '''static func _build_water(parent: Node3D) -> void:
\t# Water plane on the east side of the map (harbor district waterfront)
\t# Spans from x=180 (city edge) to x=600 (map edge)
\tvar plane = PlaneMesh.new()
\tplane.size = Vector2(420, 600)  # 420 wide (east), 600 deep (north-south)
\tvar mat = StandardMaterial3D.new()
\tmat.albedo_color = Color(0.1, 0.29, 0.42, 0.75)
\tmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
\tmat.roughness = 0.2
\tmat.metalness = 0.3
\tplane.material = mat
\tvar mi = MeshInstance3D.new()
\tmi.mesh = plane
\t# Center the water plane at x = (180 + 600) / 2 = 390
\tmi.position = Vector3(390, -0.8, 0)
\tparent.add_child(mi)'''

new5 = '''static func _build_water(parent: Node3D) -> void:
\t# Large sea in the east, starts at x=500 (WATER_X_START)
\t# Spans from x=500 to x=1100 (600m wide), -500 to +500 in z (1000m long)
\tvar plane = PlaneMesh.new()
\tplane.size = Vector2(600, 1000)
\tvar mat = StandardMaterial3D.new()
\tmat.albedo_color = Color(0.08, 0.25, 0.4, 0.85)
\tmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
\tmat.roughness = 0.15
\tmat.metalness = 0.4
\tplane.material = mat
\tvar mi = MeshInstance3D.new()
\tmi.mesh = plane
\t# Center at x = (500 + 1100) / 2 = 800
\tmi.position = Vector3(800, -1.5, 0)
\tparent.add_child(mi)
\t# Add submerged terrain below water for visual depth
\tvar sea_floor = PlaneMesh.new()
\tsea_floor.size = Vector2(600, 1000)
\tvar sf_mat = StandardMaterial3D.new()
\tsf_mat.albedo_color = Color(0.05, 0.1, 0.15)
\tsf_mat.roughness = 1.0
\tsea_floor.material = sf_mat
\tvar sf_mi = MeshInstance3D.new()
\tsf_mi.mesh = sea_floor
\tsf_mi.position = Vector3(800, -8, 0)
\tparent.add_child(sf_mi)'''

assert old5 in c, "old5 not found"
c = c.replace(old5, new5)

with open(PATH, 'w') as f:
    f.write(c)
print("OK - district polygons, scheme buildings, terrain, water all updated")
