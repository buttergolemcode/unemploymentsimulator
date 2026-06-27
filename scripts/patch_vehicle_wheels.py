#!/usr/bin/env python3
"""Patch Vehicle.gd: add _use_box_mesh flag and skip wheel anim for FBX models."""

PATH = "/home/z/my-project/godot/scripts/Vehicle.gd"

with open(PATH) as f:
    c = f.read()

# 1. Add _use_box_mesh flag declaration
old1 = "# Last steering input for body-roll animation\nvar _last_steer: float = 0.0"
new1 = """# Last steering input for body-roll animation
var _last_steer: float = 0.0
# True when using box-mesh fallback (FBX wheel animation is unreliable
# because the wheel nodes have baked orientations that conflict with our
# rotate_x / rotation.y assignments)
var _use_box_mesh: bool = false"""
assert old1 in c, "old1 not found"
c = c.replace(old1, new1)

# 2. Set _use_box_mesh=true at end of _build_box_mesh
old2 = "\t_front_wheels = [_wheel_nodes[0], _wheel_nodes[1]]\n\t_rear_wheels = [_wheel_nodes[2], _wheel_nodes[3]]\n\n\t_add_lights()"
new2 = "\t_front_wheels = [_wheel_nodes[0], _wheel_nodes[1]]\n\t_rear_wheels = [_wheel_nodes[2], _wheel_nodes[3]]\n\t_use_box_mesh = true  # enable wheel animation in _animate_wheels_and_body\n\n\t_add_lights()"
assert old2 in c, "old2 not found"
c = c.replace(old2, new2)

# 3. In _animate_wheels_and_body, skip wheel spin/steer for FBX models
old3 = """func _animate_wheels_and_body(delta: float, current_steer: float):
\tvar abs_speed = abs(speed)  # used by both front-wheel + body-roll sections
\t# Wheel spin: rotate around local X axis based on speed
\t# (wheels are typically rotated so their spin axis is X in local space)
\tvar spin_rate = speed * 3.0  # rad/s, tuned for visual feel
\tfor wheel in _wheel_nodes:
\t\t# Wheel local rotation: rotate around X
\t\t# Use rotate_x for accumulated rotation (don't set rotation.x directly
\t\t# because the wheel may have a base rotation for orientation)
\t\twheel.rotate_x(spin_rate * delta)
\t
\t# Front wheel steering: turn front wheels left/right based on steer input.
\t# Realistic max steering angle ~30 degrees at full lock (low speed),
\t# reduced at high speed for stability (matches steering authority bell curve).
\tvar steer_visual_factor: float
\tif abs_speed < 1.0:
\t\tsteer_visual_factor = 1.0  # full lock allowed at standstill for visual
\telif abs_speed < 5.0:
\t\tsteer_visual_factor = 1.0  # still full lock at low speed
\telse:
\t\t# Reduce visible steering angle at higher speeds
\t\tsteer_visual_factor = clamp(1.0 - (abs_speed - 5.0) / 17.0, 0.3, 1.0)
\t# Target Y rotation: steer (left=-1, right=+1) * max_angle (in radians)
\t# 0.5 rad = ~28 degrees, matches real car full lock
\tvar target_steer_angle = current_steer * 0.5 * steer_visual_factor
\tfor wheel in _front_wheels:
\t\t# Smoothly interpolate to target steering angle (lerp for natural feel)
\t\twheel.rotation.y = lerp(wheel.rotation.y, target_steer_angle, delta * 8.0)"""

new3 = """func _animate_wheels_and_body(delta: float, current_steer: float):
\tvar abs_speed = abs(speed)  # used by both front-wheel + body-roll sections
\t# Wheel spin + steering: ONLY animate for box-mesh fallback.
\t# For real FBX car models, the wheel nodes have baked orientations
\t# (e.g. cylinders rotated for visual alignment). Adding rotate_x or
\t# setting rotation.y breaks the orientation and the wheels glitch
\t# into the car body. We skip animation until proper pivot-node setup
\t# is implemented.
\tif _use_box_mesh:
\t\t# Wheel spin: rotate around local X axis based on speed
\t\tvar spin_rate = speed * 3.0  # rad/s, tuned for visual feel
\t\tfor wheel in _wheel_nodes:
\t\t\twheel.rotate_x(spin_rate * delta)
\t\t
\t\t# Front wheel steering: turn front wheels left/right based on steer input.
\t\t# Realistic max steering angle ~30 degrees at full lock (low speed),
\t\t# reduced at high speed for stability.
\t\tvar steer_visual_factor: float
\t\tif abs_speed < 1.0:
\t\t\tsteer_visual_factor = 1.0
\t\telif abs_speed < 5.0:
\t\t\tsteer_visual_factor = 1.0
\t\telse:
\t\t\tsteer_visual_factor = clamp(1.0 - (abs_speed - 5.0) / 17.0, 0.3, 1.0)
\t\tvar target_steer_angle = current_steer * 0.5 * steer_visual_factor
\t\tfor wheel in _front_wheels:
\t\t\twheel.rotation.y = lerp(wheel.rotation.y, target_steer_angle, delta * 8.0)"""

assert old3 in c, "old3 not found"
c = c.replace(old3, new3)

with open(PATH, 'w') as f:
    f.write(c)

print("Patched Vehicle.gd successfully")
