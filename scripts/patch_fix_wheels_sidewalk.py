#!/usr/bin/env python3
"""Fix 2 issues:
1. Sidewalk: replace broken ramp with simple low collision box (5cm)
2. Wheels: disable pivot steering for FBX models (was causing arc-swing bug)
"""

# ============ WorldBuilder.gd: Replace ramp with simple low collision ============
PATH1 = "/home/z/my-project/godot/scripts/WorldBuilder.gd"
with open(PATH1) as f:
    c = f.read()

# Remove the ramp collision code and replace with a simpler approach:
# The sidewalk collision box stays at full height (0.15m) for standing on,
# but we ALSO add a thin low box (0.05m) that extends slightly into the street.
# This creates a small "step" that floor_snap can handle (5cm < snap_length 0.5m).
old1 = """\t# RAMP COLLISION: Sloped edge on street-facing side of sidewalk
\t# Allows cars to drive UP onto sidewalk instead of hitting a wall.
\t# Ramp goes from y=0 (street) to y=SIDEWALK_HEIGHT over 30cm depth.
\tvar ramp_depth = 0.3
\tvar ramp_body = StaticBody3D.new()
\tvar ramp_col = CollisionShape3D.new()
\tvar ramp_shape = ConvexPolygonShape3D.new()
\t# Street-facing direction: -side points toward street
\t# For side=-1 (sidewalk south of street): street is at +z, so street_z = +ramp_depth/2
\t# For side=+1 (sidewalk north of street): street is at -z, so street_z = -ramp_depth/2
\tvar street_offset = -side * (ramp_depth / 2)   # y=0 side (toward street)
\tvar sidewalk_offset = side * (ramp_depth / 2)   # y=SIDEWALK_HEIGHT side (toward sidewalk)
\tif axis == "x":
\t\t# Ramp runs along x-axis, slopes in z direction
\t\t# Position ramp at the street-facing edge of sidewalk
\t\tramp_body.position = Vector3(sx, 0, sz + (-side * SIDEWALK_WIDTH / 2))
\t\tramp_shape.points = PackedVector3Array([
\t\t\tVector3(-seg_len / 2, 0, street_offset),       # street bottom left
\t\t\tVector3(seg_len / 2, 0, street_offset),         # street bottom right
\t\t\tVector3(-seg_len / 2, 0, sidewalk_offset),      # under-ramp bottom left
\t\t\tVector3(seg_len / 2, 0, sidewalk_offset),       # under-ramp bottom right
\t\t\tVector3(-seg_len / 2, SIDEWALK_HEIGHT, sidewalk_offset),  # sidewalk top left
\t\t\tVector3(seg_len / 2, SIDEWALK_HEIGHT, sidewalk_offset),   # sidewalk top right
\t\t])
\telse:
\t\t# Ramp runs along z-axis, slopes in x direction
\t\tramp_body.position = Vector3(sx + (-side * SIDEWALK_WIDTH / 2), 0, sz)
\t\tramp_shape.points = PackedVector3Array([
\t\t\tVector3(street_offset, 0, -seg_len / 2),       # street bottom front
\t\t\tVector3(street_offset, 0, seg_len / 2),         # street bottom back
\t\t\tVector3(sidewalk_offset, 0, -seg_len / 2),      # under-ramp bottom front
\t\t\tVector3(sidewalk_offset, 0, seg_len / 2),       # under-ramp bottom back
\t\t\tVector3(sidewalk_offset, SIDEWALK_HEIGHT, -seg_len / 2),  # sidewalk top front
\t\t\tVector3(sidewalk_offset, SIDEWALK_HEIGHT, seg_len / 2),   # sidewalk top back
\t\t])
\tramp_col.shape = ramp_shape
\tramp_body.add_child(ramp_col)
\tparent.add_child(ramp_body)"""

new1 = """\t# STEP COLLISION: Thin low box extending slightly into street
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

assert old1 in c, "old1 (ramp collision) not found"
c = c.replace(old1, new1)

with open(PATH1, 'w') as f:
    f.write(c)
print("OK - WorldBuilder.gd: ramp replaced with simple step collision")

# ============ Vehicle.gd: Disable FBX pivot steering ============
PATH2 = "/home/z/my-project/godot/scripts/Vehicle.gd"
with open(PATH2) as f:
    c = f.read()

# In _find_wheels: skip pivot wrapping for FBX models entirely.
# Only box-mesh fallback uses pivots (created in _build_box_mesh).
old2 = """func _find_wheels(root):
\t# Quaternius cars name wheel nodes like "NormalCar1_FrontLeftWheel",
\t# "NormalCar1_FrontRightWheel", "NormalCar1_BackWheels".
\t_wheel_nodes.clear()
\t_front_wheel_pivots.clear()
\t_front_wheels_raw.clear()
\t_rear_wheels.clear()
\t_collect_wheels(root)
\t# Wrap each front wheel in a pivot Node3D so we can rotate it on Y
\t# without disturbing the wheel mesh's local orientation (which would
\t# cause the wheel to show its tire-side instead of the rim/Felge).
\tfor wheel in _front_wheels_raw:
\t\tvar pivot = Node3D.new()
\t\tpivot.name = "SteerPivot_" + wheel.name
\t\tvar parent_node = wheel.get_parent()
\t\tvar wheel_pos = wheel.position
\t\tvar wheel_rot = wheel.rotation
\t\tparent_node.remove_child(wheel)
\t\tpivot.position = wheel_pos
\t\tparent_node.add_child(pivot)
\t\twheel.position = Vector3.ZERO
\t\twheel.rotation = wheel_rot  # preserve original orientation
\t\tpivot.add_child(wheel)
\t\t_front_wheel_pivots.append(pivot)"""

new2 = """func _find_wheels(root):
\t# Quaternius cars name wheel nodes like "NormalCar1_FrontLeftWheel",
\t# "NormalCar1_FrontRightWheel", "NormalCar1_BackWheels".
\t_wheel_nodes.clear()
\t_front_wheel_pivots.clear()
\t_front_wheels_raw.clear()
\t_rear_wheels.clear()
\t_collect_wheels(root)
\t# NOTE: FBX wheel pivot wrapping DISABLED — was causing wheels to swing
\t# in an arc when steering (FBX mesh offset != wheel node origin).
\t# Steering animation only works for box-mesh fallback (pivots created
\t# in _build_box_mesh). FBX models: wheels don't turn visually when steering.
\t# Will be fixed properly in Sprint D.5 (Animations) with real rigging."""

assert old2 in c, "old2 (find_wheels) not found"
c = c.replace(old2, new2)

with open(PATH2, 'w') as f:
    f.write(c)
print("OK - Vehicle.gd: FBX pivot steering disabled")
