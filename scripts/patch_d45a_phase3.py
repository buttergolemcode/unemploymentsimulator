#!/usr/bin/env python3
"""D.4.5a Phase 3: Real terrain heights (Portofino-inspired) + terrain-following collision.

Land falls from West (high: Canyon 100m) to East (low: Harbor 0m, Sea -3m).
Each district on a different elevation step.
"""

PATH = "/home/z/my-project/godot/scripts/WorldBuilder.gd"
with open(PATH) as f:
    c = f.read()

# ============================================================
# 1. Replace terrain_height() with Portofino-inspired stepped terrain
# ============================================================
old_terrain = """static func terrain_height(x: float, z: float) -> float:
\t# City area (Downtown to Harbor): completely flat
\tif x > -800 and x < 1500 and z > -600 and z < 600:
\t\treturn 0.0
\t# Rural zone: hills rising toward canyon walls
\tif x > -1200 and x < -800:
\t\tvar blend = clamp((-800 - x) / 400.0, 0, 1)
\t\treturn _fractal_noise(x, z, 2) * 10 * blend
\t# Beyond canyon edges: mountain height
\tif x < CANYON_EDGE_WEST or z < CANYON_EDGE_NORTH or z > CANYON_EDGE_SOUTH:
\t\tvar dist = 0.0
\t\tif x < CANYON_EDGE_WEST:
\t\t\tdist = max(dist, CANYON_EDGE_WEST - x)
\t\tif z < CANYON_EDGE_NORTH:
\t\t\tdist = max(dist, CANYON_EDGE_NORTH - z)
\t\tif z > CANYON_EDGE_SOUTH:
\t\t\tdist = max(dist, z - CANYON_EDGE_SOUTH)
\t\treturn CANYON_HEIGHT * clamp(dist / 300.0, 0, 1) + _fractal_noise(x, z, 3) * 20
\t# Water (east of harbor)
\tif x > WATER_OFFSET:
\t\treturn -3.0 - clamp((x - WATER_OFFSET) / 200.0, 0, 1) * 15
\treturn 0.0"""

new_terrain = """static func terrain_height(x: float, z: float) -> float:
\t# Portofino-inspired: land falls from West (high) to East (sea, low)
\t# Each district on a different elevation step with fractal noise for natural variation
\tvar noise = _fractal_noise(x, z, 2)
\t
\t# Canyon walls (West/North/South edges) — steep rise to 100m+
\tif x < CANYON_EDGE_WEST or z < CANYON_EDGE_NORTH or z > CANYON_EDGE_SOUTH:
\t\tvar dist = 0.0
\t\tif x < CANYON_EDGE_WEST:
\t\t\tdist = max(dist, CANYON_EDGE_WEST - x)
\t\tif z < CANYON_EDGE_NORTH:
\t\t\tdist = max(dist, CANYON_EDGE_NORTH - z)
\t\tif z > CANYON_EDGE_SOUTH:
\t\t\tdist = max(dist, z - CANYON_EDGE_SOUTH)
\t\treturn CANYON_HEIGHT * clamp(dist / 300.0, 0, 1) + noise * 20
\t
\t# Water (east of coast) — below sea level
\tif x > WATER_OFFSET:
\t\treturn -3.0 - clamp((x - WATER_OFFSET) / 200.0, 0, 1) * 15
\t
\t# Harbor (x: +600 to +1500) — sea level (0m)
\tif x > 600:
\t\treturn 0.0 + noise * 0.5  # almost flat, tiny variation
\t
\t# Downtown (x: +100 to +800) — gentle hill 5-15m, sloping down to harbor
\tif x > 100:
\t\tvar dt_blend = (800 - x) / 700.0  # 0 at harbor edge, 1 at inland
\t\treturn dt_blend * 15.0 + noise * 2.0  # 0-15m with noise
\t
\t# Industrial (x: -600 to +200) — plateau at 25m
\tif x > -600:
\t\treturn 25.0 + noise * 3.0  # 22-28m plateau
\t
\t# Suburbs (x: -1000 to -400) — rolling hills 40-50m
\tif x > -1000:
\t\treturn 45.0 + noise * 8.0  # 37-53m rolling hills
\t
\t# Rural (x: -1200 to -800) — higher hills 60-80m, rising toward canyon
\tif x > -1200:
\t\tvar r_blend = (-800 - x) / 400.0  # 0 at suburbs edge, 1 at canyon edge
\t\treturn 60.0 + r_blend * 20.0 + noise * 10.0  # 60-80m
\t
\treturn 0.0"""

