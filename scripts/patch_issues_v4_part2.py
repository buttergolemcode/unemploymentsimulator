#!/usr/bin/env python3
"""Fix 3 & 4: real harbor + better rural collision + larger map"""

PATH = "/home/z/my-project/godot/scripts/WorldBuilder.gd"
with open(PATH) as f:
    c = f.read()

# ============ Fix 4a: Larger map (800 -> 1200 playable, 600 -> 900 water offset) ============
old1 = """const MAP_SIZE: float = 800.0           # playable area (-400..+400)
const WATER_OFFSET: float = 400.0       # water starts at this distance from center
const WATER_PLANE_SIZE: float = 1600.0  # large enough to look infinite"""
new1 = """const MAP_SIZE: float = 1200.0          # playable area (-600..+600)
const WATER_OFFSET: float = 600.0       # water starts at this distance from center
const WATER_PLANE_SIZE: float = 2400.0  # large enough to look infinite"""
assert old1 in c, "old1 (map size) not found"
c = c.replace(old1, new1)

# ============ Fix 4b: Better rural collision (denser grid of boxes) ============
old2 = """\t# 2) Rural raised collision (4 boxes at corners, matching terrain_height)
\tvar rural_body = StaticBody3D.new()
\trural_body.name = "RuralGround"
\t# Add multiple collision boxes around the rural perimeter
\tfor angle_deg in range(0, 360, 30):
\t\tvar angle = deg_to_rad(angle_deg)
\t\tvar rx = cos(angle) * 390.0  # radius just inside water
\t\tvar rz = sin(angle) * 390.0
\t\tvar rcol = CollisionShape3D.new()
\t\tvar rshape = BoxShape3D.new()
\t\trshape.size = Vector3(80, 1.0, 80)
\t\trcol.shape = rshape
\t\tvar h_at = terrain_height(rx, rz)
\t\trcol.position = Vector3(rx, h_at - 0.5, rz)
\t\trural_body.add_child(rcol)
\tparent.add_child(rural_body)"""
new2 = """\t# 2) Rural raised collision (DENSE GRID covering entire rural area)
\t# Old approach (12 boxes around perimeter) left gaps where cars fell through.
\t# New approach: grid of 50x50m boxes covering the full rural ring (380-580m radius)
\tvar rural_body = StaticBody3D.new()
\trural_body.name = "RuralGround"
\tvar rural_grid = 50  # 50m spacing
\tfor gx in range(-600, 601, rural_grid):
\t\tfor gz in range(-600, 601, rural_grid):
\t\t\tvar r = sqrt(gx * gx + gz * gz)
\t\t\t# Only place boxes in rural ring (between city edge and water)
\t\t\tif r < 380 or r > 580:
\t\t\t\tcontinue
\t\t\tvar rcol = CollisionShape3D.new()
\t\t\tvar rshape = BoxShape3D.new()
\t\t\trshape.size = Vector3(rural_grid, 1.0, rural_grid)
\t\t\trcol.shape = rshape
\t\t\tvar h_at = terrain_height(gx, gz)
\t\t\trcol.position = Vector3(gx, h_at - 0.5, gz)
\t\t\trural_body.add_child(rcol)
\tparent.add_child(rural_body)"""
assert old2 in c, "old2 (rural collision) not found"
c = c.replace(old2, new2)

# ============ Fix 4c: Update terrain_height for larger map ============
old3 = """static func terrain_height(x: float, z: float) -> float:
\tvar r = sqrt(x * x + z * z)
\t# City area: completely flat
\tif r < 380:
\t\treturn 0.0
\t# Rural edge: gentle hills rising toward mountains
\tif r < WATER_OFFSET:
\t\tvar blend = (r - 380) / (WATER_OFFSET - 380)
\t\treturn _fractal_noise(x, z, 2) * 6 * blend
\t# Water (below sea level)
\treturn -3.0"""
new3 = """static func terrain_height(x: float, z: float) -> float:
\tvar r = sqrt(x * x + z * z)
\t# City area: completely flat (extended for larger map)
\tif r < 580:
\t\treturn 0.0
\t# Rural edge: gentle hills rising toward mountains (extended range)
\tif r < WATER_OFFSET:
\t\tvar blend = (r - 580) / (WATER_OFFSET - 580)
\t\treturn _fractal_noise(x, z, 2) * 8 * blend
\t# Water (below sea level)
\treturn -3.0"""
assert old3 in c, "old3 (terrain_height) not found"
c = c.replace(old3, new3)

# ============ Fix 4d: Update city ground collision for larger map ============
old4 = """\tvar city_shape = BoxShape3D.new()
\tcity_shape.size = Vector3(800, 1.0, 800)  # 800x800 flat ground at y=-0.5"""
new4 = """\tvar city_shape = BoxShape3D.new()
\tcity_shape.size = Vector3(1200, 1.0, 1200)  # 1200x1200 flat ground (covers city + inner rural)"""
assert old4 in c, "old4 (city ground) not found"
c = c.replace(old4, new4)

