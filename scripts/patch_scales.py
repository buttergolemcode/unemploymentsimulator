#!/usr/bin/env python3
"""Adjust all scales to be realistic relative to each other.

Realistic reference (in meters):
- Player: 1.8m tall (capsule radius 0.4, height 1.8 — already correct)
- Car: 4.5m long, 1.8m wide, 1.5m high (currently 4.4 x 2 x 0.7 — too low!)
- Sidewalk: 2.5m wide, 0.15m high (currently 3m wide — OK)
- Road: 7m wide total (2 lanes of 3.5m each) → half-width 3.5m (currently 8m — too wide!)
- Block: 80m (was 100m — slightly too large)
- Skyscraper: 50-150m tall (currently 30-100 — OK but bump up)
- House: 6-10m tall, 8-15m footprint
"""

import re

# ============ WorldBuilder.gd ============
PATH1 = "/home/z/my-project/godot/scripts/WorldBuilder.gd"
with open(PATH1) as f:
    c = f.read()

# 1. Adjust road/sidewalk constants (narrower roads, slimmer sidewalks)
old1 = """const ROAD_HALF_WIDTH: float = 8.0      # street is 16m wide (4 lanes)
const SIDEWALK_WIDTH: float = 3.0       # 3m sidewalk on each side
const SIDEWALK_HEIGHT: float = 0.15     # raised sidewalk
const BLOCK_SIZE: float = 100.0         # distance between street centers
const BUILDING_MARGIN: float = 1.0      # gap between building and sidewalk"""
new1 = """const ROAD_HALF_WIDTH: float = 4.0       # street is 8m wide (2 lanes of 4m)
const SIDEWALK_WIDTH: float = 2.5       # 2.5m sidewalk on each side (realistic)
const SIDEWALK_HEIGHT: float = 0.15     # raised sidewalk (15cm curb)
const BLOCK_SIZE: float = 80.0          # 80m blocks (was 100m, more NYC-like)
const BUILDING_MARGIN: float = 0.5      # buildings flush with sidewalk (NYC-style)"""
assert old1 in c, "old1 not found"
c = c.replace(old1, new1)

# 2. Adjust district height ranges (taller skyscrapers, realistic houses)
old2 = """"downtown": {
\t\t\t"color": "#475569", "height_min": 30, "height_max": 100, "ground": "#1a1a1a","""
new2 = """"downtown": {
\t\t\t"color": "#475569", "height_min": 40, "height_max": 150, "ground": "#1a1a1a","""
assert old2 in c, "old2 (downtown) not found"
c = c.replace(old2, new2)

old3 = """"harbor": {
\t\t\t"color": "#1c1917", "height_min": 8, "height_max": 22, "ground": "#171717","""
new3 = """"harbor": {
\t\t\t"color": "#1c1917", "height_min": 10, "height_max": 25, "ground": "#171717","""
assert old3 in c, "old3 (harbor) not found"
c = c.replace(old3, new3)

old4 = """"slums": {
\t\t\t"color": "#451a03", "height_min": 5, "height_max": 14, "ground": "#1a0f0a","""
new4 = """"slums": {
\t\t\t"color": "#451a03", "height_min": 4, "height_max": 10, "ground": "#1a0f0a","""
assert old4 in c, "old4 (slums) not found"
c = c.replace(old4, new4)

old5 = """"industrial": {
\t\t\t"color": "#1f2937", "height_min": 9, "height_max": 24, "ground": "#161616","""
new5 = """"industrial": {
\t\t\t"color": "#1f2937", "height_min": 10, "height_max": 30, "ground": "#161616","""
assert old5 in c, "old5 (industrial) not found"
c = c.replace(old5, new5)

old6 = """"suburbs": {
\t\t\t"color": "#525252", "height_min": 4, "height_max": 9, "ground": "#1a2a1a","""
new6 = """"suburbs": {
\t\t\t"color": "#525252", "height_min": 5, "height_max": 10, "ground": "#1a2a1a","""
assert old6 in c, "old6 (suburbs) not found"
c = c.replace(old6, new6)

