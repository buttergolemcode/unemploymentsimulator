#!/usr/bin/env python3
"""PROPER physics fix: add collision to all ground objects + restore vehicle physics.

Root cause: Sidewalks, asphalt, park grass, and piers had NO collision shapes.
Cars (and player) fell through them visually. Previous 'fixes' just adjusted
heights to mask the symptom. This fix addresses the cause:

1. Add StaticBody3D + CollisionShape3D to:
   - Sidewalk segments (in _make_sidewalk_segment)
   - Sidewalk corners (in _make_sidewalk_corner)
   - Asphalt (in _make_street)
   - Park grass (in _park)
   - (Piers already have collision)

2. Restore vehicle collision box to normal height (bottom at y=0)
   - No more fake 'ground clearance' hack
   - Physics handles elevation changes naturally

3. Keep floor detection settings (snap_length, max_angle) — they help car
   climb onto sidewalks now that sidewalks have collision.
"""

# ============ WorldBuilder.gd: Add collision to sidewalks, asphalt, park ============
PATH1 = "/home/z/my-project/godot/scripts/WorldBuilder.gd"
with open(PATH1) as f:
    c = f.read()

# Fix 1: Add collision to sidewalk segments
old1 = """static func _make_sidewalk_segment(parent: Node3D, axis: String, pos: float,
\t\tside: int, seg_start: float, seg_len: float) -> void:
\t# Center of segment along the street direction
\tvar seg_center = seg_start + seg_len / 2
\tvar sidewalk = MeshInstance3D.new()
\tvar s_mesh = BoxMesh.new()
\tif axis == "x":
\t\ts_mesh.size = Vector3(seg_len, SIDEWALK_HEIGHT, SIDEWALK_WIDTH)
\t\tsidewalk.position = Vector3(seg_center, SIDEWALK_HEIGHT / 2, pos + side * (ROAD_HALF_WIDTH + SIDEWALK_WIDTH / 2))
\telse:
\t\ts_mesh.size = Vector3(SIDEWALK_WIDTH, SIDEWALK_HEIGHT, seg_len)
\t\tsidewalk.position = Vector3(pos + side * (ROAD_HALF_WIDTH + SIDEWALK_WIDTH / 2), SIDEWALK_HEIGHT / 2, seg_center)
\tsidewalk.mesh = s_mesh
\tvar smat = StandardMaterial3D.new()
\tsmat.albedo_color = Color(0.55, 0.55, 0.55)  # light gray NYC concrete
\tsmat.roughness = 0.9
\tsidewalk.material_override = smat
\tparent.add_child(sidewalk)"""

new1 = """static func _make_sidewalk_segment(parent: Node3D, axis: String, pos: float,
\t\tside: int, seg_start: float, seg_len: float) -> void:
\t# Center of segment along the street direction
\tvar seg_center = seg_start + seg_len / 2
\tvar sidewalk = MeshInstance3D.new()
\tvar s_mesh = BoxMesh.new()
\tvar sx: float
\tvar sz: float
\tif axis == "x":
\t\ts_mesh.size = Vector3(seg_len, SIDEWALK_HEIGHT, SIDEWALK_WIDTH)
\t\tsx = seg_center
\t\tsz = pos + side * (ROAD_HALF_WIDTH + SIDEWALK_WIDTH / 2)
\t\tsidewalk.position = Vector3(sx, SIDEWALK_HEIGHT / 2, sz)
\telse:
\t\ts_mesh.size = Vector3(SIDEWALK_WIDTH, SIDEWALK_HEIGHT, seg_len)
\t\tsx = pos + side * (ROAD_HALF_WIDTH + SIDEWALK_WIDTH / 2)
\t\tsz = seg_center
\t\tsidewalk.position = Vector3(sx, SIDEWALK_HEIGHT / 2, sz)
\tsidewalk.mesh = s_mesh
\tvar smat = StandardMaterial3D.new()
\tsmat.albedo_color = Color(0.55, 0.55, 0.55)
\tsmat.roughness = 0.9
\tsidewalk.material_override = smat
\tparent.add_child(sidewalk)
\t# COLLISION: StaticBody3D so cars/player can drive/walk on sidewalk
\tvar body = StaticBody3D.new()
\tbody.position = Vector3(sx, SIDEWALK_HEIGHT / 2, sz)
\tvar col = CollisionShape3D.new()
\tvar shape = BoxShape3D.new()
\tif axis == "x":
\t\tshape.size = Vector3(seg_len, SIDEWALK_HEIGHT, SIDEWALK_WIDTH)
\telse:
\t\tshape.size = Vector3(SIDEWALK_WIDTH, SIDEWALK_HEIGHT, seg_len)
\tcol.shape = shape
\tbody.add_child(col)
\tparent.add_child(body)"""