# ============ Fix 4e: Update mountain walls for larger map ============
old5 = """\t# 3) Mountain walls (impassable barriers at map edges)
\t# North wall (z < -400)
\tvar north_body = StaticBody3D.new()
\tnorth_body.name = "MountainNorth"
\tvar north_col = CollisionShape3D.new()
\tvar north_shape = BoxShape3D.new()
\tnorth_shape.size = Vector3(1200, 100, 200)
\tnorth_col.shape = north_shape
\tnorth_col.position = Vector3(0, 50, -500)
\tnorth_body.add_child(north_col)
\tparent.add_child(north_body)
\t# South wall (z > 400)
\tvar south_body = StaticBody3D.new()
\tsouth_body.name = "MountainSouth"
\tvar south_col = CollisionShape3D.new()
\tvar south_shape = BoxShape3D.new()
\tsouth_shape.size = Vector3(1200, 100, 200)
\tsouth_col.shape = south_shape
\tsouth_col.position = Vector3(0, 50, 500)
\tsouth_body.add_child(south_col)
\tparent.add_child(south_body)
\t# West wall (x < -400)
\tvar west_body = StaticBody3D.new()
\twest_body.name = "MountainWest"
\tvar west_col = CollisionShape3D.new()
\tvar west_shape = BoxShape3D.new()
\twest_shape.size = Vector3(200, 100, 1200)
\twest_col.shape = west_shape
\twest_col.position = Vector3(-500, 50, 0)
\twest_body.add_child(west_col)
\tparent.add_child(west_body)
\t# East harbor wall (low barrier to block ground vehicles from water)
\tvar east_body = StaticBody3D.new()
\teast_body.name = "HarborBarrier"
\tvar east_col = CollisionShape3D.new()
\tvar east_shape = BoxShape3D.new()
\teast_shape.size = Vector3(20, 4, 1200)
\teast_col.shape = east_shape
\teast_col.position = Vector3(410, 2, 0)
\teast_body.add_child(east_col)
\tparent.add_child(east_body)"""
new5 = """\t# 3) Mountain walls (impassable barriers at map edges — extended for larger map)
\t# North wall (z < -600)
\tvar north_body = StaticBody3D.new()
\tnorth_body.name = "MountainNorth"
\tvar north_col = CollisionShape3D.new()
\tvar north_shape = BoxShape3D.new()
\tnorth_shape.size = Vector3(1800, 100, 200)
\tnorth_col.shape = north_shape
\tnorth_col.position = Vector3(0, 50, -700)
\tnorth_body.add_child(north_col)
\tparent.add_child(north_body)
\t# South wall (z > 600)
\tvar south_body = StaticBody3D.new()
\tsouth_body.name = "MountainSouth"
\tvar south_col = CollisionShape3D.new()
\tvar south_shape = BoxShape3D.new()
\tsouth_shape.size = Vector3(1800, 100, 200)
\tsouth_col.shape = south_shape
\tsouth_col.position = Vector3(0, 50, 700)
\tsouth_body.add_child(south_col)
\tparent.add_child(south_body)
\t# West wall (x < -600)
\tvar west_body = StaticBody3D.new()
\twest_body.name = "MountainWest"
\tvar west_col = CollisionShape3D.new()
\tvar west_shape = BoxShape3D.new()
\twest_shape.size = Vector3(200, 100, 1800)
\twest_col.shape = west_shape
\twest_col.position = Vector3(-700, 50, 0)
\twest_body.add_child(west_col)
\tparent.add_child(west_body)
\t# East harbor wall (low barrier at harbor edge)
\tvar east_body = StaticBody3D.new()
\teast_body.name = "HarborBarrier"
\tvar east_col = CollisionShape3D.new()
\tvar east_shape = BoxShape3D.new()
\teast_shape.size = Vector3(20, 4, 1800)
\teast_col.shape = east_shape
\teast_col.position = Vector3(610, 2, 0)
\teast_body.add_child(east_col)
\tparent.add_child(east_body)"""
assert old5 in c, "old5 (mountain walls) not found"
c = c.replace(old5, new5)

# ============ Fix 4f: Update terrain mesh size + water plane ============
old6 = """\tvar size = 900
\tvar segs = 100"""
new6 = """\tvar size = 1400  # larger terrain mesh for bigger map
\tvar segs = 120"""
assert old6 in c, "old6 (terrain mesh size) not found"
c = c.replace(old6, new6)

