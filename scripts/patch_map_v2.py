#!/usr/bin/env python3
"""Comprehensive map redesign:
1. Simplified road system (only 3 main avenues per axis, no 50m grid)
2. Block-based building placement (clear separation streets/buildings)
3. Proper terrain collision (HeightmapShape3D)
4. Pro-district building styles (different shapes/colors per district)
"""

PATH = "/home/z/my-project/godot/scripts/WorldBuilder.gd"

with open(PATH) as f:
    c = f.read()

# ============================================================
# 1. Replace _build_roads — simplified, only 3 main avenues per axis
# ============================================================
old1 = '''static func _build_roads(parent: Node3D) -> void:
\t# Main avenues (4-lane) cross at the city center
\t# East-West main roads at z = -100, z = +100
\t# North-South main roads at x = -100, x = +100
\tfor pos in [-100, 100]:
\t\t_make_road(parent, "x", pos, ROAD_HALF_MAIN, SIDEWALK, true)
\t\t_make_road(parent, "z", pos, ROAD_HALF_MAIN, SIDEWALK, true)
\t
\t# Secondary streets (2-lane) every 50m in the city grid
\tfor p in range(-300, 301, 50):
\t\tif abs(p) == 100:
\t\t\tcontinue  # already done as main avenue
\t\tif abs(p) > 350:
\t\t\tcontinue  # outside city
\t\t_make_road(parent, "x", p, ROAD_HALF_SIDE, SIDEWALK, false)
\t\t_make_road(parent, "z", p, ROAD_HALF_SIDE, SIDEWALK, false)'''

new1 = '''static func _build_roads(parent: Node3D) -> void:
\t# Clean road system: 3 main avenues per axis (at -200, 0, +200)
\t# These define clear city blocks of 200x200m each
\t# No more 50m street grid that made everything look like a checkerboard
\tvar avenue_positions = [-200, 0, 200]
\tfor pos in avenue_positions:
\t\t_make_road(parent, "x", pos, ROAD_HALF_MAIN, SIDEWALK, true)
\t\t_make_road(parent, "z", pos, ROAD_HALF_MAIN, SIDEWALK, true)'''

assert old1 in c, "old1 (build_roads) not found"
c = c.replace(old1, new1)

# ============================================================
# 2. Replace _is_on_road — match new avenue layout
# ============================================================
old2 = '''static func _is_on_road(x: float, z: float) -> bool:
\t# Main avenues at ±100
\tfor pos in [-100, 100]:
\t\tif abs(z - pos) < ROAD_HALF_MAIN + SIDEWALK and abs(x) < 360:
\t\t\treturn true
\t\tif abs(x - pos) < ROAD_HALF_MAIN + SIDEWALK and abs(z) < 360:
\t\t\treturn true
\t# Secondary streets every 50m
\tfor p in range(-300, 301, 50):
\t\tif p == -100 or p == 100:
\t\t\tcontinue
\t\tif abs(z - p) < ROAD_HALF_SIDE + SIDEWALK and abs(x) < 360:
\t\t\treturn true
\t\tif abs(x - p) < ROAD_HALF_SIDE + SIDEWALK and abs(z) < 360:
\t\t\treturn true
\treturn false'''

new2 = '''static func _is_on_road(x: float, z: float) -> bool:
\t# Main avenues at -200, 0, +200 (with sidewalk buffer)
\tvar road_buffer = ROAD_HALF_MAIN + SIDEWALK
\tfor pos in [-200, 0, 200]:
\t\tif abs(z - pos) < road_buffer and abs(x) < 380:
\t\t\treturn true
\t\tif abs(x - pos) < road_buffer and abs(z) < 380:
\t\t\treturn true
\treturn false'''

assert old2 in c, "old2 (is_on_road) not found"
c = c.replace(old2, new2)

