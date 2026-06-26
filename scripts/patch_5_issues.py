#!/usr/bin/env python3
"""Fix 5 issues:
1. Smooth sidewalk corners at intersections
2. Visible crosswalks (were too small)
3. NPCs still on streets (better avoidance)
4. More NPCs (3x current count)
5. Car wheels still glitching (lower collision box)
"""

# ============ WorldBuilder.gd: Fix 1 (corners) + Fix 2 (crosswalks) ============
PATH1 = "/home/z/my-project/godot/scripts/WorldBuilder.gd"
with open(PATH1) as f:
    c = f.read()

# Fix 1: Add corner sidewalk pieces at every intersection
# Replace _build_crosswalks to also add corner pieces
old1 = """static func _build_crosswalks(parent: Node3D) -> void:
\t# At each intersection (cross of two streets), draw 4 crosswalks
\t# (zebra stripes) across each street leg
\tfor x_pos in STREET_GRID:
\t\tfor z_pos in STREET_GRID:
\t\t\t# Intersection at (x_pos, z_pos)
\t\t\t# 4 crosswalks: north, south, east, west legs
\t\t\t# Each crosswalk spans ROAD_HALF_WIDTH*2 wide and ~3m deep
\t\t\t_make_crosswalk(parent, x_pos, z_pos - ROAD_HALF_WIDTH - 1.5, "x")  # north leg
\t\t\t_make_crosswalk(parent, x_pos, z_pos + ROAD_HALF_WIDTH + 1.5, "x")  # south leg
\t\t\t_make_crosswalk(parent, x_pos - ROAD_HALF_WIDTH - 1.5, z_pos, "z")  # west leg
\t\t\t_make_crosswalk(parent, x_pos + ROAD_HALF_WIDTH + 1.5, z_pos, "z")  # east leg"""

