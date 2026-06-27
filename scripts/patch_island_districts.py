#!/usr/bin/env python3
"""
D.4.5a: Rewrite District system for island map.
- Replace 6 old districts with 4 island regions (portofino, nyc, harbor, slums_suburbs)
- Remove canyon/industrial/rural
- Update MAP_SIZE to 2500 (matches heightmap)
- Update scheme building positions
- Update get_district_at
- Remove old canyon collision walls
"""

PATH = "/home/z/my-project/godot/scripts/WorldBuilder.gd"
with open(PATH) as f:
    c = f.read()

# 1. Update map constants — remove canyon, sync size
old_consts = """const MAP_SIZE: float = 3000.0          # playable area (-1500..+1500)
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

new_consts = """const MAP_SIZE: float = 2500.0          # playable area (-1250..+1250)
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
const HARBOR_BASIN_D: float = 300.0     # basin depth"""

assert old_consts in c, "old_consts not found"
c = c.replace(old_consts, new_consts)

# 2. Replace all 6 districts with 4 island regions
old_districts_start = "\tDISTRICTS = {"
old_districts_end = "\t}"

# Find the district block
start_idx = c.index(old_districts_start)
end_idx = c.index(old_districts_end, start_idx) + len(old_districts_end)

new_districts = """\tDISTRICTS = {
\t\t"portofino": {
\t\t\t"color": "#d4a574", "height_min": 8, "height_max": 20, "ground": "#8a7a5a",
\t\t\t# Portofino: NE part of island (x > -50, z < 100)
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(-50, -800), Vector2(800, -800), Vector2(800, 100), Vector2(-50, 100)
\t\t\t])
\t\t},
\t\t"nyc": {
\t\t\t"color": "#1e293b", "height_min": 40, "height_max": 150, "ground": "#1a1a1a",
\t\t\t# NYC Downtown: center of island (-200..+300 X, -300..+400 Z)
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(-200, -300), Vector2(300, -300), Vector2(300, 400), Vector2(-200, 400)
\t\t\t])
\t\t},
\t\t"harbor": {
\t\t\t"color": "#1c1917", "height_min": 8, "height_max": 20, "ground": "#171717",
\t\t\t# Harbor: SE part of island (x > 100, z > 100)
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(100, 100), Vector2(800, 100), Vector2(800, 800), Vector2(100, 800)
\t\t\t])
\t\t},
\t\t"slums_suburbs": {
\t\t\t"color": "#5a4030", "height_min": 4, "height_max": 12, "ground": "#2a2a1a",
\t\t\t# Slums/Suburbs: W/NW part of island (x < -100)
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(-800, -800), Vector2(-100, -800), Vector2(-100, 800), Vector2(-800, 800)
\t\t\t])
\t\t},
\t}"""

c = c[:start_idx] + new_districts + c[end_idx:]

# 3. Update scheme building positions for island layout
old_schemes = """const SCHEME_BUILDINGS: Array = [
\t# Downtown (+100..+800 X) — tall skyscrapers (40-150m)
\t{"id": "trading", "name": "Trading Floor", "emoji": "📈",
\t "x": 300, "z": -100, "w": 25, "d": 22, "h": 70, "color": "#22d3ee"},
\t{"id": "wirefraud", "name": "Corporate Tower", "emoji": "💸",
\t "x": 500, "z": 100, "w": 30, "d": 25, "h": 120, "color": "#64748b"},
\t{"id": "taxfraud", "name": "Accountant Office", "emoji": "🧾",
\t "x": 200, "z": 200, "w": 18, "d": 16, "h": 35, "color": "#eab308"},
\t{"id": "gambling", "name": "Casino", "emoji": "🎰",
\t "x": 600, "z": -200, "w": 25, "d": 22, "h": 28, "color": "#f59e0b"},
\t# Slums (+50..+300 X, +300..+800 Z) — container-slum buildings (4-8m)
\t{"id": "drugs", "name": "Trap House", "emoji": "💊",
\t "x": 100, "z": 500, "w": 10, "d": 8, "h": 6, "color": "#a855f7"},
\t{"id": "scam", "name": "Internet Cafe", "emoji": "🎣",
\t "x": 50, "z": 600, "w": 8, "d": 7, "h": 5, "color": "#ec4899"},
\t{"id": "robbery", "name": "Corner Store", "emoji": "🔫",
\t "x": 150, "z": 550, "w": 7, "d": 7, "h": 4, "color": "#ef4444"},
\t# Industrial (-600..+200 X) — large warehouse (15m)
\t{"id": "ecom", "name": "E-Com Warehouse", "emoji": "📦",
\t "x": -200, "z": -100, "w": 25, "d": 22, "h": 15, "color": "#4ade80"},
]"""

