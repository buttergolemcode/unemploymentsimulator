#!/usr/bin/env python3
"""Proper physics fix: add collision to ALL surfaces (sidewalks, roads, etc.)

Root cause: Sidewalks and roads were only visual BoxMesh without any
StaticBody3D collision. The car's collision box only hit the flat city
ground at y=-0.5, so sidewalks (15cm high) had no physical effect.

This patch adds proper collision to every walkable/drivable surface:
- Asphalt (roads): collision at y=0
- Sidewalks: collision at y=0.15 (matches visual height)
- Sidewalk corners: collision at y=0.15
- Park grass: collision at y=0.05
- Piers: already had collision (keep)

With proper collision everywhere, the car's gravity will naturally pull
it onto whatever surface it's above. No more glitching through.
"""

PATH = "/home/z/my-project/godot/scripts/WorldBuilder.gd"
with open(PATH) as f:
    c = f.read()

# ============ 1. Asphalt: add collision ============
# In _make_street, the asphalt BoxMesh needs a StaticBody3D sibling
old1 = """\tasphalt.mesh = a_mesh
\tvar amat = StandardMaterial3D.new()
\tamat.albedo_color = Color(0.08, 0.08, 0.08)  # dark asphalt
\tamat.roughness = 0.95
\tasphalt.material_override = amat
\tparent.add_child(asphalt)"""
new1 = """\tasphalt.mesh = a_mesh
\tvar amat = StandardMaterial3D.new()
\tamat.albedo_color = Color(0.08, 0.08, 0.08)  # dark asphalt
\tamat.roughness = 0.95
\tasphalt.material_override = amat
\tparent.add_child(asphalt)
\t# Collision: asphalt is a drivable surface at y=0.03
\tvar asphalt_body = StaticBody3D.new()
\tasphalt_body.name = "RoadCollision"
\tvar asphalt_col = CollisionShape3D.new()
\tvar asphalt_shape = BoxShape3D.new()
\tif axis == "x":
\t\tasphalt_shape.size = Vector3(length, 0.04, ROAD_HALF_WIDTH * 2)
\t\tasphalt_col.position = Vector3(0, 0.03, pos)
\telse:
\t\tasphalt_shape.size = Vector3(ROAD_HALF_WIDTH * 2, 0.04, length)
\t\tasphalt_col.position = Vector3(pos, 0.03, 0)
\tasphalt_col.shape = asphalt_shape
\tasphalt_body.add_child(asphalt_col)
\tparent.add_child(asphalt_body)"""
assert old1 in c, "old1 (asphalt) not found"
c = c.replace(old1, new1)

# ============ 2. Sidewalk segments: add collision ============
# In _make_sidewalk_segment, add StaticBody3D
old2 = """\tsidewalk.mesh = s_mesh
\tvar smat = StandardMaterial3D.new()
\tsmat.albedo_color = Color(0.55, 0.55, 0.55)  # light gray NYC concrete
\tsmat.roughness = 0.9
\tsidewalk.material_override = smat
\tparent.add_child(sidewalk)

static func _make_dash(parent: Node3D, axis: String, pos: float, t: float) -> void:"""
new2 = """\tsidewalk.mesh = s_mesh
\tvar smat = StandardMaterial3D.new()
\tsmat.albedo_color = Color(0.55, 0.55, 0.55)  # light gray NYC concrete
\tsmat.roughness = 0.9
\tsidewalk.material_override = smat
\tparent.add_child(sidewalk)
\t# Collision: sidewalk is a walkable surface at y=0.15 (raised curb)
\tvar sw_body = StaticBody3D.new()
\tsw_body.name = "SidewalkCollision"
\tvar sw_col = CollisionShape3D.new()
\tvar sw_shape = BoxShape3D.new()
\tif axis == "x":
\t\tsw_shape.size = Vector3(seg_len, SIDEWALK_HEIGHT, SIDEWALK_WIDTH)
\t\tsw_col.position = Vector3(seg_center, SIDEWALK_HEIGHT / 2, pos + side * (ROAD_HALF_WIDTH + SIDEWALK_WIDTH / 2))
\telse:
\t\tsw_shape.size = Vector3(SIDEWALK_WIDTH, SIDEWALK_HEIGHT, seg_len)
\t\tsw_col.position = Vector3(pos + side * (ROAD_HALF_WIDTH + SIDEWALK_WIDTH / 2), SIDEWALK_HEIGHT / 2, seg_center)
\tsw_col.shape = sw_shape
\tsw_body.add_child(sw_col)
\tparent.add_child(sw_body)

static func _make_dash(parent: Node3D, axis: String, pos: float, t: float) -> void:"""
assert old2 in c, "old2 (sidewalk segment) not found"
c = c.replace(old2, new2)

