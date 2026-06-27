#!/usr/bin/env python3
"""Add ramp collision to sidewalk segments (Option A — sloped edges).

Instead of a vertical wall (BoxShape), add a ConvexPolygonShape3D ramp
on the street-facing edge of each sidewalk. The ramp goes from y=0
(street level) to y=SIDEWALK_HEIGHT (sidewalk top) over 30cm depth.
Cars can drive up this ramp onto the sidewalk.
"""

PATH = "/home/z/my-project/godot/scripts/WorldBuilder.gd"
with open(PATH) as f:
    c = f.read()

# Find _make_sidewalk_segment and add ramp collision after the sidewalk body
old = """\t# COLLISION: StaticBody3D so cars/player can drive/walk on sidewalk
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

new = """\t# COLLISION: StaticBody3D so cars/player can drive/walk on sidewalk
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
\t# RAMP COLLISION: Sloped edge on street-facing side of sidewalk
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

assert old in c, "old (sidewalk segment collision) not found"
c = c.replace(old, new)

with open(PATH, 'w') as f:
    f.write(c)
print("OK - Ramp collision added to sidewalk segments")
