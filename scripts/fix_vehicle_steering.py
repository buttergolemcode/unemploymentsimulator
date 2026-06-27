#!/usr/bin/env python3
"""Fix duplicated if/else block in Vehicle.gd steering section."""

PATH = "/home/z/my-project/godot/scripts/Vehicle.gd"

with open(PATH, "r") as f:
    lines = f.readlines()

# Find the duplicated block and replace with correct one
out = []
i = 0
while i < len(lines):
    line = lines[i]
    # Detect the broken pattern
    if "if speed < 0:  # reverse: steering inverts (like real car)" in line:
        # Write correct block:
        out.append("\t\tif speed < 0:  # reverse: steering inverts (like real car)\n")
        out.append("\t\t\tyaw += turn\n")
        out.append("\t\telse:\n")
        out.append("\t\t\tyaw -= turn\n")
        # Skip the duplicated block (next ~6 lines)
        # Skip until we find the "rotation.y = yaw + PI" line
        i += 1
        while i < len(lines) and "rotation.y = yaw + PI" not in lines[i]:
            i += 1
        # Don't skip the rotation line itself - leave it for next iteration
        continue
    else:
        out.append(line)
        i += 1

with open(PATH, "w") as f:
    f.writelines(out)

print("Fixed Vehicle.gd steering block")
