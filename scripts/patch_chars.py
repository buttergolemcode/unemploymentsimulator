#!/usr/bin/env python3
"""Patch PlayerController.gd and NPC.gd to remove unnecessary rotation.y = PI
for Quaternius character models."""

# PlayerController.gd
PATH1 = "/home/z/my-project/godot/scripts/PlayerController.gd"
with open(PATH1) as f:
    c = f.read()
old1 = "                instance.rotation.y = PI  # face -Z (forward)"
new1 = "                # Quaternius characters face -Z by default, no rotation needed\n                # instance.rotation.y = PI  # uncomment if model faces wrong way"
assert old1 in c, f"old1 not found in {PATH1}"
c = c.replace(old1, new1)
with open(PATH1, 'w') as f:
    f.write(c)
print(f"Patched {PATH1}")

# NPC.gd: also reduce walk bob amplitude (was 0.06, too bouncy)
PATH2 = "/home/z/my-project/godot/scripts/NPC.gd"
with open(PATH2) as f:
    c = f.read()
old2 = "\t\tmesh.position.y = abs(sin(walk_phase)) * 0.06"
new2 = "\t\tmesh.position.y = abs(sin(walk_phase)) * 0.03  # subtle bob (was 0.06)"
assert old2 in c, f"old2 not found in {PATH2}"
c = c.replace(old2, new2)
with open(PATH2, 'w') as f:
    f.write(c)
print(f"Patched {PATH2}")
