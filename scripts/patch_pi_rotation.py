#!/usr/bin/env python3
"""Add PI rotation to NPC and Player meshes (pragmatic fix for backwards walking)."""

# NPC.gd: rotate mesh by PI
PATH1 = "/home/z/my-project/godot/scripts/NPC.gd"
with open(PATH1) as f:
    c = f.read()
old1 = "\t\tinstance.scale = Vector3(1.0, 1.0, 1.0)\n\t\t# Rotate to face forward (FBX may have different default orientation)\n\t\t# Quaternius characters face -Z by default (Godot's forward direction).\n\t\t# Our NPC movement uses facing = atan2(dx, dz), where facing=0 means\n\t\t# moving toward -Z. So no rotation needed"
new1 = "\t\tinstance.scale = Vector3(1.0, 1.0, 1.0)\n\t\t# Pragmatic fix: rotate mesh by PI to face movement direction.\n\t\t# Despite Godot's -Z forward convention, the facing = atan2(-dx, -dz)\n\t\t# formula produces opposite orientation for this FBX. PI fixes it.\n\t\tinstance.rotation.y = PI"
assert old1 in c, "NPC old1 not found"
c = c.replace(old1, new1)
with open(PATH1, 'w') as f:
    f.write(c)
print(f"Patched {PATH1}")

# PlayerController.gd: rotate player mesh by PI too
PATH2 = "/home/z/my-project/godot/scripts/PlayerController.gd"
with open(PATH2) as f:
    c = f.read()
old2 = "\t\tinstance.scale = Vector3(1.0, 1.0, 1.0)\n\t\t# Quaternius characters face -Z by default (Godot's forward direction).\n\t\t# Player movement uses -Z forward (velocity.x/z = -sin/-cos of yaw),\n\t\t# so no rotation needed"
new2 = "\t\tinstance.scale = Vector3(1.0, 1.0, 1.0)\n\t\t# Pragmatic fix: rotate mesh by PI to face movement direction.\n\t\tinstance.rotation.y = PI"
assert old2 in c, "PlayerController old2 not found"
c = c.replace(old2, new2)
with open(PATH2, 'w') as f:
    f.write(c)
print(f"Patched {PATH2}")