# 3. Adjust scheme building sizes (more realistic)
old7 = """const SCHEME_BUILDINGS: Array = [
\t# Downtown (center)
\t{"id": "trading", "name": "Trading Floor", "emoji": "📈",
\t "x": -50, "z": -50, "w": 18, "d": 16, "h": 50, "color": "#22d3ee"},
\t{"id": "wirefraud", "name": "Corporate Tower", "emoji": "💸",
\t "x": 50, "z": -50, "w": 22, "d": 20, "h": 90, "color": "#64748b"},
\t{"id": "taxfraud", "name": "Accountant Office", "emoji": "🧾",
\t "x": -150, "z": 50, "w": 14, "d": 12, "h": 28, "color": "#eab308"},
\t{"id": "gambling", "name": "Casino", "emoji": "🎰",
\t "x": 150, "z": 100, "w": 20, "d": 18, "h": 22, "color": "#f59e0b"},
\t# Slums (SW)
\t{"id": "drugs", "name": "Trap House", "emoji": "💊",
\t "x": -350, "z": 250, "w": 12, "d": 10, "h": 10, "color": "#a855f7"},
\t{"id": "scam", "name": "Internet Cafe", "emoji": "🎣",
\t "x": -250, "z": 350, "w": 10, "d": 9, "h": 8, "color": "#ec4899"},
\t{"id": "robbery", "name": "Corner Store", "emoji": "🔫",
\t "x": -350, "z": 350, "w": 9, "d": 9, "h": 6, "color": "#ef4444"},
\t# Industrial (NW)
\t{"id": "ecom", "name": "E-Com Warehouse", "emoji": "📦",
\t "x": -350, "z": -250, "w": 20, "d": 18, "h": 14, "color": "#4ade80"},
]"""
new7 = """const SCHEME_BUILDINGS: Array = [
\t# Downtown (center) — tall skyscrapers (40-120m)
\t{"id": "trading", "name": "Trading Floor", "emoji": "📈",
\t "x": -50, "z": -50, "w": 25, "d": 22, "h": 70, "color": "#22d3ee"},
\t{"id": "wirefraud", "name": "Corporate Tower", "emoji": "💸",
\t "x": 50, "z": -50, "w": 30, "d": 25, "h": 120, "color": "#64748b"},
\t{"id": "taxfraud", "name": "Accountant Office", "emoji": "🧾",
\t "x": -150, "z": 50, "w": 18, "d": 16, "h": 35, "color": "#eab308"},
\t{"id": "gambling", "name": "Casino", "emoji": "🎰",
\t "x": 150, "z": 100, "w": 25, "d": 22, "h": 28, "color": "#f59e0b"},
\t# Slums (SW) — small rundown houses (4-8m)
\t{"id": "drugs", "name": "Trap House", "emoji": "💊",
\t "x": -350, "z": 250, "w": 10, "d": 8, "h": 6, "color": "#a855f7"},
\t{"id": "scam", "name": "Internet Cafe", "emoji": "🎣",
\t "x": -250, "z": 350, "w": 8, "d": 7, "h": 5, "color": "#ec4899"},
\t{"id": "robbery", "name": "Corner Store", "emoji": "🔫",
\t "x": -350, "z": 350, "w": 7, "d": 7, "h": 4, "color": "#ef4444"},
\t# Industrial (NW) — large warehouse (15m)
\t{"id": "ecom", "name": "E-Com Warehouse", "emoji": "📦",
\t "x": -350, "z": -250, "w": 25, "d": 22, "h": 15, "color": "#4ade80"},
]"""
assert old7 in c, "old7 (scheme buildings) not found"
c = c.replace(old7, new7)

# 4. Adjust landmark sizes (church tower removed, others scaled)
# Skyscrapers (skyline row) — make taller and more realistic
old8 = """\t# Skyline row (3 tall towers)
\t_skyscraper(parent, 150, -100, 12, 90, "#1e293b")
\t_skyscraper(parent, 175, -100, 12, 110, "#0f172a")
\t_skyscraper(parent, 200, -100, 12, 95, "#1e293b")"""
new8 = """\t# Skyline row (3 tall towers, 100-150m)
\t_skyscraper(parent, 150, -100, 18, 110, "#1e293b")
\t_skyscraper(parent, 175, -100, 18, 140, "#0f172a")
\t_skyscraper(parent, 200, -100, 18, 120, "#1e293b")"""
assert old8 in c, "old8 (skyline) not found"
c = c.replace(old8, new8)

