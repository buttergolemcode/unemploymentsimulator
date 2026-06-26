#!/usr/bin/env python3
"""Simplest reliable fix: make sidewalk collision FLAT (5cm) instead of 15cm.

The visual sidewalk stays at 15cm height (looks like a real curb).
But the COLLISION is only 5cm tall — small enough that floor_snap (0.5m)
can reliably pull the car up onto it without needing ramps.

This is the simplest approach because:
- No ramps needed (which had positioning issues)
- No complex rotation math
- floor_snap handles small steps reliably (5cm << 50cm snap length)
- Visually still looks like a proper raised sidewalk (15cm)
"""

PATH = "/home/z/my-project/godot/scripts/WorldBuilder.gd"
with open(PATH) as f:
    c = f.read()

# Remove the ramp collision entirely + lower sidewalk collision to 5cm
old1 = """\t# COLLISION: StaticBody3D so cars/player can drive/walk on sidewalk
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
\tparent.add_child(body)
\t
\t# RAMP COLLISION: Sloped box from street edge to sidewalk top
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

new1 = """\t# COLLISION: StaticBody3D with LOW collision height (5cm)
\t# Visual sidewalk is 15cm tall, but collision is only 5cm — small enough
\t# for floor_snap (0.5m) to reliably pull cars/players up onto it.
\t# This avoids the need for ramps or slope collision shapes.
\tvar collision_height = 0.05  # 5cm collision (visual stays 15cm)
\tvar body = StaticBody3D.new()
\tbody.position = Vector3(sx, collision_height / 2, sz)
\tvar col = CollisionShape3D.new()
\tvar shape = BoxShape3D.new()
\tif axis == "x":
\t\tshape.size = Vector3(seg_len, collision_height, SIDEWALK_WIDTH)
\telse:
\t\tshape.size = Vector3(SIDEWALK_WIDTH, collision_height, seg_len)
\tcol.shape = shape
\tbody.add_child(col)
\tparent.add_child(body)"""

assert old1 in c, "old1 (sidewalk + ramp) not found"
c = c.replace(old1, new1)

# Also lower the sidewalk corner collision to 5cm
old2 = """\t# COLLISION: StaticBody3D so cars/player can stand on corner
\tvar body = StaticBody3D.new()
\tbody.position = Vector3(x, SIDEWALK_HEIGHT / 2, z)
\tvar col = CollisionShape3D.new()
\tvar shape = BoxShape3D.new()
\tshape.size = Vector3(SIDEWALK_WIDTH, SIDEWALK_HEIGHT, SIDEWALK_WIDTH)
\tcol.shape = shape
\tbody.add_child(col)
\tparent.add_child(body)"""

new2 = """\t# COLLISION: StaticBody3D with LOW collision height (5cm, matches segments)
\tvar collision_height = 0.05
\tvar body = StaticBody3D.new()
\tbody.position = Vector3(x, collision_height / 2, z)
\tvar col = CollisionShape3D.new()
\tvar shape = BoxShape3D.new()
\tshape.size = Vector3(SIDEWALK_WIDTH, collision_height, SIDEWALK_WIDTH)
\tcol.shape = shape
\tbody.add_child(col)
\tparent.add_child(body)"""

assert old2 in c, "old2 (corner collision) not found"
c = c.replace(old2, new2)

with open(PATH, 'w') as f:
    f.write(c)
print("OK - Sidewalk collision lowered to 5cm (visual stays 15cm)")