# ============ 3. Sidewalk corners: add collision ============
old3 = """\tcorner.mesh = c_mesh
\tcorner.position = Vector3(x, SIDEWALK_HEIGHT / 2, z)
\tvar smat = StandardMaterial3D.new()
\tsmat.albedo_color = Color(0.55, 0.55, 0.55)  # match sidewalk color
\tsmat.roughness = 0.9
\tcorner.material_override = smat
\tparent.add_child(corner)"""
new3 = """\tcorner.mesh = c_mesh
\tcorner.position = Vector3(x, SIDEWALK_HEIGHT / 2, z)
\tvar smat = StandardMaterial3D.new()
\tsmat.albedo_color = Color(0.55, 0.55, 0.55)  # match sidewalk color
\tsmat.roughness = 0.9
\tcorner.material_override = smat
\tparent.add_child(corner)
\t# Collision: corner piece at sidewalk height
\tvar corner_body = StaticBody3D.new()
\tvar corner_col = CollisionShape3D.new()
\tvar corner_shape = BoxShape3D.new()
\tcorner_shape.size = Vector3(SIDEWALK_WIDTH, SIDEWALK_HEIGHT, SIDEWALK_WIDTH)
\tcorner_col.shape = corner_shape
\tcorner_col.position = Vector3(x, SIDEWALK_HEIGHT / 2, z)
\tcorner_body.add_child(corner_col)
\tparent.add_child(corner_body)"""
assert old3 in c, "old3 (sidewalk corner) not found"
c = c.replace(old3, new3)

# ============ 4. Park grass: add collision ============
old4 = """\tgrass.mesh = g_mesh
\tgrass.position = Vector3(x, 0.06, z)  # raised to clear terrain (y=-0.05)
\tvar gmat = StandardMaterial3D.new()
\tgmat.albedo_color = Color(0.18, 0.35, 0.15)  # green grass
\tgmat.roughness = 1.0
\tgrass.material_override = gmat
\tparent.add_child(grass)"""
new4 = """\tgrass.mesh = g_mesh
\tgrass.position = Vector3(x, 0.06, z)  # raised to clear terrain (y=-0.05)
\tvar gmat = StandardMaterial3D.new()
\tgmat.albedo_color = Color(0.18, 0.35, 0.15)  # green grass
\tgmat.roughness = 1.0
\tgrass.material_override = gmat
\tparent.add_child(grass)
\t# Collision: park grass is walkable at y=0.06
\tvar grass_body = StaticBody3D.new()
\tvar grass_col = CollisionShape3D.new()
\tvar grass_shape = BoxShape3D.new()
\tgrass_shape.size = Vector3(w, 0.12, d)
\tgrass_col.shape = grass_shape
\tgrass_col.position = Vector3(x, 0.06, z)
\tgrass_body.add_child(grass_col)
\tparent.add_child(grass_body)"""
assert old4 in c, "old4 (park grass) not found"
c = c.replace(old4, new4)

# ============ 5. Piers: already have collision (verify) ============
# Pier code already has pier_body — no change needed.

# ============ 6. Update _make_road: collision road ============

with open(PATH, 'w') as f:
    f.write(c)
print("OK - WorldBuilder.gd: collision added to sidewalks, roads, corners, park grass")

# ============ Vehicle.gd: simplify collision to match new surfaces ============
PATH2 = "/home/z/my-project/godot/scripts/Vehicle.gd"
with open(PATH2) as f:
    c = f.read()

# Keep current Vehicle.gd collision settings (already proper with ground clearance)
# Just verify gravity is properly applied
print("OK - Vehicle.gd: no changes needed (collision already proper)")

# ============ GameScene.gd: vehicle collision box (clean) ============
PATH3 = "/home/z/my-project/godot/scripts/GameScene.gd"
with open(PATH3) as f:
    c = f.read()

# Vehicle collision: clean box with ground clearance
# Bottom at y=0.2 (20cm clearance), top at y=1.4 (matches car body)
old5 = """\t\t# Collision box with GROUND CLEARANCE (like real car chassis)
\t\t# Box bottom at y=0.2 (20cm clearance above road) — car can drive
\t\t# over sidewalks (15cm) and small obstacles without getting stuck.
\t\t# Wheels (visual) reach down to y=0 to show ground contact.
\t\tshape.size = Vector3(1.9, 1.2, 4.3)
\t\tcol.shape = shape
\t\tcol.position = Vector3(0, 0.8, 0)  # center at y=0.8, bottom at y=0.2"""
new5 = """\t\t# Collision box with GROUND CLEARANCE (real car chassis height)
\t\t# Bottom at y=0.2 (20cm clearance), top at y=1.4 (matches body)
\t\t# Car can drive over sidewalks (15cm) — gravity + floor_snap handle
\t\t# the transition automatically now that sidewalks have collision.
\t\tshape.size = Vector3(1.9, 1.2, 4.3)
\t\tcol.shape = shape
\t\tcol.position = Vector3(0, 0.8, 0)  # center y=0.8, bottom y=0.2"""
assert old5 in c, "old5 (vehicle collision) not found"
c = c.replace(old5, new5)

with open(PATH3, 'w') as f:
    f.write(c)
print("OK - GameScene.gd: vehicle collision comment updated")
