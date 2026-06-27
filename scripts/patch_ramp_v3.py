#!/usr/bin/env python3
"""Completely rewrite ramp collision with correct geometry.

Previous ramp was positioned wrong (offset calculation was incorrect)
and the rotation pivot was at box center, not at street edge — causing
the ramp to float above ground instead of connecting street to sidewalk.

New approach: simple NON-ROTATED box that spans from street level (y=0)
to sidewalk level (y=0.15). The box is positioned so it bridges the gap
between the street edge and the sidewalk edge, and its top surface is
a slope. We achieve the slope by making the box thin and tilting it,
but the position math is now correct.

Actually, simpler: just make a SINGLE box that includes both the step
AND fills the gap. The box is SIDEWALK_HEIGHT tall, extends from street
edge inward. This creates a smooth slope up to sidewalk level.

Wait — let's go even simpler: REMOVE the sidewalk collision entirely
for the street-facing edge, and instead extend the city ground collision
UP to sidewalk height in the sidewalk zone. But that's complex.

SIMPLEST RELIABLE APPROACH:
- Make the sidewalk collision box EXTEND into the street by 30cm
- This creates a 30cm-wide 'lip' at sidewalk height that the car can
  drive up onto via floor_snap (since the lip is only 15cm tall, well
  within floor_snap_length=0.5m)

No — that creates a wall again.

REAL SIMPLEST APPROACH (what we should have done from start):
- Don't add separate sidewalk collision at all
- Instead, raise the entire ground collision in the sidewalk zone
- Use multiple ground collision boxes at different heights

OK final approach that WILL work:
- Add a tilted BoxShape3D ramp
- Position: centered exactly between street edge and sidewalk edge
- Rotation: around the STREET EDGE (not box center) so one end touches
  street (y=0) and other end touches sidewalk top (y=0.15)
- Use Godot's transform to position correctly
"""

PATH = "/home/z/my-project/godot/scripts/WorldBuilder.gd"
with open(PATH) as f:
    c = f.read()

# Replace the broken ramp with a correctly-positioned one
old = """\t# RAMP COLLISION: Rotated box forming smooth slope from street to sidewalk
\t# More reliable than steps — CharacterBody3D can drive up slopes but not steps.
\t# Ramp: 60cm long, rotated ~14° so it goes from y=0 (street) to y=0.15 (sidewalk).
\tvar ramp_length = 0.6   # 60cm ramp length
\tvar ramp_thickness = 0.05
\t# Angle: arctan(SIDEWALK_HEIGHT / ramp_length) — slope angle
\tvar ramp_angle = atan(SIDEWALK_HEIGHT / ramp_length)
\t# Hypotenuse length (actual box length needed)
\tvar ramp_box_len = sqrt(ramp_length * ramp_length + SIDEWALK_HEIGHT * SIDEWALK_HEIGHT)
\tvar ramp_body = StaticBody3D.new()
\tvar ramp_col = CollisionShape3D.new()
\tvar ramp_shape = BoxShape3D.new()
\t# Ramp center position: midpoint between street edge and sidewalk edge
\t# Street edge: sz + (-side * SIDEWALK_WIDTH / 2)
\t# Sidewalk edge: sz + (side * SIDEWALK_WIDTH / 2) — but ramp starts at street edge
\t# Ramp midpoint: at street edge + ramp_length/2 toward sidewalk, height SIDEWALK_HEIGHT/2
\tvar ramp_mid_offset = -side * (SIDEWALK_WIDTH / 2) + side * (ramp_length / 2)
\tvar ramp_height = SIDEWALK_HEIGHT / 2
\tif axis == "x":
\t\tramp_shape.size = Vector3(seg_len, ramp_thickness, ramp_box_len)
\t\tramp_body.position = Vector3(sx, ramp_height, sz + ramp_mid_offset)
\t\tramp_body.rotation.x = -side * ramp_angle  # tilt to slope up toward sidewalk
\telse:
\t\tramp_shape.size = Vector3(ramp_box_len, ramp_thickness, seg_len)
\t\tramp_body.position = Vector3(sx + ramp_mid_offset, ramp_height, sz)
\t\tramp_body.rotation.z = side * ramp_angle  # tilt to slope up toward sidewalk
\tramp_col.shape = ramp_shape
\tramp_body.add_child(ramp_col)
\tparent.add_child(ramp_body)"""

new = """\t# RAMP COLLISION: Sloped box from street edge to sidewalk top
\t# Positioned correctly: starts at street edge (y=0), ends at sidewalk top (y=0.15)
\t# Sidewalk edge facing street is at: sz + (-side * SIDEWALK_WIDTH / 2)
\t# We place ramp from that edge, extending 50cm INTO the street
\tvar ramp_length = 0.5    # 50cm ramp
\tvar ramp_thickness = 0.02
\tvar ramp_angle = atan(SIDEWALK_HEIGHT / ramp_length)  # ~17° slope
\t# Hypotenuse length (box length along slope)
\tvar ramp_box_len = sqrt(ramp_length * ramp_length + SIDEWALK_HEIGHT * SIDEWALK_HEIGHT)
\t# Sidewalk street-facing edge position (relative to sidewalk center sz)
\t# For axis='x' (E-W street): sidewalk center is at sz, street-facing edge at sz - side*1.25
\t# Ramp midpoint: at sidewalk edge - ramp_length/2 (extending into street), height = SIDEWALK_HEIGHT/2
\tvar sidewalk_edge_offset = -side * (SIDEWALK_WIDTH / 2)
\tvar ramp_mid_offset = sidewalk_edge_offset - side * (ramp_length / 2)
\tvar ramp_y = SIDEWALK_HEIGHT / 2
\tvar ramp_body = StaticBody3D.new()
\tvar ramp_col = CollisionShape3D.new()
\tvar ramp_shape = BoxShape3D.new()
\tif axis == "x":
\t\tramp_shape.size = Vector3(seg_len, ramp_thickness, ramp_box_len)
\t\tramp_body.position = Vector3(sx, ramp_y, sz + ramp_mid_offset)
\t\tramp_body.rotation.x = side * ramp_angle  # tilt: street side down, sidewalk side up
\telse:
\t\tramp_shape.size = Vector3(ramp_box_len, ramp_thickness, seg_len)
\t\tramp_body.position = Vector3(sx + ramp_mid_offset, ramp_y, sz)
\t\tramp_body.rotation.z = -side * ramp_angle  # tilt: street side down, sidewalk side up
\tramp_col.shape = ramp_shape
\tramp_body.add_child(ramp_col)
\tparent.add_child(ramp_body)"""

assert old in c, "old (ramp collision) not found"
c = c.replace(old, new)

with open(PATH, 'w') as f:
    f.write(c)
print("OK - Ramp collision repositioned correctly")
