#!/usr/bin/env python3
"""Fix NPC facing formula + use pivot approach for vehicle wheels."""

# ============ NPC.gd: fix atan2 formula ============
PATH1 = "/home/z/my-project/godot/scripts/NPC.gd"
with open(PATH1) as f:
    c = f.read()
# Original formula was wrong: atan2(dx, dz) gives rotation that faces OPPOSITE
# of movement direction. Correct formula: atan2(-dx, -dz) so mesh faces movement.
old1 = "\t\tfacing = atan2(dx, dz)"
new1 = "\t\t# Godot Y-rotation convention: forward = (-sin(yaw), 0, -cos(yaw))\n\t\t# We want forward to equal movement direction (dx, dz), so:\n\t\t# -sin(yaw) = dx/dist, -cos(yaw) = dz/dist\n\t\t# yaw = atan2(-dx, -dz)\n\t\tfacing = atan2(-dx, -dz)"
assert old1 in c, "NPC old1 not found"
c = c.replace(old1, new1)
with open(PATH1, 'w') as f:
    f.write(c)
print(f"Patched {PATH1}")

# ============ Vehicle.gd: pivot-based wheel steering ============
PATH3 = "/home/z/my-project/godot/scripts/Vehicle.gd"
with open(PATH3) as f:
    c = f.read()

# 1. Update variable declarations
old4 = "var _front_wheels: Array = []\nvar _rear_wheels: Array = []"
new4 = """var _front_wheel_pivots: Array = []  # parent Node3Ds for steering Y-rotation
var _front_wheels_raw: Array = []  # raw wheel nodes before pivot wrapping
var _rear_wheels: Array = []"""
assert old4 in c, "Vehicle old4 not found"
c = c.replace(old4, new4)

# 2. Replace _find_wheels
old5 = """func _find_wheels(root):
\t# Quaternius cars typically name wheel nodes "Wheel_FL", "Wheel_FR", "Wheel_RL", "Wheel_RR"
\t# or similar. Walk the tree and collect any node whose name contains "wheel".
\t_wheel_nodes.clear()
\t_front_wheels.clear()
\t_rear_wheels.clear()
\t_collect_wheels(root)
\t# Fallback: if naming convention didn't match, assume first 2 wheels are front
\tif _front_wheels.is_empty() and _wheel_nodes.size() >= 4:
\t\t_front_wheels = [_wheel_nodes[0], _wheel_nodes[1]]
\t\t_rear_wheels = [_wheel_nodes[2], _wheel_nodes[3]]"""

new5 = """func _find_wheels(root):
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
assert old5 in c, "Vehicle old5 not found"
c = c.replace(old5, new5)

# 3. Update _collect_wheels to use _front_wheels_raw
old7 = """\t\tif "_f" in name_lower or "front" in name_lower:
\t\t\t_front_wheels.append(node)
\t\telif "_r" in name_lower or "rear" in name_lower or "_b" in name_lower:
\t\t\t_rear_wheels.append(node)"""
new7 = """\t\tif "front" in name_lower or "_fl" in name_lower or "_fr" in name_lower:
\t\t\t_front_wheels_raw.append(node)
\t\telif "back" in name_lower or "rear" in name_lower or "_rl" in name_lower or "_rr" in name_lower:
\t\t\t_rear_wheels.append(node)"""
assert old7 in c, "Vehicle old7 not found"
c = c.replace(old7, new7)

# 4. Update steering code in _animate_wheels_and_body
old3 = """\tvar target_steer_angle = current_steer * 0.5 * steer_visual_factor
\tfor wheel in _front_wheels:
\t\t# Only set Y rotation, preserve X and Z (which keep wheel upright)
\t\twheel.rotation.y = lerp(wheel.rotation.y, target_steer_angle, delta * 8.0)"""
new3 = """\tvar target_steer_angle = current_steer * 0.5 * steer_visual_factor
\tfor pivot in _front_wheel_pivots:
\t\tpivot.rotation.y = lerp(pivot.rotation.y, target_steer_angle, delta * 8.0)"""
assert old3 in c, "Vehicle old3 not found"
c = c.replace(old3, new3)

# 5. Update box-mesh fallback to also use pivots
old8 = """\t_front_wheels = [_wheel_nodes[0], _wheel_nodes[1]]
\t_rear_wheels = [_wheel_nodes[2], _wheel_nodes[3]]
\t_use_box_mesh = true  # enable wheel animation in _animate_wheels_and_body"""

new8 = """\t# Wrap first two wheels (front) in pivots for steering animation
\tfor i in [0, 1]:
\t\tvar wheel_node = _wheel_nodes[i]
\t\tvar pivot = Node3D.new()
\t\tpivot.name = "BoxSteerPivot_" + str(i)
\t\tvar parent_node = wheel_node.get_parent()
\t\tvar wp = wheel_node.position
\t\tvar wr = wheel_node.rotation
\t\tparent_node.remove_child(wheel_node)
\t\tpivot.position = wp
\t\tparent_node.add_child(pivot)
\t\twheel_node.position = Vector3.ZERO
\t\twheel_node.rotation = wr
\t\tpivot.add_child(wheel_node)
\t\t_front_wheel_pivots.append(pivot)
\t_rear_wheels = [_wheel_nodes[2], _wheel_nodes[3]]
\t_use_box_mesh = true  # enable wheel spin animation"""
assert old8 in c, "Vehicle old8 not found"
c = c.replace(old8, new8)

with open(PATH3, 'w') as f:
    f.write(c)
print(f"Patched {PATH3}")