new1 = """static func _build_crosswalks(parent: Node3D) -> void:
\t# At each intersection, add: 4 crosswalks + 4 corner sidewalk pieces
\tfor x_pos in STREET_GRID:
\t\tfor z_pos in STREET_GRID:
\t\t\t# 4 crosswalks (zebra stripes) — one per street leg
\t\t\t_make_crosswalk(parent, x_pos, z_pos - ROAD_HALF_WIDTH - 1.5, "x")  # north
\t\t\t_make_crosswalk(parent, x_pos, z_pos + ROAD_HALF_WIDTH + 1.5, "x")  # south
\t\t\t_make_crosswalk(parent, x_pos - ROAD_HALF_WIDTH - 1.5, z_pos, "z")  # west
\t\t\t_make_crosswalk(parent, x_pos + ROAD_HALF_WIDTH + 1.5, z_pos, "z")  # east
\t\t\t# 4 corner sidewalk pieces (fill the gaps at intersection corners)
\t\t\tfor cx_sign in [-1, 1]:
\t\t\t\tfor cz_sign in [-1, 1]:
\t\t\t\t\tvar corner_x = x_pos + cx_sign * (ROAD_HALF_WIDTH + SIDEWALK_WIDTH / 2)
\t\t\t\t\tvar corner_z = z_pos + cz_sign * (ROAD_HALF_WIDTH + SIDEWALK_WIDTH / 2)
\t\t\t\t\t_make_sidewalk_corner(parent, corner_x, corner_z)

static func _make_sidewalk_corner(parent: Node3D, x: float, z: float) -> void:
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

assert old1 in c, "old1 (crosswalks) not found"
c = c.replace(old1, new1)

# Fix 2: Make crosswalk stripes wider and longer (visible)
old2 = """static func _make_crosswalk(parent: Node3D, x: float, z: float, axis: String) -> void:
\t# Zebra stripes: white bars across the street
\tvar stripe_width = 0.5
\tvar stripe_count = 8
\tvar stripe_spacing = (ROAD_HALF_WIDTH * 2) / stripe_count
\tfor i in range(stripe_count):
\t\tvar offset = (i - (stripe_count - 1) / 2.0) * stripe_spacing
\t\tvar stripe = MeshInstance3D.new()
\t\tvar s_mesh = BoxMesh.new()
\t\tif axis == "x":
\t\t\t# Crosswalk runs east-west, stripes are perpendicular (along z)
\t\t\ts_mesh.size = Vector3(stripe_width, 0.01, 3)
\t\t\tstripe.position = Vector3(x + offset, 0.04, z)
\t\telse:
\t\t\t# Crosswalk runs north-south, stripes are perpendicular (along x)
\t\t\ts_mesh.size = Vector3(3, 0.01, stripe_width)
\t\t\tstripe.position = Vector3(x, 0.04, z + offset)
\t\tstripe.mesh = s_mesh
\t\tvar smat = StandardMaterial3D.new()
\t\tsmat.albedo_color = Color(0.95, 0.95, 0.95)  # white
\t\tsmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
\t\tstripe.material_override = smat
\t\tparent.add_child(stripe)"""

new2 = """static func _make_crosswalk(parent: Node3D, x: float, z: float, axis: String) -> void:
\t# Zebra stripes: white bars across the FULL width of the street
\tvar stripe_width = 0.6  # wider stripes (more visible)
\tvar stripe_count = 6    # fewer stripes, more spacing
\tvar stripe_length = ROAD_HALF_WIDTH * 2 - 0.5  # spans almost full street width
\tvar stripe_spacing = 0.8  # space between stripes along crosswalk direction
\tfor i in range(stripe_count):
\t\tvar offset = (i - (stripe_count - 1) / 2.0) * stripe_spacing
\t\tvar stripe = MeshInstance3D.new()
\t\tvar s_mesh = BoxMesh.new()
\t\tif axis == "x":
\t\t\t# Crosswalk runs east-west (along x), stripes perpendicular (along z)
\t\t\ts_mesh.size = Vector3(stripe_width, 0.02, stripe_length)
\t\t\tstripe.position = Vector3(x + offset, 0.05, z)
\t\telse:
\t\t\t# Crosswalk runs north-south (along z), stripes perpendicular (along x)
\t\t\ts_mesh.size = Vector3(stripe_length, 0.02, stripe_width)
\t\t\tstripe.position = Vector3(x, 0.05, z + offset)
\t\tstripe.mesh = s_mesh
\t\tvar smat = StandardMaterial3D.new()
\t\tsmat.albedo_color = Color(0.95, 0.95, 0.95)  # white
\t\tsmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
\t\tstripe.material_override = smat
\t\tparent.add_child(stripe)"""

assert old2 in c, "old2 (make_crosswalk) not found"
c = c.replace(old2, new2)

with open(PATH1, 'w') as f:
    f.write(c)
print("OK - WorldBuilder.gd: corners + crosswalks fixed")

# ============ GameScene.gd: Fix 4 (more NPCs) ============
PATH2 = "/home/z/my-project/godot/scripts/GameScene.gd"
with open(PATH2) as f:
    c = f.read()

# Increase NPC counts 3x
old3 = """\t# Pedestrians — distributed per district based on new layout
\tvar ped_configs = [
\t\t{"district": "downtown", "count": 12, "colors": ["#1e293b", "#0f172a", "#374151", "#4b5563"]},
\t\t{"district": "harbor", "count": 5, "colors": ["#1c1917", "#292524", "#44403c"]},
\t\t{"district": "slums", "count": 10, "colors": ["#7c2d12", "#9a3412", "#451a03", "#1c1917"]},
\t\t{"district": "industrial", "count": 6, "colors": ["#3f3f46", "#525252", "#27272a"]},
\t\t{"district": "suburbs", "count": 5, "colors": ["#525252", "#737373", "#404040"]},
\t\t{"district": "rural", "count": 3, "colors": ["#6b5b4a", "#7a6a5a"]},
\t]"""
new3 = """\t# Pedestrians — distributed per district (3x more NPCs for livelier city)
\tvar ped_configs = [
\t\t{"district": "downtown", "count": 35, "colors": ["#1e293b", "#0f172a", "#374151", "#4b5563"]},
\t\t{"district": "harbor", "count": 15, "colors": ["#1c1917", "#292524", "#44403c"]},
\t\t{"district": "slums", "count": 30, "colors": ["#7c2d12", "#9a3412", "#451a03", "#1c1917"]},
\t\t{"district": "industrial", "count": 18, "colors": ["#3f3f46", "#525252", "#27272a"]},
\t\t{"district": "suburbs", "count": 15, "colors": ["#525252", "#737373", "#404040"]},
\t\t{"district": "rural", "count": 8, "colors": ["#6b5b4a", "#7a6a5a"]},
\t]"""
assert old3 in c, "old3 (NPC counts) not found"
c = c.replace(old3, new3)

with open(PATH2, 'w') as f:
    f.write(c)
print("OK - GameScene.gd: NPC counts tripled")

# ============ NPC.gd: Fix 3 (better street avoidance) ============
PATH3 = "/home/z/my-project/godot/scripts/NPC.gd"
with open(PATH3) as f:
    c = f.read()

# Increase street buffer (was 4.5m, make it 5.5m to keep NPCs further from roads)
old4 = """static var ROAD_HALF: float = 4.5  # 4m half-width + 0.5m buffer"""
new4 = """static var ROAD_HALF: float = 5.5  # 4m half-width + 1.5m buffer (keep NPCs on sidewalk)"""
assert old4 in c, "old4 (road buffer) not found"
c = c.replace(old4, new4)

# Also make _pick_new_target try harder (20 attempts instead of 10)
old5 = """func _pick_new_target():
\t# Try to find a target that's NOT on a street (keep NPC on sidewalks/buildings)
\tfor attempt in range(10):"""
new5 = """func _pick_new_target():
\t# Try to find a target that's NOT on a street (keep NPC on sidewalks/buildings)
\tfor attempt in range(20):"""
assert old5 in c, "old5 (pick_new_target attempts) not found"
c = c.replace(old5, new5)

with open(PATH3, 'w') as f:
    f.write(c)
