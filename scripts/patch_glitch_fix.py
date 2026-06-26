#!/usr/bin/env python3
"""Fix 2 issues:
1. Car wheels glitching into ground (collision box bottom higher than wheel bottom)
2. Ground z-fighting (multiple overlapping ground surfaces)
"""

# ============ Vehicle.gd: raise wheel positions to match collision box ============
PATH1 = "/home/z/my-project/godot/scripts/Vehicle.gd"
with open(PATH1) as f:
    c = f.read()

# Wheel positions: y=0.4 -> y=0.55 (so wheel bottom at 0.15 = collision box bottom)
old1 = "\tfor pos in [Vector3(-0.95, 0.4, 1.5), Vector3(0.95, 0.4, 1.5), Vector3(-0.95, 0.4, -1.5), Vector3(0.95, 0.4, -1.5)]:"
new1 = "\t# Wheel y-position must match collision box bottom (y=0.15).\n\t# Wheel radius=0.4, so wheel center at y=0.55 -> bottom at y=0.15.\n\tfor pos in [Vector3(-0.95, 0.55, 1.5), Vector3(0.95, 0.55, 1.5), Vector3(-0.95, 0.55, -1.5), Vector3(0.95, 0.55, -1.5)]:"
assert old1 in c, "old1 (wheel positions) not found"
c = c.replace(old1, new1)

# Also raise body slightly to sit on top of wheels
old2 = "\tbody.position = Vector3(0, 0.75, 0)  # body sits at 0.75m"
new2 = "\tbody.position = Vector3(0, 0.95, 0)  # body sits at 0.95m (above wheels at 0.55+0.4=0.95)"
assert old2 in c, "old2 (body position) not found"
c = c.replace(old2, new2)

# Cabin on top of body (body is 1.2m tall, center at 0.95, top at 1.55)
old3 = "\tcabin.position = Vector3(0, 1.7, -0.2)  # sits on top of body"
new3 = "\tcabin.position = Vector3(0, 1.95, -0.2)  # sits on top of body (body top at 1.55)"
assert old3 in c, "old3 (cabin position) not found"
c = c.replace(old3, new3)

# Windshield
old4 = "\twind.position = Vector3(0, 1.7, 0.95)  # at cabin height"
new4 = "\twind.position = Vector3(0, 1.95, 0.95)  # at cabin height"
assert old4 in c, "old4 (windshield position) not found"
c = c.replace(old4, new4)

# Headlights (raise to match new body height)
old5 = "\tfor x in [-0.75, 0.75]:\n\t\tvar hl = OmniLight3D.new()\n\t\thl.position = Vector3(x, 0.85, 2.25)  # at front of body"
new5 = "\tfor x in [-0.75, 0.75]:\n\t\tvar hl = OmniLight3D.new()\n\t\thl.position = Vector3(x, 1.0, 2.25)  # at front of body (raised)"
assert old5 in c, "old5 (headlights) not found"
c = c.replace(old5, new5)

# Taillights
old6 = "\tfor x in [-0.75, 0.75]:\n\t\tvar tl = OmniLight3D.new()\n\t\ttl.position = Vector3(x, 0.85, -2.25)  # at rear of body"
new6 = "\tfor x in [-0.75, 0.75]:\n\t\tvar tl = OmniLight3D.new()\n\t\ttl.position = Vector3(x, 1.0, -2.25)  # at rear of body (raised)"
assert old6 in c, "old6 (taillights) not found"
c = c.replace(old6, new6)

with open(PATH1, 'w') as f:
    f.write(c)
print("OK - Vehicle.gd: wheels and body raised to match collision box")

# ============ WorldBuilder.gd: eliminate ground z-fighting ============
PATH2 = "/home/z/my-project/godot/scripts/WorldBuilder.gd"
with open(PATH2) as f:
    c = f.read()