# ============================================================
# 3. Replace _build_filler_buildings — block-based placement
# ============================================================
old3 = '''static func _build_filler_buildings(parent: Node3D) -> void:
\t# Place buildings on a grid, skipping roads and scheme-building areas
\t# Dense layout: 15m grid (was 25m), smaller gaps, bigger buildings
\tvar grid = 15  # 15m grid spacing (denser than 25m)
\tvar half = 380  # cover city area
\tfor gx in range(-half, half + 1, grid):
\t\tfor gz in range(-half, half + 1, grid):
\t\t\tvar cx = gx + grid / 2.0
\t\t\tvar cz = gz + grid / 2.0
\t\t\tvar r = sqrt(cx * cx + cz * cz)
\t\t\tif r > 390:
\t\t\t\tcontinue  # outside city
\t\t\tif _is_on_road(cx, cz):
\t\t\t\tcontinue
\t\t\t# Skip near scheme buildings
\t\t\tvar too_close = false
\t\t\tfor b in SCHEME_BUILDINGS:
\t\t\t\tif sqrt((cx - b.x) ** 2 + (cz - b.z) ** 2) < max(b.w, b.d) / 2 + 4:
\t\t\t\t\ttoo_close = true
\t\t\t\t\tbreak
\t\t\tif too_close:
\t\t\t\tcontinue
\t\t\t
\t\t\tvar dist_id = get_district_at(cx, cz)
\t\t\tif dist_id == "water" or dist_id == "rural":
\t\t\t\tcontinue  # no filler buildings in water/rural
\t\t\t
\t\t\t# Hash-based random for deterministic placement
\t\t\tvar seed_val = abs((gx * 73856093) ^ (gz * 19349663)) % 99991
\t\t\tvar rng = func(salt): return float((seed_val * (salt + 1) * 9301 + 49297) % 233280) / 233280
\t\t\t
\t\t\t# Gap chance — REDUCED for higher density
\t\t\tvar gap = 0.10
\t\t\tmatch dist_id:
\t\t\t\t"downtown": gap = 0.05  # very dense (was 0.10)
\t\t\t\t"harbor": gap = 0.25    # (was 0.40)
\t\t\t\t"slums": gap = 0.10     # (was 0.20)
\t\t\t\t"industrial": gap = 0.20  # (was 0.30)
\t\t\t\t"suburbs": gap = 0.35   # (was 0.50)
\t\t\tif rng.call(99) < gap:
\t\t\t\tcontinue
\t\t\t
\t\t\t# Building dimensions per district — BIGGER for better fill
\t\t\tvar w: float
\t\t\tvar d: float
\t\t\tvar h: float
\t\t\tvar dist = DISTRICTS[dist_id]
\t\t\tif dist_id == "downtown":
\t\t\t\tw = 10 + rng.call(1) * 4  # 10-14m (was 12-20)
\t\t\t\td = 9 + rng.call(2) * 4
\t\t\t\th = dist.height_min + rng.call(3) * (dist.height_max - dist.height_min)
\t\t\telif dist_id == "industrial":
\t\t\t\tw = 11 + rng.call(1) * 4
\t\t\t\td = 10 + rng.call(2) * 4
\t\t\t\th = dist.height_min + rng.call(3) * (dist.height_max - dist.height_min)
\t\t\telif dist_id == "harbor":
\t\t\t\tw = 12 + rng.call(1) * 4
\t\t\t\td = 11 + rng.call(2) * 4
\t\t\t\th = dist.height_min + rng.call(3) * (dist.height_max - dist.height_min)
\t\t\telif dist_id == "slums":
\t\t\t\tw = 7 + rng.call(1) * 4
\t\t\t\td = 6 + rng.call(2) * 4
\t\t\t\th = dist.height_min + rng.call(3) * (dist.height_max - dist.height_min)
\t\t\telse:  # suburbs
\t\t\t\tw = 7 + rng.call(1) * 3
\t\t\t\td = 6 + rng.call(2) * 3
\t\t\t\th = dist.height_min + rng.call(3) * (dist.height_max - dist.height_min)
\t\t\t
\t\t\t# Offset within grid cell (small, to fill the cell tightly)
\t\t\tvar margin = 1.0
\t\t\tvar max_off = max(0, (grid - w - margin * 2) / 2)
\t\t\tvar ox = (rng.call(4) - 0.5) * max_off
\t\t\tvar oz = (rng.call(5) - 0.5) * max_off
\t\t\tvar fx = cx + ox
\t\t\tvar fz = cz + oz
\t\t\t
\t\t\t# Skip if corners overlap road
\t\t\tif _is_on_road(fx - w / 2, fz - d / 2) or _is_on_road(fx + w / 2, fz + d / 2):
\t\t\t\tcontinue
\t\t\tif _is_on_road(fx - w / 2, fz + d / 2) or _is_on_road(fx + w / 2, fz - d / 2):
\t\t\t\tcontinue
\t\t\t
\t\t\t# Build it
\t\t\tvar mesh = MeshInstance3D.new()
\t\t\tvar f_mesh = BoxMesh.new()
\t\t\tf_mesh.size = Vector3(w, h, d)
\t\t\tmesh.mesh = f_mesh
\t\t\tmesh.position = Vector3(fx, h / 2, fz)
\t\t\tvar mat = StandardMaterial3D.new()
\t\t\t# Color palette per district
\t\t\tvar palette: Array
\t\t\tmatch dist_id:
\t\t\t\t"downtown":
\t\t\t\t\tpalette = ["#475569", "#334155", "#1e293b", "#64748b", "#3f3f46"]
\t\t\t\t"harbor":
\t\t\t\t\tpalette = ["#1c1917", "#292524", "#44403c", "#1f2937"]
\t\t\t\t"slums":
\t\t\t\t\tpalette = ["#7c2d12", "#9a3412", "#451a03", "#1c1917", "#57534e"]
\t\t\t\t"industrial":
\t\t\t\t\tpalette = ["#3f3f46", "#525252", "#27272a", "#404040"]
\t\t\t\t_:
\t\t\t\t\tpalette = ["#525252", "#737373", "#404040", "#a3a3a3"]
\t\t\tmat.albedo_color = Color.from_string(palette[int(rng.call(6) * palette.size()) % palette.size()], Color.GRAY)
\t\t\tmat.roughness = 0.85
\t\t\tmesh.material_override = mat
\t\t\tparent.add_child(mesh)
\t\t\t
\t\t\t# Collision
\t\t\tvar body = StaticBody3D.new()
\t\t\tbody.position = Vector3(fx, h / 2, fz)
\t\t\tvar col = CollisionShape3D.new()
\t\t\tvar shape = BoxShape3D.new()
\t\t\tshape.size = Vector3(w, h, d)
\t\t\tcol.shape = shape
\t\t\tbody.add_child(col)
\t\t\tparent.add_child(body)'''