print("OK - NPC.gd: better street avoidance")

# ============ GameScene.gd: Fix 5 (car collision box lower) ============
# The issue: collision box bottom is at y=0.15, but wheels are at y=0.55
# with radius 0.4 -> wheel bottom at y=0.15. That should match.
# But move_and_slide might not be snapping properly. Let's lower the
# collision box so its bottom is at y=0 (ground level), then wheels
# (bottom at 0.15) will be slightly above ground but that's better than
# wheels in ground.
PATH4 = "/home/z/my-project/godot/scripts/GameScene.gd"
with open(PATH4) as f:
    c = f.read()

old6 = """\t\tshape.size = Vector3(2.0, 1.5, 4.5)  # matches new larger car body
\t\tcol.shape = shape
\t\tcol.position = Vector3(0, 0.9, 0)  # center of body"""
new6 = """\t\tshape.size = Vector3(2.0, 1.4, 4.5)  # slightly shorter to lower center of mass
\t\tcol.shape = shape
\t\tcol.position = Vector3(0, 0.7, 0)  # lowered: bottom at y=0.0 (ground level)"""
assert old6 in c, "old6 (vehicle collision) not found"
c = c.replace(old6, new6)

with open(PATH4, 'w') as f:
    f.write(c)
print("OK - GameScene.gd: vehicle collision lowered (wheels above ground)")

# ============ Vehicle.gd: lower wheels to match new collision ============
PATH5 = "/home/z/my-project/godot/scripts/Vehicle.gd"
with open(PATH5) as f:
    c = f.read()

# Wheels: y=0.55 -> y=0.4 (wheel bottom at y=0.0 = ground level)
old7 = "\t# Wheel y-position must match collision box bottom (y=0.15).\n\t# Wheel radius=0.4, so wheel center at y=0.55 -> bottom at y=0.15.\n\tfor pos in [Vector3(-0.95, 0.55, 1.5), Vector3(0.95, 0.55, 1.5), Vector3(-0.95, 0.55, -1.5), Vector3(0.95, 0.55, -1.5)]:"
new7 = "\t# Wheel y-position: radius=0.4, center at y=0.4 -> bottom at y=0.0 (ground level)\n\tfor pos in [Vector3(-0.95, 0.4, 1.5), Vector3(0.95, 0.4, 1.5), Vector3(-0.95, 0.4, -1.5), Vector3(0.95, 0.4, -1.5)]:"
assert old7 in c, "old7 (wheel positions) not found"
c = c.replace(old7, new7)

# Body: y=0.95 -> y=0.8 (sits above wheels, wheel top at 0.8)
old8 = "\tbody.position = Vector3(0, 0.95, 0)  # body sits at 0.95m (above wheels at 0.55+0.4=0.95)"
new8 = "\tbody.position = Vector3(0, 0.8, 0)  # body sits at 0.8m (above wheels at 0.4+0.4=0.8)"
assert old8 in c, "old8 (body position) not found"
c = c.replace(old8, new8)

# Cabin: y=1.95 -> y=1.7 (on top of body, body top at 0.8+0.6=1.4)
old9 = "\tcabin.position = Vector3(0, 1.95, -0.2)  # sits on top of body (body top at 1.55)"
new9 = "\tcabin.position = Vector3(0, 1.7, -0.2)  # sits on top of body (body top at 1.4)"
assert old9 in c, "old9 (cabin position) not found"
c = c.replace(old9, new9)

# Windshield: y=1.95 -> y=1.7
old10 = "\twind.position = Vector3(0, 1.95, 0.95)  # at cabin height"
new10 = "\twind.position = Vector3(0, 1.7, 0.95)  # at cabin height"
assert old10 in c, "old10 (windshield position) not found"
c = c.replace(old10, new10)

# Headlights: y=1.0 -> y=0.85 (front of body)
old11 = "\tfor x in [-0.75, 0.75]:\n\t\tvar hl = OmniLight3D.new()\n\t\thl.position = Vector3(x, 1.0, 2.25)  # at front of body (raised)"
new11 = "\tfor x in [-0.75, 0.75]:\n\t\tvar hl = OmniLight3D.new()\n\t\thl.position = Vector3(x, 0.85, 2.25)  # at front of body"
assert old11 in c, "old11 (headlights) not found"
c = c.replace(old11, new11)

# Taillights: y=1.0 -> y=0.85
old12 = "\tfor x in [-0.75, 0.75]:\n\t\tvar tl = OmniLight3D.new()\n\t\ttl.position = Vector3(x, 1.0, -2.25)  # at rear of body (raised)"
new12 = "\tfor x in [-0.75, 0.75]:\n\t\tvar tl = OmniLight3D.new()\n\t\ttl.position = Vector3(x, 0.85, -2.25)  # at rear of body"
assert old12 in c, "old12 (taillights) not found"
c = c.replace(old12, new12)

with open(PATH5, 'w') as f:
    f.write(c)
print("OK - Vehicle.gd: wheels at ground level, body lowered to match")