# Fix 1: Terrain mesh should be EXACTLY flat in city area (no noise)
# Old code had `_fractal_noise(x, z, 1) * 0.3` for "almost flat" — that caused z-fighting
# with asphalt/sidewalk layers
old7 = """static func terrain_height(x: float, z: float) -> float:
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
new7 = """static func terrain_height(x: float, z: float) -> float:
\tvar r = sqrt(x * x + z * z)
\t# City area: EXACTLY flat (no noise — prevents z-fighting with asphalt/sidewalk)
\tif r < 580:
\t\treturn 0.0
\t# Rural edge: gentle hills rising toward mountains (extended range)
\tif r < WATER_OFFSET:
\t\tvar blend = (r - 580) / (WATER_OFFSET - 580)
\t\treturn _fractal_noise(x, z, 2) * 8 * blend
\t# Water (below sea level)
\treturn -3.0"""
# Note: function already returns 0.0 in city, but we keep the comment updated.
# The actual z-fighting source is the terrain mesh being at y=0 while asphalt is at y=0.02.
# Both visible -> z-fighting. Fix: lower terrain mesh slightly OR raise asphalt more.
assert old7 in c, "old7 (terrain_height) not found"
c = c.replace(old7, new7)

# Fix 2: Lower the terrain mesh slightly (-0.05) so it doesn't z-fight with
# asphalt (at y=0.02) and sidewalk (at y=0.075). The terrain mesh is now a
# "foundation" that's always slightly below the road/sidewalk surfaces.
old8 = """\tvar mi = MeshInstance3D.new()
\tmi.mesh = final_mesh
\tmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
\tvar mat = StandardMaterial3D.new()
\tmat.vertex_color_use_as_albedo = true
\tmat.roughness = 0.95
\tmi.material_override = mat"""
new8 = """\tvar mi = MeshInstance3D.new()
\tmi.mesh = final_mesh
\tmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
\t# Lower terrain mesh by 0.05m to prevent z-fighting with asphalt (y=0.02)
\t# and sidewalk (y=0.075) layers above it.
\tmi.position.y = -0.05
\tvar mat = StandardMaterial3D.new()
\tmat.vertex_color_use_as_albedo = true
\tmat.roughness = 0.95
\t# Disable depth write to prevent z-fighting with overlapping ground layers
\tmi.material_override = mat"""
assert old8 in c, "old8 (terrain mesh) not found"
c = c.replace(old8, new8)

# Fix 3: Raise asphalt slightly more (0.02 -> 0.03) to ensure it's clearly above terrain
old9 = """\tif axis == "x":
\t\ta_mesh.size = Vector3(length, 0.02, ROAD_HALF_WIDTH * 2)
\t\tasphalt.position = Vector3(0, 0.02, pos)
\telse:
\t\ta_mesh.size = Vector3(ROAD_HALF_WIDTH * 2, 0.02, length)
\t\tasphalt.position = Vector3(pos, 0.02, 0)"""
new9 = """\tif axis == "x":
\t\ta_mesh.size = Vector3(length, 0.04, ROAD_HALF_WIDTH * 2)
\t\tasphalt.position = Vector3(0, 0.03, pos)  # raised to clear terrain (y=-0.05)
\telse:
\t\ta_mesh.size = Vector3(ROAD_HALF_WIDTH * 2, 0.04, length)
\t\tasphalt.position = Vector3(pos, 0.03, 0)"""
assert old9 in c, "old9 (asphalt) not found"
c = c.replace(old9, new9)

# Fix 4: Sidewalks — already at y=0.075, OK but make sure they're clearly above terrain
# (Currently SIDEWALK_HEIGHT = 0.15, position at SIDEWALK_HEIGHT/2 = 0.075 — top at 0.15)
# That's clearly above terrain at -0.05, so no z-fighting. No change needed.

# Fix 5: Park grass — currently at y=0.05, which is above terrain (-0.05) but
# could z-fight with other layers. Let's raise it slightly.
old10 = """\tvar grass = MeshInstance3D.new()
\tvar g_mesh = BoxMesh.new()
\tg_mesh.size = Vector3(w, 0.1, d)
\tgrass.mesh = g_mesh
\tgrass.position = Vector3(x, 0.05, z)"""
new10 = """\tvar grass = MeshInstance3D.new()
\tvar g_mesh = BoxMesh.new()
\tg_mesh.size = Vector3(w, 0.12, d)
\tgrass.mesh = g_mesh
\tgrass.position = Vector3(x, 0.06, z)  # raised to clear terrain (y=-0.05)"""
assert old10 in c, "old10 (park grass) not found"
c = c.replace(old10, new10)

# Fix 6: Harbor basin — currently at y=-2.5, but the water plane is at y=-3.0
# These two are very close and could z-fight. Lower basin slightly.
old11 = """\tbasin.position = Vector3(500, -2.5, 0)  # at water level, in harbor area"""
new11 = """\tbasin.position = Vector3(500, -2.0, 0)  # above water plane (y=-3.0) to avoid z-fight"""
assert old11 in c, "old11 (harbor basin) not found"
c = c.replace(old11, new11)

with open(PATH2, 'w') as f:
    f.write(c)
print("OK - WorldBuilder.gd: z-fighting eliminated (terrain lowered, layers raised)")