new3 = '''static func _build_filler_buildings(parent: Node3D) -> void:
\t# BLOCK-BASED placement: city is divided into 200x200m blocks by the
\t# main avenues (at -200, 0, +200). Each block gets 2-4 buildings placed
\t# at clear positions within the block, NOT random grid.
\t# This gives a clean city look with clear separation streets/buildings.
\t
\tvar block_size = 200.0  # distance between avenues
\tvar road_buffer = ROAD_HALF_MAIN + SIDEWALK  # space to leave near roads
\tvar block_padding = road_buffer + 4.0  # extra margin from road
\t
\t# Iterate over all 200x200m blocks in the city area
\tvar block_coords = [-300, -100, 100]  # block centers (between avenues)
\tfor bx in block_coords:
\t\tfor bz in block_coords:
\t\t\t# Block corners
\t\t\tvar bx_min = bx - block_size / 2 + block_padding
\t\t\tvar bx_max = bx + block_size / 2 - block_padding
\t\t\tvar bz_min = bz - block_size / 2 + block_padding
\t\t\tvar bz_max = bz + block_size / 2 - block_padding
\t\t\t
\t\t\tvar block_w = bx_max - bx_min
\t\t\tvar block_d = bz_max - bz_min
\t\t\tif block_w < 10 or block_d < 10:
\t\t\t\tcontinue  # block too small
\t\t\t
\t\t\t# District at block center
\t\t\tvar dist_id = get_district_at(bx, bz)
\t\t\tif dist_id == "water" or dist_id == "rural":
\t\t\t\tcontinue  # no filler buildings in water/rural
\t\t\t
\t\t\t# Place 2x2 = 4 buildings per block, with clear spacing
\t\t\tvar buildings_per_side = 2
\t\t\tvar cell_w = block_w / buildings_per_side
\t\t\tvar cell_d = block_d / buildings_per_side
\t\t\t
\t\t\tfor ix in range(buildings_per_side):
\t\t\t\tfor iz in range(buildings_per_side):
\t\t\t\t\t# Cell center within block
\t\t\t\t\tvar cx = bx_min + cell_w * (ix + 0.5)
\t\t\t\t\tvar cz = bz_min + cell_d * (iz + 0.5)
\t\t\t\t\t
\t\t\t\t\t# Skip if too close to scheme building
\t\t\t\t\tvar too_close = false
\t\t\t\t\tfor b in SCHEME_BUILDINGS:
\t\t\t\t\t\tif sqrt((cx - b.x) ** 2 + (cz - b.z) ** 2) < max(b.w, b.d) / 2 + 6:
\t\t\t\t\t\t\ttoo_close = true
\t\t\t\t\t\t\tbreak
\t\t\t\t\tif too_close:
\t\t\t\t\t\tcontinue
\t\t\t\t\t
\t\t\t\t\t# Hash-based random for deterministic variation
\t\t\t\t\tvar seed_val = abs((int(cx) * 73856093) ^ (int(cz) * 19349663)) % 99991
\t\t\t\t\tvar rng = func(salt): return float((seed_val * (salt + 1) * 9301 + 49297) % 233280) / 233280
\t\t\t\t\t
\t\t\t\t\t# Skip some cells based on district (for variety, not too dense)
\t\t\t\t\tvar skip_chance = 0.0
\t\t\t\t\tmatch dist_id:
\t\t\t\t\t\t"downtown": skip_chance = 0.10
\t\t\t\t\t\t"harbor": skip_chance = 0.30
\t\t\t\t\t\t"slums": skip_chance = 0.15
\t\t\t\t\t\t"industrial": skip_chance = 0.25
\t\t\t\t\t\t"suburbs": skip_chance = 0.40
\t\t\t\t\tif rng.call(99) < skip_chance:
\t\t\t\t\t\tcontinue
\t\t\t\t\t
\t\t\t\t\t# Building dimensions — fit within cell with margin
\t\t\t\t\tvar margin = 2.0
\t\t\t\t\tvar max_w = cell_w - margin * 2
\t\t\t\t\tvar max_d = cell_d - margin * 2
\t\t\t\t\tvar dist = DISTRICTS[dist_id]
\t\t\t\t\tvar w: float
\t\t\t\t\tvar d: float
\t\t\t\t\tvar h: float
\t\t\t\t\tmatch dist_id:
\t\t\t\t\t\t"downtown":
\t\t\t\t\t\t\tw = min(max_w, 14 + rng.call(1) * 6)
\t\t\t\t\t\t\td = min(max_d, 12 + rng.call(2) * 6)
\t\t\t\t\t\t\th = dist.height_min + rng.call(3) * (dist.height_max - dist.height_min)
\t\t\t\t\t\t"industrial":
\t\t\t\t\t\t\tw = min(max_w, 16 + rng.call(1) * 8)
\t\t\t\t\t\t\td = min(max_d, 14 + rng.call(2) * 8)
\t\t\t\t\t\t\th = dist.height_min + rng.call(3) * (dist.height_max - dist.height_min)
\t\t\t\t\t\t"harbor":
\t\t\t\t\t\t\tw = min(max_w, 18 + rng.call(1) * 6)
\t\t\t\t\t\t\td = min(max_d, 16 + rng.call(2) * 6)
\t\t\t\t\t\t\th = dist.height_min + rng.call(3) * (dist.height_max - dist.height_min)
\t\t\t\t\t\t"slums":
\t\t\t\t\t\t\tw = min(max_w, 8 + rng.call(1) * 4)
\t\t\t\t\t\t\td = min(max_d, 7 + rng.call(2) * 4)
\t\t\t\t\t\t\th = dist.height_min + rng.call(3) * (dist.height_max - dist.height_min)
\t\t\t\t\t\t_:
\t\t\t\t\t\t\tw = min(max_w, 8 + rng.call(1) * 3)
\t\t\t\t\t\t\td = min(max_d, 7 + rng.call(2) * 3)
\t\t\t\t\t\t\th = dist.height_min + rng.call(3) * (dist.height_max - dist.height_min)
\t\t\t\t\t
\t\t\t\t\t# District-specific building style
\t\t\t\t\t_make_district_building(parent, cx, cz, w, d, h, dist_id, rng)'''