# 5. Adjust stadium size (larger, more realistic)
old9 = """\t# Stadium
\t_stadium(parent, -250, 100)"""
new9 = """\t# Stadium (large, ~80m diameter)
\t_stadium(parent, -250, 100)"""
assert old9 in c, "old9 (stadium) not found"
c = c.replace(old9, new9)

# 6. Update _build_block to use new BLOCK_SIZE
old10 = """\t# Block bounds (100x100m block, with sidewalk + margin subtracted)
\tvar road_buffer = ROAD_HALF_WIDTH + SIDEWALK_WIDTH + BUILDING_MARGIN
\tvar block_inner = BLOCK_SIZE - 2 * road_buffer  # ~84m"""
new10 = """\t# Block bounds (BLOCK_SIZE wide, with sidewalk + margin subtracted)
\tvar road_buffer = ROAD_HALF_WIDTH + SIDEWALK_WIDTH + BUILDING_MARGIN
\tvar block_inner = BLOCK_SIZE - 2 * road_buffer  # ~70m for 80m block"""
assert old10 in c, "old10 (block bounds) not found"
c = c.replace(old10, new10)

with open(PATH1, 'w') as f:
    f.write(c)
print("OK - WorldBuilder.gd scales updated")

# ============ Vehicle.gd — adjust car body size ============
PATH2 = "/home/z/my-project/godot/scripts/Vehicle.gd"
with open(PATH2) as f:
    c = f.read()

# Make car body taller (0.7 -> 1.5m) and slightly wider
old11 = """\tvar body_m = BoxMesh.new()
\tbody_m.size = Vector3(2, 0.7, 4.4)
\tbody.mesh = body_m
\tbody.position = Vector3(0, 0.35, 0)"""
new11 = """\tvar body_m = BoxMesh.new()
\tbody_m.size = Vector3(1.9, 1.0, 4.2)  # realistic car: 1.9m wide, 1.0m body height, 4.2m long
\tbody.mesh = body_m
\tbody.position = Vector3(0, 0.65, 0)  # body sits at 0.65m (wheel top)"""
assert old11 in c, "old11 (car body) not found"
c = c.replace(old11, new11)

# Cabin
old12 = """\tvar cabin_m = BoxMesh.new()
\tcabin_m.size = Vector3(1.7, 0.6, 2.0)
\tcabin.mesh = cabin_m
\tcabin.position = Vector3(0, 1.0, -0.2)"""
new12 = """\tvar cabin_m = BoxMesh.new()
\tcabin_m.size = Vector3(1.6, 0.7, 1.8)  # cabin: 1.6m wide, 0.7m tall, 1.8m long
\tcabin.mesh = cabin_m
\tcabin.position = Vector3(0, 1.5, -0.2)  # sits on top of body"""
assert old12 in c, "old12 (car cabin) not found"
c = c.replace(old12, new12)

# Windshield
old13 = """\tvar wind_m = BoxMesh.new()
\twind_m.size = Vector3(1.6, 0.5, 0.1)
\twind.mesh = wind_m
\twind.position = Vector3(0, 1.0, 0.85)"""
new13 = """\tvar wind_m = BoxMesh.new()
\twind_m.size = Vector3(1.5, 0.6, 0.1)
\twind.mesh = wind_m
\twind.position = Vector3(0, 1.5, 0.85)  # at cabin height"""
assert old13 in c, "old13 (windshield) not found"
c = c.replace(old13, new13)

# Wheels — make realistic (0.35 radius was OK, but adjust positions)
old14 = """\tfor pos in [Vector3(-0.9, 0.35, 1.5), Vector3(0.9, 0.35, 1.5), Vector3(-0.9, 0.35, -1.5), Vector3(0.9, 0.35, -1.5)]:
\t\tvar wheel = MeshInstance3D.new()
\t\tvar w_m = CylinderMesh.new()
\t\tw_m.top_radius = 0.35
\t\tw_m.bottom_radius = 0.35
\t\tw_m.height = 0.25
\t\twheel.mesh = w_m
\t\twheel.rotation.z = PI / 2
\t\twheel.position = pos"""
new14 = """\tfor pos in [Vector3(-0.9, 0.35, 1.4), Vector3(0.9, 0.35, 1.4), Vector3(-0.9, 0.35, -1.4), Vector3(0.9, 0.35, -1.4)]:
\t\tvar wheel = MeshInstance3D.new()
\t\tvar w_m = CylinderMesh.new()
\t\tw_m.top_radius = 0.35  # 35cm radius = 70cm diameter (realistic)
\t\tw_m.bottom_radius = 0.35
\t\tw_m.height = 0.25  # 25cm tire width
\t\twheel.mesh = w_m
\t\twheel.rotation.z = PI / 2
\t\twheel.position = pos"""
assert old14 in c, "old14 (wheels) not found"
c = c.replace(old14, new14)