assert old_terrain in c, "old_terrain not found"
c = c.replace(old_terrain, new_terrain)

# ============================================================
# 2. Replace flat city collision with terrain-following grid collision
# ============================================================
old_collision = """\t# === COLLISION SYSTEM (proper — covers all terrain) ===
\t# 1) City ground (flat, covers entire city + rural area at y=0)
\tvar city_body = StaticBody3D.new()
\tcity_body.name = "CityGround"
\tvar city_col = CollisionShape3D.new()
\tvar city_shape = BoxShape3D.new()
\tcity_shape.size = Vector3(3000, 1.0, 3000)  # 3000x3000 flat ground (covers city + inner rural)
\tcity_col.shape = city_shape
\tcity_col.position = Vector3(0, -0.5, 0)
\tcity_body.add_child(city_col)
\tparent.add_child(city_body)
\t
\t# 2) Rural raised collision (DENSE GRID covering entire rural area)
\t# Old approach (12 boxes around perimeter) left gaps where cars fell through.
\t# New approach: grid of 50x50m boxes covering the full rural ring (380-580m radius)
\tvar rural_body = StaticBody3D.new()
\trural_body.name = "RuralGround"
\tvar rural_grid = 80  # 80m spacing
\tfor gx in range(-1200, 1201, rural_grid):
\t\tfor gz in range(-1200, 1201, rural_grid):
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

new_collision = """\t# === COLLISION SYSTEM: terrain-following grid ===
\t# Every 60m cell gets a BoxShape3D positioned at terrain_height().
\t# This covers the ENTIRE playable area with proper elevation — cars
\t# can drive uphill/downhill, follow the Portofino-style slope.
\tvar terrain_body = StaticBody3D.new()
\tterrain_body.name = "TerrainGround"
\tvar terrain_grid = 60  # 60m cells — balance of precision vs performance
\tfor gx in range(-1400, 1501, terrain_grid):
\t\tfor gz in range(-1400, 1501, terrain_grid):
\t\t\t# Skip water area (x > 1500) — no ground collision in ocean
\t\t\tif gx > 1500:
\t\t\t\tcontinue
\t\t\t# Skip deep canyon (handled by mountain walls below)
\t\t\tif gx < CANYON_EDGE_WEST - 100 or gz < CANYON_EDGE_NORTH - 100 or gz > CANYON_EDGE_SOUTH + 100:
\t\t\t\tcontinue
\t\t\tvar h_at = terrain_height(gx, gz)
\t\t\t# Skip underwater cells (no collision needed below sea level)
\t\t\tif h_at < -1:
\t\t\t\tcontinue
\t\t\tvar rcol = CollisionShape3D.new()
\t\t\tvar rshape = BoxShape3D.new()
\t\t\trshape.size = Vector3(terrain_grid, 1.0, terrain_grid)
\t\t\trcol.shape = rshape
\t\t\trcol.position = Vector3(gx, h_at - 0.5, gz)
\t\t\tterrain_body.add_child(rcol)
\tparent.add_child(terrain_body)"""

assert old_collision in c, "old_collision not found"
c = c.replace(old_collision, new_collision)

# ============================================================
# 3. Update building positions to use terrain_height()
# ============================================================
# Scheme buildings: add terrain_height() to Y position
old_scheme_pos = "\tmesh.position = Vector3(b.x, b.h / 2.0, b.z)"
new_scheme_pos = "\tmesh.position = Vector3(b.x, terrain_height(b.x, b.z) + b.h / 2.0, b.z)"
assert old_scheme_pos in c, "old_scheme_pos not found"
c = c.replace(old_scheme_pos, new_scheme_pos)

# Scheme building collision body
old_scheme_col = "\tbody.position = Vector3(b.x, b.h / 2.0, b.z)"
new_scheme_col = "\tbody.position = Vector3(b.x, terrain_height(b.x, b.z) + b.h / 2.0, b.z)"
assert old_scheme_col in c, "old_scheme_col not found"
c = c.replace(old_scheme_col, new_scheme_col)

# Scheme building label
old_label_pos = "\tlabel.position = Vector3(b.x, b.h + 2, b.z)"
new_label_pos = "\tlabel.position = Vector3(b.x, terrain_height(b.x, b.z) + b.h + 2, b.z)"
assert old_label_pos in c, "old_label_pos not found"
c = c.replace(old_label_pos, new_label_pos)

# ============================================================
# 4. Update filler building Y positions
# ============================================================
old_filler_pos = "\tmesh.position = Vector3(fx, h / 2, fz)"
new_filler_pos = "\tmesh.position = Vector3(fx, terrain_height(fx, fz) + h / 2, fz)"
assert old_filler_pos in c, "old_filler_pos not found"
c = c.replace(old_filler_pos, new_filler_pos)

old_filler_col = "\tbody.position = Vector3(fx, h / 2, fz)"
new_filler_col = "\tbody.position = Vector3(fx, terrain_height(fx, fz) + h / 2, fz)"
assert old_filler_col in c, "old_filler_col not found"
c = c.replace(old_filler_col, new_filler_col)

# ============================================================
# 5. Update _make_tree to use terrain_height (already does, verify)
# ============================================================
# _make_tree already uses: var ground_y = terrain_height(x, z) — OK, no change needed

# ============================================================
# 6. Update street lamps to use terrain_height
# ============================================================
old_lamp = "\tpole.position = pos + Vector3(0, 2, 0)"
new_lamp = "\tpole.position = pos + Vector3(0, terrain_height(pos.x, pos.z) + 2, 0)"
assert old_lamp in c, "old_lamp not found"
c = c.replace(old_lamp, new_lamp)

old_light = "\tlight.position = pos + Vector3(0, 4, 0)"
new_light = "\tlight.position = pos + Vector3(0, terrain_height(pos.x, pos.z) + 4, 0)"
assert old_light in c, "old_light not found"
c = c.replace(old_light, new_light)

# ============================================================
# 7. Update harbor dock props to use terrain_height (harbor = 0m, so minimal change)
# ============================================================
# Harbor is at sea level (0m), so terrain_height returns ~0 there. No change needed.

# ============================================================
# 8. Update landmarks to use terrain_height
# ============================================================
# Park grass
old_park = "\tgrass.position = Vector3(x, 0.06, z)"
new_park = "\tgrass.position = Vector3(x, terrain_height(x, z) + 0.06, z)"
assert old_park in c, "old_park not found"
c = c.replace(old_park, new_park)

# Park grass collision
old_park_col = "\tgrass_body.position = Vector3(x, 0.06, z)"
new_park_col = "\tgrass_body.position = Vector3(x, terrain_height(x, z) + 0.06, z)"
assert old_park_col in c, "old_park_col not found"
c = c.replace(old_park_col, new_park_col)

# ============================================================
# 9. Update roads to use terrain_height (Downtown is on a slope)
# ============================================================
old_asphalt_x = "\tasphalt.position = Vector3(0, 0.03, pos)"
new_asphalt_x = "\tasphalt.position = Vector3(0, terrain_height(0, pos) + 0.03, pos)"
assert old_asphalt_x in c, "old_asphalt_x not found"
c = c.replace(old_asphalt_x, new_asphalt_x)

old_asphalt_z = "\tasphalt.position = Vector3(pos, 0.03, 0)"
new_asphalt_z = "\tasphalt.position = Vector3(pos, terrain_height(pos, 0) + 0.03, 0)"
assert old_asphalt_z in c, "old_asphalt_z not found"
c = c.replace(old_asphalt_z, new_asphalt_z)

# ============================================================
# 10. Update GameScene.tscn player spawn to use terrain height
# ============================================================
# Player spawn is at (400, 0.1, 0) — terrain at (400,0) is ~10m in Downtown
# We need to update this in the .tscn file, but since terrain_height is a
# GDScript function, we'll set the player Y in code instead.
# For now, set it high enough to fall onto terrain.

# ============================================================
# 11. Update NPC spawns and vehicle spawns to use terrain_height
# ============================================================
# These are set in GameScene.gd — need to update there

with open(PATH, 'w') as f:
    f.write(c)
print("OK — terrain_height + collision + building/lamp/road/park positions updated")