# ============ Fix 3: Real harbor with docks, ships, harbor basin ============
old7 = """static func _build_dock_props(parent: Node3D) -> void:
\t# Cargo containers in harbor district
\tfor i in range(40):
\t\tvar x = 220 + randf() * 150
\t\tvar z = -250 + randf() * 500
\t\tif get_district_at(x, z) != "harbor":
\t\t\tcontinue
\t\tvar container = MeshInstance3D.new()
\t\tvar c_mesh = BoxMesh.new()
\t\tvar rot = randf() > 0.5
\t\tif rot:
\t\t\tc_mesh.size = Vector3(12, 2.5, 2.5)
\t\telse:
\t\t\tc_mesh.size = Vector3(2.5, 2.5, 12)
\t\tcontainer.mesh = c_mesh
\t\tvar stack_h = int(randf() * 3) * 2.6
\t\tcontainer.position = Vector3(x, 1.3 + stack_h, z)
\t\tvar mat = StandardMaterial3D.new()
\t\tvar colors = ["#dc2626", "#2563eb", "#16a34a", "#eab308", "#ea580c", "#7c3aed"]
\t\tmat.albedo_color = Color.from_string(colors[randi() % colors.size()], Color.GRAY)
\t\tmat.roughness = 0.7
\t\tcontainer.material_override = mat
\t\tparent.add_child(container)
\t# Cargo cranes (visual landmarks at harbor)
\tfor i in range(4):
\t\tvar cx = 230 + i * 30
\t\tvar cz = -100 + (i % 2) * 200
\t\tvar crane = _make_crane()
\t\tcrane.position = Vector3(cx, 0, cz)
\t\tparent.add_child(crane)"""
new7 = """static func _build_dock_props(parent: Node3D) -> void:
\t# === HARBOR BASIN (water inlet for ships) ===
\t# Cut a rectangular basin into the harbor area for ships to dock
\tvar basin = MeshInstance3D.new()
\tvar b_mesh = BoxMesh.new()
\tb_mesh.size = Vector3(200, 0.1, 300)  # 200x300m harbor basin
\tbasin.mesh = b_mesh
\tbasin.position = Vector3(500, -2.5, 0)  # at water level, in harbor area
\tvar basin_mat = StandardMaterial3D.new()
\tbasin_mat.albedo_color = Color(0.05, 0.15, 0.28)  # dark water
\tbasin_mat.roughness = 0.1
\tbasin_mat.metalness = 0.6
\tbasin.material_override = basin_mat
\tparent.add_child(basin)
\t
\t# === DOCKS (concrete piers extending into basin) ===
\t# 3 piers running east-west into the basin
\tfor pier_idx in range(3):
\t\tvar pier_z = -100 + pier_idx * 100  # piers at z = -100, 0, 100
\t\tvar pier = MeshInstance3D.new()
\t\tvar p_mesh = BoxMesh.new()
\t\tp_mesh.size = Vector3(120, 1.0, 20)  # 120m long, 20m wide pier
\t\tpier.mesh = p_mesh
\t\tpier.position = Vector3(500, 0.5, pier_z)  # at water level
\t\tvar pier_mat = StandardMaterial3D.new()
\t\tpier_mat.albedo_color = Color(0.5, 0.5, 0.5)  # concrete gray
\t\tpier_mat.roughness = 0.95
\t\tpier.material_override = pier_mat
\t\tparent.add_child(pier)
\t\t# Collision for pier (so cars can drive on it)
\t\tvar pier_body = StaticBody3D.new()
\t\tpier_body.position = Vector3(500, 0.5, pier_z)
\t\tvar pier_col = CollisionShape3D.new()
\t\tvar pier_shape = BoxShape3D.new()
\t\tpier_shape.size = Vector3(120, 1.0, 20)
\t\tpier_col.shape = pier_shape
\t\tpier_body.add_child(pier_col)
\t\tparent.add_child(pier_body)
\t
\t# === CARGO SHIPS (large box-shaped ships docked at piers) ===
\tfor ship_idx in range(3):
\t\tvar ship_z = -100 + ship_idx * 100
\t\tvar ship = MeshInstance3D.new()
\t\tvar s_mesh = BoxMesh.new()
\t\ts_mesh.size = Vector3(80, 8, 15)  # 80m long, 8m tall, 15m wide ship
\t\tship.mesh = s_mesh
\t\tship.position = Vector3(540, 4, ship_z + 15)  # next to pier, half in water
\t\tvar ship_mat = StandardMaterial3D.new()
\t\tvar ship_colors = ["#1e3a5f", "#1e293b", "#0c4a6e", "#1e3a5f"]
\t\tship_mat.albedo_color = Color.from_string(ship_colors[ship_idx % 4], Color.NAVY)
\t\tship_mat.roughness = 0.4
\t\tship_mat.metalness = 0.5
\t\tship.material_override = ship_mat
\t\tparent.add_child(ship)
\t\t# Ship superstructure (bridge tower)
\t\tvar bridge = MeshInstance3D.new()
\t\tvar br_mesh = BoxMesh.new()
\t\tbr_mesh.size = Vector3(15, 6, 12)
\t\tbridge.mesh = br_mesh
\t\tbridge.position = Vector3(540, 12, ship_z + 15)  # on top of ship
\t\tvar bridge_mat = StandardMaterial3D.new()
\t\tbridge_mat.albedo_color = Color.WHITE
\t\tbridge_mat.roughness = 0.3
\t\tbridge.material_override = bridge_mat
\t\tparent.add_child(bridge)
\t
\t# === CARGO CONTAINERS (stacked on piers, not floating) ===
\tfor i in range(60):
\t\t# Place containers ON the piers (at pier height y=1.5)
\t\tvar pier_idx = i % 3
\t\tvar pier_z = -100 + pier_idx * 100
\t\tvar cx = 460 + (i / 3) % 5 * 12  # along pier length
\t\tvar cz = pier_z + ((i / 3) / 5) % 2 * 6 - 3  # across pier width
\t\tvar container = MeshInstance3D.new()
\t\tvar c_mesh = BoxMesh.new()
\t\tc_mesh.size = Vector3(12, 2.5, 2.5)  # standard container size
\t\tcontainer.mesh = c_mesh
\t\tvar stack_h = int(randf() * 3) * 2.6  # stack 0-2 high
\t\tcontainer.position = Vector3(cx, 1.5 + stack_h, cz)
\t\tvar mat = StandardMaterial3D.new()
\t\tvar colors = ["#dc2626", "#2563eb", "#16a34a", "#eab308", "#ea580c", "#7c3aed", "#0891b2"]
\t\tmat.albedo_color = Color.from_string(colors[randi() % colors.size()], Color.GRAY)
\t\tmat.roughness = 0.7
\t\tcontainer.material_override = mat
\t\tparent.add_child(container)
\t
\t# === CARGO CRANES (large, on piers, loading ships) ===
\tfor i in range(6):
\t\tvar crane_idx = i % 3
\t\tvar crane_z = -100 + crane_idx * 100
\t\tvar crane_x = 480 + (i / 3) * 30
\t\tvar crane = _make_crane()
\t\tcrane.position = Vector3(crane_x, 1.0, crane_z)  # on pier
\t\tparent.add_child(crane)"""
assert old7 in c, "old7 (dock props) not found"
c = c.replace(old7, new7)

