#!/usr/bin/env python3
"""Replace step collision with ROTATED BOX ramp (most reliable approach).

The step approach didn't work because Godot's CharacterBody3D can't
reliably climb multiple small steps. A rotated box creates a smooth
slope that the car can drive up reliably.

Ramp: 50cm long box, rotated to slope from y=0 (street) to y=0.15 (sidewalk).
Angle: arctan(0.15 / 0.5) ≈ 17° — well under floor_max_angle (60°).
"""

import math

PATH = "/home/z/my-project/godot/scripts/WorldBuilder.gd"
with open(PATH) as f:
    c = f.read()

# Replace the step collision with a rotated box ramp
old = """\t# STEP COLLISION: Thin low box extending slightly into street
\t# Creates a 5cm step (small enough for floor_snap to handle) that bridges
\t# the gap between street (y=0) and sidewalk (y=0.15). Car drives over this
\t# small step and floor_snap pulls it up onto sidewalk surface.
\tvar step_height = 0.05  # 5cm step — small enough for floor_snap (0.5m)
\tvar step_depth = 0.5    # extends 50cm into street from sidewalk edge
\tvar step_body = StaticBody3D.new()
\tvar step_col = CollisionShape3D.new()
\tvar step_shape = BoxShape3D.new()
\tif axis == "x":
\t\tstep_shape.size = Vector3(seg_len, step_height, step_depth)
\t\tstep_body.position = Vector3(sx, step_height / 2, sz + (-side * (SIDEWALK_WIDTH / 2 + step_depth / 2)))
\telse:
\t\tstep_shape.size = Vector3(step_depth, step_height, seg_len)
\t\tstep_body.position = Vector3(sx + (-side * (SIDEWALK_WIDTH / 2 + step_depth / 2)), step_height / 2, sz)
\tstep_col.shape = step_shape
\tstep_body.add_child(step_col)
\tparent.add_child(step_body)"""

new = """\t# RAMP COLLISION: Rotated box forming smooth slope from street to sidewalk
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

assert old in c, "old (step collision) not found"
c = c.replace(old, new)

with open(PATH, 'w') as f:
    f.write(c)
print("OK - Replaced step with rotated box ramp")
