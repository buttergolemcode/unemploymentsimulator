#!/usr/bin/env python3
"""Proper vehicle physics fix: ground clearance + better floor detection.

The real issue: collision box bottom was AT ground level (y=0), so when
the car drove onto a sidewalk (y=0.15), the box couldn't climb over it.
Instead the car got stuck or wheels glitched through.

Real cars have GROUND CLEARANCE — the chassis sits above the ground,
only wheels touch. We model this by:
1. Raising the collision box (bottom at y=0.2, gives 20cm clearance)
2. Increasing floor_snap_length (0.3 -> 0.5) so car snaps to raised surfaces
3. Setting floor_max_angle to allow climbing sidewalks (15cm steps)
4. Wheels visual position matches actual ground contact (y=0.4)
"""

# ============ GameScene.gd: Raise vehicle collision box (ground clearance) ============
PATH1 = "/home/z/my-project/godot/scripts/GameScene.gd"
with open(PATH1) as f:
    c = f.read()

old1 = """\t\tshape.size = Vector3(2.0, 1.4, 4.5)  # slightly shorter to lower center of mass
\t\tcol.shape = shape
\t\tcol.position = Vector3(0, 0.7, 0)  # lowered: bottom at y=0.0 (ground level)"""
new1 = """\t\t# Collision box with GROUND CLEARANCE (like real car chassis)
\t\t# Box bottom at y=0.2 (20cm clearance above road) — car can drive
\t\t# over sidewalks (15cm) and small obstacles without getting stuck.
\t\t# Wheels (visual) reach down to y=0 to show ground contact.
\t\tshape.size = Vector3(1.9, 1.2, 4.3)
\t\tcol.shape = shape
\t\tcol.position = Vector3(0, 0.8, 0)  # center at y=0.8, bottom at y=0.2"""
assert old1 in c, "old1 (vehicle collision) not found"
c = c.replace(old1, new1)

with open(PATH1, 'w') as f:
    f.write(c)
print("OK - GameScene.gd: vehicle collision raised (ground clearance)")

# ============ Vehicle.gd: Better floor detection + match wheel positions ============
PATH2 = "/home/z/my-project/godot/scripts/Vehicle.gd"
with open(PATH2) as f:
    c = f.read()

# Improve floor detection settings — allow climbing sidewalks
old2 = """func _ready():
\tadd_to_group("vehicle")
\t# Floor detection for gravity
\tmotion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
\tfloor_snap_length = 0.3
\t_build_mesh()
\trotation.y = yaw + PI"""
new2 = """func _ready():
\tadd_to_group("vehicle")
\t# Floor detection — tuned for driving over sidewalks and small steps
\tmotion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
\tfloor_snap_length = 0.5  # snap to floor within 50cm (was 0.3) — handles sidewalk steps
\tfloor_max_angle = deg_to_rad(60)  # allow climbing slopes up to 60° (was default 45°)
\t_build_mesh()
\trotation.y = yaw + PI"""
assert old2 in c, "old2 (vehicle ready) not found"
c = c.replace(old2, new2)

# Wheel positions: y=0.4 (wheel bottom at y=0 = ground contact)
# This matches the visual ground level — wheels appear to touch ground.
# When car drives onto sidewalk (y=0.15), floor_snap pulls car up,
# wheels rise with car, still appear to touch new surface.
old3 = "\t# Wheel y-position: radius=0.4, center at y=0.4 -> bottom at y=0.0 (ground level)\n\tfor pos in [Vector3(-0.95, 0.4, 1.5), Vector3(0.95, 0.4, 1.5), Vector3(-0.95, 0.4, -1.5), Vector3(0.95, 0.4, -1.5)]:"
new3 = "\t# Wheel y-position: radius=0.4, center at y=0.4 -> bottom at y=0.0 (ground contact)\n\t# When car drives onto sidewalk, floor_snap raises entire car (including wheels)\n\tfor pos in [Vector3(-0.95, 0.4, 1.5), Vector3(0.95, 0.4, 1.5), Vector3(-0.95, 0.4, -1.5), Vector3(0.95, 0.4, -1.5)]:"
assert old3 in c, "old3 (wheel positions) not found"
c = c.replace(old3, new3)

# Body position: y=0.8 (above wheels, matches collision box center)
# Body is 1.0m tall, so top at y=1.3, bottom at y=0.3 (above ground clearance 0.2)
old4 = "\tbody.position = Vector3(0, 0.8, 0)  # body sits at 0.8m (above wheels at 0.4+0.4=0.8)"
new4 = "\tbody.position = Vector3(0, 0.9, 0)  # body center at 0.9m (above wheels, matches collision box)"
assert old4 in c, "old4 (body position) not found"
c = c.replace(old4, new4)

# Cabin: y=1.7 -> y=1.8 (on top of body, body top at 0.9+0.5=1.4)
old5 = "\tcabin.position = Vector3(0, 1.7, -0.2)  # sits on top of body (body top at 1.4)"
new5 = "\tcabin.position = Vector3(0, 1.8, -0.2)  # on top of body (body top at 1.4)"
assert old5 in c, "old5 (cabin position) not found"
c = c.replace(old5, new5)

# Windshield: y=1.7 -> y=1.8
old6 = "\twind.position = Vector3(0, 1.7, 0.95)  # at cabin height"
new6 = "\twind.position = Vector3(0, 1.8, 0.95)  # at cabin height"
assert old6 in c, "old6 (windshield position) not found"
c = c.replace(old6, new6)

# Headlights: y=0.85 (front of body)
old7 = "\tfor x in [-0.75, 0.75]:\n\t\tvar hl = OmniLight3D.new()\n\t\thl.position = Vector3(x, 0.85, 2.25)  # at front of body"
new7 = "\tfor x in [-0.75, 0.75]:\n\t\tvar hl = OmniLight3D.new()\n\t\thl.position = Vector3(x, 0.9, 2.25)  # at front of body"
assert old7 in c, "old7 (headlights) not found"
c = c.replace(old7, new7)

# Taillights
old8 = "\tfor x in [-0.75, 0.75]:\n\t\tvar tl = OmniLight3D.new()\n\t\ttl.position = Vector3(x, 0.85, -2.25)  # at rear of body"
new8 = "\tfor x in [-0.75, 0.75]:\n\t\tvar tl = OmniLight3D.new()\n\t\ttl.position = Vector3(x, 0.9, -2.25)  # at rear of body"
assert old8 in c, "old8 (taillights) not found"
c = c.replace(old8, new8)

with open(PATH2, 'w') as f:
    f.write(c)
print("OK - Vehicle.gd: floor detection + ground clearance setup")