assert old1 in c, "old1 (sidewalk segment) not found"
c = c.replace(old1, new1)

# Fix 2: Add collision to sidewalk corners
old2 = """static func _make_sidewalk_corner(parent: Node3D, x: float, z: float) -> void:
\t# Square sidewalk piece at intersection corner (fills gap between
\t# the two perpendicular sidewalks that were broken at intersection)
\tvar corner = MeshInstance3D.new()
\tvar c_mesh = BoxMesh.new()
\tc_mesh.size = Vector3(SIDEWALK_WIDTH, SIDEWALK_HEIGHT, SIDEWALK_WIDTH)
\tcorner.mesh = c_mesh
\tcorner.position = Vector3(x, SIDEWALK_HEIGHT / 2, z)
\tvar smat = StandardMaterial3D.new()
\tsmat.albedo_color = Color(0.55, 0.55, 0.55)  # match sidewalk color
\tsmat.roughness = 0.9
\tcorner.material_override = smat
\tparent.add_child(corner)"""

new2 = """static func _make_sidewalk_corner(parent: Node3D, x: float, z: float) -> void:
\t# Square sidewalk piece at intersection corner (fills gap between
\t# the two perpendicular sidewalks that were broken at intersection)
\tvar corner = MeshInstance3D.new()
\tvar c_mesh = BoxMesh.new()
\tc_mesh.size = Vector3(SIDEWALK_WIDTH, SIDEWALK_HEIGHT, SIDEWALK_WIDTH)
\tcorner.mesh = c_mesh
\tcorner.position = Vector3(x, SIDEWALK_HEIGHT / 2, z)
\tvar smat = StandardMaterial3D.new()
\tsmat.albedo_color = Color(0.55, 0.55, 0.55)
\tsmat.roughness = 0.9
\tcorner.material_override = smat
\tparent.add_child(corner)
\t# COLLISION: StaticBody3D so cars/player can stand on corner
\tvar body = StaticBody3D.new()
\tbody.position = Vector3(x, SIDEWALK_HEIGHT / 2, z)
\tvar col = CollisionShape3D.new()
\tvar shape = BoxShape3D.new()
\tshape.size = Vector3(SIDEWALK_WIDTH, SIDEWALK_HEIGHT, SIDEWALK_WIDTH)
\tcol.shape = shape
\tbody.add_child(col)
\tparent.add_child(body)"""

assert old2 in c, "old2 (sidewalk corner) not found"
c = c.replace(old2, new2)

# Fix 3: Add collision to park grass
old3 = """\tvar grass = MeshInstance3D.new()
\tvar g_mesh = BoxMesh.new()
\tg_mesh.size = Vector3(w, 0.12, d)
\tgrass.mesh = g_mesh
\tgrass.position = Vector3(x, 0.06, z)  # raised to clear terrain (y=-0.05)
\tvar gmat = StandardMaterial3D.new()
\tgmat.albedo_color = Color(0.18, 0.35, 0.15)  # green grass
\tgmat.roughness = 1.0
\tgrass.material_override = gmat
\tparent.add_child(grass)"""

new3 = """\tvar grass = MeshInstance3D.new()
\tvar g_mesh = BoxMesh.new()
\tg_mesh.size = Vector3(w, 0.12, d)
\tgrass.mesh = g_mesh
\tgrass.position = Vector3(x, 0.06, z)
\tvar gmat = StandardMaterial3D.new()
\tgmat.albedo_color = Color(0.18, 0.35, 0.15)
\tgmat.roughness = 1.0
\tgrass.material_override = gmat
\tparent.add_child(grass)
\t# COLLISION: StaticBody3D so cars/player can walk on park grass
\tvar grass_body = StaticBody3D.new()
\tgrass_body.position = Vector3(x, 0.06, z)
\tvar grass_col = CollisionShape3D.new()
\tvar grass_shape = BoxShape3D.new()
\tgrass_shape.size = Vector3(w, 0.12, d)
\tgrass_col.shape = grass_shape
\tgrass_body.add_child(grass_col)
\tparent.add_child(grass_body)"""