# ============ Fix 3b: Update harbor district polygon for larger map ============
old8 = """"harbor": {
\t\t\t"color": "#1c1917", "height_min": 10, "height_max": 25, "ground": "#171717",
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(200, -300), Vector2(400, -300), Vector2(400, 300), Vector2(200, 300)
\t\t\t])
\t\t},"""
new8 = """"harbor": {
\t\t\t"color": "#1c1917", "height_min": 10, "height_max": 25, "ground": "#171717",
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(400, -400), Vector2(600, -400), Vector2(600, 400), Vector2(400, 400)
\t\t\t])
\t\t},"""
assert old8 in c, "old8 (harbor polygon) not found"
c = c.replace(old8, new8)

# ============ Update _build_water for larger map ============
old9 = """static func _build_water(parent: Node3D) -> void:
\tvar plane = PlaneMesh.new()
\tplane.size = Vector2(WATER_PLANE_SIZE, WATER_PLANE_SIZE)
\tvar mat = StandardMaterial3D.new()
\tmat.albedo_color = Color(0.08, 0.22, 0.35, 0.85)
\tmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
\tmat.roughness = 0.15
\tmat.metalness = 0.4
\tplane.material = mat
\tvar mi = MeshInstance3D.new()
\tmi.mesh = plane
\tmi.position = Vector3(800, -3.0, 0)  # east side, below ground
\tparent.add_child(mi)"""
new9 = """static func _build_water(parent: Node3D) -> void:
\t# Sea on east side (harbor) + surrounding ocean
\tvar plane = PlaneMesh.new()
\tplane.size = Vector2(WATER_PLANE_SIZE, WATER_PLANE_SIZE)
\tvar mat = StandardMaterial3D.new()
\tmat.albedo_color = Color(0.08, 0.22, 0.35, 0.85)
\tmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
\tmat.roughness = 0.15
\tmat.metalness = 0.4
\tplane.material = mat
\tvar mi = MeshInstance3D.new()
\tmi.mesh = plane
\tmi.position = Vector3(1200, -3.0, 0)  # east side, larger offset for bigger map
\tparent.add_child(mi)"""
assert old9 in c, "old9 (water) not found"
c = c.replace(old9, new9)

with open(PATH, 'w') as f:
    f.write(c)
print("OK - WorldBuilder.gd: larger map, real harbor, dense rural collision")
