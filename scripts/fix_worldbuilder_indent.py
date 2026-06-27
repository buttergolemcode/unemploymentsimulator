#!/usr/bin/env python3
"""Convert WorldBuilder.gd from 8-space indent to tab indent."""
import re

PATH = '/home/z/my-project/godot/scripts/WorldBuilder.gd'

with open(PATH, 'r') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    # Count leading spaces
    stripped = line.lstrip(' ')
    leading = line[:len(line) - len(stripped)]
    # Convert groups of 8 spaces to tabs
    if leading:
        n_spaces = len(leading)
        n_tabs = n_spaces // 8
        remainder = n_spaces % 8
        new_leading = '\t' * n_tabs + ' ' * remainder
        new_lines.append(new_leading + stripped)
    else:
        new_lines.append(line)

with open(PATH, 'w') as f:
    f.writelines(new_lines)

# Verify
with open(PATH, 'rb') as f:
    c = f.read()
lines = c.split(b'\n')
tabs = sum(1 for l in lines if l.startswith(b'\t'))
spaces = sum(1 for l in lines if l.startswith(b' '))
print(f'After conversion: tabs={tabs} spaces={spaces}')