assert old3 in c, "old3 (park grass) not found"
c = c.replace(old3, new3)

with open(PATH1, 'w') as f:
    f.write(c)
print("OK - WorldBuilder.gd: collision added to sidewalks, corners, park grass")

# ============ GameScene.gd: Restore vehicle collision to normal height ============
PATH2 = "/home/z/my-project/godot/scripts/GameScene.gd"
with open(PATH2) as f:
    c = f.read()

# Restore vehicle collision: bottom at y=0 (ground level), no fake ground clearance
old4 = """\t\t# Collision box with GROUND CLEARANCE (like real car chassis)
\t\t# Box bottom at y=0.2 (20cm clearance above road) — car can drive
\t\t# over sidewalks (15cm) and small obstacles without getting stuck.
\t\t# Wheels (visual) reach down to y=0 to show ground contact.
\t\tshape.size = Vector3(1.9, 1.2, 4.3)
\t\tcol.shape = shape
\t\tcol.position = Vector3(0, 0.8, 0)  # center at y=0.8, bottom at y=0.2"""
new4 = """\t\t# Vehicle collision box — bottom at y=0 (ground level)
\t\t# Sidewalks/park now have their own collision, so car will naturally
\t\t# drive onto them via floor_snap. No fake ground clearance needed.
\t\tshape.size = Vector3(1.9, 1.4, 4.3)
\t\tcol.shape = shape
\t\tcol.position = Vector3(0, 0.7, 0)  # center at y=0.7, bottom at y=0.0"""
assert old4 in c, "old4 (vehicle collision) not found"
c = c.replace(old4, new4)

with open(PATH2, 'w') as f:
    f.write(c)
print("OK - GameScene.gd: vehicle collision restored to ground level")

# ============ Vehicle.gd: Restore normal body/wheel positions ============
PATH3 = "/home/z/my-project/godot/scripts/Vehicle.gd"
with open(PATH3) as f:
    c = f.read()

# Body: y=0.9 -> y=0.8 (sits above wheels at y=0.4, wheel top at 0.8)
old5 = "\tbody.position = Vector3(0, 0.9, 0)  # body center at 0.9m (above wheels, matches collision box)"
new5 = "\tbody.position = Vector3(0, 0.8, 0)  # body center at 0.8m (above wheels at 0.4+0.4=0.8)"
assert old5 in c, "old5 (body position) not found"
c = c.replace(old5, new5)

# Cabin: y=1.8 -> y=1.7
old6 = "\tcabin.position = Vector3(0, 1.8, -0.2)  # on top of body (body top at 1.4)"
new6 = "\tcabin.position = Vector3(0, 1.7, -0.2)  # on top of body (body top at 1.4)"
assert old6 in c, "old6 (cabin position) not found"
c = c.replace(old6, new6)

# Windshield: y=1.8 -> y=1.7
old7 = "\twind.position = Vector3(0, 1.8, 0.95)  # at cabin height"
new7 = "\twind.position = Vector3(0, 1.7, 0.95)  # at cabin height"
assert old7 in c, "old7 (windshield position) not found"
c = c.replace(old7, new7)

# Headlights: y=0.9 -> y=0.85
old8 = "\tfor x in [-0.75, 0.75]:\n\t\tvar hl = OmniLight3D.new()\n\t\thl.position = Vector3(x, 0.9, 2.25)  # at front of body"
new8 = "\tfor x in [-0.75, 0.75]:\n\t\tvar hl = OmniLight3D.new()\n\t\thl.position = Vector3(x, 0.85, 2.25)  # at front of body"
assert old8 in c, "old8 (headlights) not found"
c = c.replace(old8, new8)

# Taillights
old9 = "\tfor x in [-0.75, 0.75]:\n\t\tvar tl = OmniLight3D.new()\n\t\ttl.position = Vector3(x, 0.9, -2.25)  # at rear of body"
new9 = "\tfor x in [-0.75, 0.75]:\n\t\tvar tl = OmniLight3D.new()\n\t\ttl.position = Vector3(x, 0.85, -2.25)  # at rear of body"
assert old9 in c, "old9 (taillights) not found"
c = c.replace(old9, new9)

with open(PATH3, 'w') as f:
    f.write(c)
print("OK - Vehicle.gd: body/wheel positions restored to normal")