new_schemes = """const SCHEME_BUILDINGS: Array = [
\t# NYC Downtown (center) — tall skyscrapers (40-150m)
\t{"id": "trading", "name": "Trading Floor", "emoji": "📈",
\t "x": 50, "z": -50, "w": 25, "d": 22, "h": 70, "color": "#22d3ee"},
\t{"id": "wirefraud", "name": "Corporate Tower", "emoji": "💸",
\t "x": 150, "z": 50, "w": 30, "d": 25, "h": 120, "color": "#64748b"},
\t{"id": "taxfraud", "name": "Accountant Office", "emoji": "🧾",
\t "x": -100, "z": 100, "w": 18, "d": 16, "h": 35, "color": "#eab308"},
\t{"id": "gambling", "name": "Casino", "emoji": "🎰",
\t "x": 200, "z": -100, "w": 25, "d": 22, "h": 28, "color": "#f59e0b"},
\t# Slums (W/NW) — container-slum buildings (4-8m)
\t{"id": "drugs", "name": "Trap House", "emoji": "💊",
\t "x": -400, "z": 200, "w": 10, "d": 8, "h": 6, "color": "#a855f7"},
\t{"id": "scam", "name": "Internet Cafe", "emoji": "🎣",
\t "x": -500, "z": 300, "w": 8, "d": 7, "h": 5, "color": "#ec4899"},
\t{"id": "robbery", "name": "Corner Store", "emoji": "🔫",
\t "x": -350, "z": 350, "w": 7, "d": 7, "h": 4, "color": "#ef4444"},
\t# NYC Downtown — large warehouse (15m)
\t{"id": "ecom", "name": "E-Com Warehouse", "emoji": "📦",
\t "x": -50, "z": 200, "w": 25, "d": 22, "h": 15, "color": "#4ade80"},
]"""

assert old_schemes in c, "old_schemes not found"
c = c.replace(old_schemes, new_schemes)

# 4. Update get_district_at — 4 regions + sea
old_get = """static func get_district_at(x: float, z: float) -> String:
\t_init_districts()
\tvar point = Vector2(x, z)
\t# Check all districts including rural (now has a polygon)
\tfor district_name in ["downtown", "harbor", "slums", "industrial", "suburbs", "rural"]:
\t\tvar district = DISTRICTS[district_name]
\t\tvar polygon = district.get("polygon", PackedVector2Array())
\t\tif polygon.size() >= 3 and Geometry2D.is_point_in_polygon(point, polygon):
\t\t\treturn district_name
\t# Water (east of coast)
\tif x > WATER_OFFSET:
\t\treturn "water"
\t# Canyon/mountains (beyond playable area)
\treturn "canyon\""""

new_get = """static func get_district_at(x: float, z: float) -> String:
\t_init_districts()
\tvar point = Vector2(x, z)
\tfor district_name in ["portofino", "nyc", "harbor", "slums_suburbs"]:
\t\tvar district = DISTRICTS[district_name]
\t\tvar polygon = district.get("polygon", PackedVector2Array())
\t\tif polygon.size() >= 3 and Geometry2D.is_point_in_polygon(point, polygon):
\t\t\treturn district_name
\t# Off-island = sea
\treturn "sea\""""

assert old_get in c, "old_get not found"
c = c.replace(old_get, new_get)

# 5. Update HEIGHTMAP_WORLD_SIZE
c = c.replace("const HEIGHTMAP_WORLD_SIZE: float = 3000.0",
              "const HEIGHTMAP_WORLD_SIZE: float = 2500.0")

# 6. Remove old canyon collision walls (mountain bodies)
# Find and remove north/south/west/east mountain bodies
import re
# Remove the mountain wall collision section
mountain_pattern = r'\t# 3\) Mountain walls.*?(?=\tvar east_body|parent\.add_child\(mi\))'
c = re.sub(mountain_pattern, '\t# Mountain walls removed — island uses sea as border\n\n', c, flags=re.DOTALL)

# Remove east harbor barrier too
east_pattern = r'\t# East harbor barrier.*?(?=parent\.add_child\(mi\))'
c = re.sub(east_pattern, '', c, flags=re.DOTALL)

with open(PATH, 'w') as f:
    f.write(c)
print("OK — Districts, scheme positions, get_district_at, constants updated for island")