assert old3 in c, "old3 (filler_buildings) not found"
c = c.replace(old3, new3)

# ============================================================
# 4. Add _make_district_building helper function (different styles per district)
# ============================================================
# Insert before _is_on_road
old4 = '''static func _is_on_road(x: float, z: float) -> bool:'''

new4 = '''# ============================================================
# District-specific building styles
# ============================================================

static func _make_district_building(parent: Node3D, x: float, z: float,
\t\tw: float, d: float, h: float, dist_id: String, rng: Callable) -> void:
\tvar mesh = MeshInstance3D.new()
\tvar body = StaticBody3D.new()
\tbody.position = Vector3(x, h / 2, z)
\t
\tmatch dist_id:
\t\t"downtown":
\t\t\t# Tall glass skyscraper — emissive blue/cyan windows
\t\t\tvar b_mesh = BoxMesh.new()
\t\t\tb_mesh.size = Vector3(w, h, d)
\t\t\tmesh.mesh = b_mesh
\t\t\tmesh.position = Vector3(x, h / 2, z)
\t\t\tvar mat = StandardMaterial3D.new()
\t\t\tvar colors = ["#1e293b", "#0f172a", "#1e3a5f", "#1e293b"]
\t\t\tmat.albedo_color = Color.from_string(colors[int(rng.call(1) * 4) % 4], Color.DIM_GRAY)
\t\t\tmat.metalness = 0.6
\t\t\tmat.roughness = 0.25
\t\t\tmat.emission_enabled = true
\t\t\tmat.emission = Color(0.3, 0.5, 0.7)
\t\t\tmat.emission_energy_multiplier = 0.2
\t\t\tmesh.material_override = mat
\t\t"harbor":
\t\t\t# Low warehouse — flat dark box with roof detail
\t\t\tvar b_mesh = BoxMesh.new()
\t\t\tb_mesh.size = Vector3(w, h, d)
\t\t\tmesh.mesh = b_mesh
\t\t\tmesh.position = Vector3(x, h / 2, z)
\t\t\tvar mat = StandardMaterial3D.new()
\t\t\tvar colors = ["#1c1917", "#292524", "#44403c", "#1f2937"]
\t\t\tmat.albedo_color = Color.from_string(colors[int(rng.call(1) * 4) % 4], Color.DIM_GRAY)
\t\t\tmat.roughness = 0.95
\t\t\tmesh.material_override = mat
\t\t"slums":
\t\t\t# Small rundown house — brown/red brick, smaller scale
\t\t\tvar b_mesh = BoxMesh.new()
\t\t\tb_mesh.size = Vector3(w, h, d)
\t\t\tmesh.mesh = b_mesh
\t\t\tmesh.position = Vector3(x, h / 2, z)
\t\t\tvar mat = StandardMaterial3D.new()
\t\t\tvar colors = ["#7c2d12", "#9a3412", "#451a03", "#57534e", "#78350f"]
\t\t\tmat.albedo_color = Color.from_string(colors[int(rng.call(1) * 5) % 5], Color.DIM_GRAY)
\t\t\tmat.roughness = 1.0
\t\t\tmesh.material_override = mat
\t\t"industrial":
\t\t\t# Factory — wide gray box with metallic look
\t\t\tvar b_mesh = BoxMesh.new()
\t\t\tb_mesh.size = Vector3(w, h, d)
\t\t\tmesh.mesh = b_mesh
\t\t\tmesh.position = Vector3(x, h / 2, z)
\t\t\tvar mat = StandardMaterial3D.new()
\t\t\tvar colors = ["#3f3f46", "#525252", "#27272a", "#404040"]
\t\t\tmat.albedo_color = Color.from_string(colors[int(rng.call(1) * 4) % 4], Color.DIM_GRAY)
\t\t\tmat.metalness = 0.3
\t\t\tmat.roughness = 0.7
\t\t\tmesh.material_override = mat
\t\t_:
\t\t\t# Suburbs — small house with garden, lighter colors
\t\t\tvar b_mesh = BoxMesh.new()
\t\t\tb_mesh.size = Vector3(w, h, d)
\t\t\tmesh.mesh = b_mesh
\t\t\tmesh.position = Vector3(x, h / 2, z)
\t\t\tvar mat = StandardMaterial3D.new()
\t\t\tvar colors = ["#a3a3a3", "#d4d4d4", "#f5f5f5", "#e5e5e5", "#bfbfbf"]
\t\t\tmat.albedo_color = Color.from_string(colors[int(rng.call(1) * 5) % 5], Color.DIM_GRAY)
\t\t\tmat.roughness = 0.9
\t\t\tmesh.material_override = mat
\t
\tparent.add_child(mesh)
\t# Collision
\tvar col = CollisionShape3D.new()
\tvar shape = BoxShape3D.new()
\tshape.size = Vector3(w, h, d)
\tcol.shape = shape
\tbody.add_child(col)
\tparent.add_child(body)

static func _is_on_road(x: float, z: float) -> bool:'''

assert old4 in c, "old4 (insertion point) not found"
c = c.replace(old4, new4)

with open(PATH, 'w') as f:
    f.write(c)
print("OK - roads simplified, block-based buildings, district styles added")