# Headlights
old15 = """\tfor x in [-0.6, 0.6]:
\t\tvar hl = OmniLight3D.new()
\t\thl.position = Vector3(x, 0.5, 2.2)"""
new15 = """\tfor x in [-0.7, 0.7]:
\t\tvar hl = OmniLight3D.new()
\t\thl.position = Vector3(x, 0.7, 2.1)  # at front of body"""
assert old15 in c, "old15 (headlights) not found"
c = c.replace(old15, new15)

# Taillights
old16 = """\tfor x in [-0.6, 0.6]:
\t\tvar tl = OmniLight3D.new()
\t\ttl.position = Vector3(x, 0.5, -2.2)"""
new16 = """\tfor x in [-0.7, 0.7]:
\t\tvar tl = OmniLight3D.new()
\t\ttl.position = Vector3(x, 0.7, -2.1)  # at rear of body"""
assert old16 in c, "old16 (taillights) not found"
c = c.replace(old16, new16)

with open(PATH2, 'w') as f:
    f.write(c)
print("OK - Vehicle.gd scales updated (box mesh fallback only)")

# ============ GameScene.gd — adjust vehicle collision shape ============
PATH3 = "/home/z/my-project/godot/scripts/GameScene.gd"
with open(PATH3) as f:
    c = f.read()

# Vehicle collision box (was 2x1.5x4.4 — too narrow, adjust to match new body)
old17 = """\t\tvar shape = BoxShape3D.new()
\t\tshape.size = Vector3(2, 1.5, 4.4)
\t\tcol.shape = shape
\t\tcol.position = Vector3(0, 0.75, 0)"""
new17 = """\t\tvar shape = BoxShape3D.new()
\t\tshape.size = Vector3(1.9, 1.5, 4.2)  # matches new car body size
\t\tcol.shape = shape
\t\tcol.position = Vector3(0, 0.85, 0)  # center of 1.5m tall body"""
assert old17 in c, "old17 (vehicle collision) not found"
c = c.replace(old17, new17)

# NPC collision (was 0.3 radius, 1.5 height — OK for human, but adjust)
old18 = """\t\tvar shape = CapsuleShape3D.new()
\t\tshape.radius = 0.3
\t\tshape.height = 1.5
\t\tcol.shape = shape
\t\tcol.position = Vector3(0, 0.75, 0)"""
new18 = """\t\tvar shape = CapsuleShape3D.new()
\t\tshape.radius = 0.35  # 35cm radius — realistic human shoulder width
\t\tshape.height = 1.7  # 1.7m tall capsule (covers head to feet)
\t\tcol.shape = shape
\t\tcol.position = Vector3(0, 0.85, 0)  # center at 0.85m"""
assert old18 in c, "old18 (NPC collision) not found"
c = c.replace(old18, new18)

with open(PATH3, 'w') as f:
    f.write(c)
print("OK - GameScene.gd scales updated")

# ============ GameScene.tscn — adjust player collision ============
PATH4 = "/home/z/my-project/godot/scenes/GameScene.tscn"
with open(PATH4) as f:
    c = f.read()

old19 = """[sub_resource type="CapsuleShape3D" id="CapsuleShape3D_player"]
radius = 0.4
height = 1.8"""
new19 = """[sub_resource type="CapsuleShape3D" id="CapsuleShape3D_player"]
radius = 0.35
height = 1.7"""
assert old19 in c, "old19 (player capsule) not found"
c = c.replace(old19, new19)

# Player collision shape position
old20 = """[node name="CollisionShape3D" type="CollisionShape3D" parent="Player"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.9, 0)
shape = SubResource("CapsuleShape3D_player")"""
new20 = """[node name="CollisionShape3D" type="CollisionShape3D" parent="Player"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.85, 0)
shape = SubResource("CapsuleShape3D_player")"""
assert old20 in c, "old20 (player collision shape) not found"
c = c.replace(old20, new20)

with open(PATH4, 'w') as f:
    f.write(c)
print("OK - GameScene.tscn scales updated")
