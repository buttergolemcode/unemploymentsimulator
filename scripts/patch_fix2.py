#!/usr/bin/env python3
"""Patch NPC.gd, PlayerController.gd, Vehicle.gd"""

# ============ NPC.gd: re-enable rotation.y = PI for character model ============
PATH1 = "/home/z/my-project/godot/scripts/NPC.gd"
with open(PATH1) as f:
    c = f.read()
old1 = """\t\t# Note: Quaternius characters face -Z by default (forward in Godot),
\t\t# so no rotation needed. If a model faces +Z, add PI here.
\t\t# instance.rotation.y = PI  # uncomment if model faces wrong way"""
new1 = """\t\t# Quaternius characters face -Z by default (forward in Godot).
\t\t# Our NPC movement uses facing = atan2(dx, dz) which assumes +Z forward.
\t\t# So we rotate the model by PI to align mesh with movement direction.
\t\tinstance.rotation.y = PI"""
assert old1 in c, "NPC old1 not found"
c = c.replace(old1, new1)
with open(PATH1, 'w') as f:
    f.write(c)
print(f"Patched {PATH1}")

# ============ PlayerController.gd: same fix ============
PATH2 = "/home/z/my-project/godot/scripts/PlayerController.gd"
with open(PATH2) as f:
    c = f.read()
old2 = """                # Quaternius characters face -Z by default, no rotation needed
                # instance.rotation.y = PI  # uncomment if model faces wrong way"""
new2 = """                # Quaternius characters face -Z by default (forward in Godot).
                # Rotate by PI to align mesh with player's movement direction
                # (player movement uses -Z forward convention).
                instance.rotation.y = PI"""
assert old2 in c, "PlayerController old2 not found"
c = c.replace(old2, new2)
with open(PATH2, 'w') as f:
    f.write(c)
print(f"Patched {PATH2}")

# ============ Vehicle.gd: re-enable front-wheel steering (Y only, no spin) ============
PATH3 = "/home/z/my-project/godot/scripts/Vehicle.gd"
with open(PATH3) as f:
    c = f.read()

old3 = """\tif _use_box_mesh:
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

new3 = """\t# Front-wheel steering: turn front wheels left/right based on steer input.
\t# This works for BOTH box-mesh fallback AND real FBX models because
\t# wheel.rotation.y = X only overwrites the Y component, preserving the
\t# wheel's baked X/Z orientation (e.g. cylinder rotated for visual alignment).
\tvar steer_visual_factor: float
\tif abs_speed < 1.0:
\t\tsteer_visual_factor = 1.0
\telif abs_speed < 5.0:
\t\tsteer_visual_factor = 1.0
\telse:
\t\tsteer_visual_factor = clamp(1.0 - (abs_speed - 5.0) / 17.0, 0.3, 1.0)
\tvar target_steer_angle = current_steer * 0.5 * steer_visual_factor
\tfor wheel in _front_wheels:
\t\t# Only set Y rotation, preserve X and Z (which keep wheel upright)
\t\twheel.rotation.y = lerp(wheel.rotation.y, target_steer_angle, delta * 8.0)
\t
\t# Wheel spin (X-axis rotation): ONLY for box-mesh fallback.
\t# For real FBX models, rotate_x() would accumulate on top of baked
\t# orientation and cause wheels to clip into the body.
\tif _use_box_mesh:
\t\tvar spin_rate = speed * 3.0
\t\tfor wheel in _wheel_nodes:
\t\t\twheel.rotate_x(spin_rate * delta)"""

assert old3 in c, "Vehicle old3 not found"
c = c.replace(old3, new3)
with open(PATH3, 'w') as f:
    f.write(c)
print(f"Patched {PATH3}")
