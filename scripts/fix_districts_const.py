#!/usr/bin/env python3
"""Convert DISTRICTS const to static var with _init build (avoids Godot 4.7
'not a constant expression' error for PackedVector2Array in const dict)."""

PATH = "/home/z/my-project/godot/scripts/WorldBuilder.gd"

with open(PATH) as f:
    c = f.read()

# Replace the const DISTRICTS block with a static var + _init function
old = '''const DISTRICTS: Dictionary = {
\t"downtown": {
\t\t"color": "#475569", "height_min": 24, "height_max": 80, "ground": "#1a1a1a",
\t\t"polygon": PackedVector2Array([
\t\t\tVector2(-80, -80), Vector2(80, -80), Vector2(80, 80), Vector2(-80, 80)
\t\t])
\t},
\t"harbor": {
\t\t"color": "#1c1917", "height_min": 8, "height_max": 22, "ground": "#171717",
\t\t"polygon": PackedVector2Array([
\t\t\tVector2(80, -100), Vector2(260, -100), Vector2(260, 180),
\t\t\tVector2(180, 180), Vector2(180, -60), Vector2(80, -60), Vector2(80, 80), Vector2(120, 80)
\t\t])
\t},
\t"slums": {
\t\t"color": "#451a03", "height_min": 5, "height_max": 14, "ground": "#1a0f0a",
\t\t"polygon": PackedVector2Array([
\t\t\tVector2(-180, 40), Vector2(-80, 40), Vector2(-80, 180), Vector2(-180, 180)
\t\t])
\t},
\t"industrial": {
\t\t"color": "#1f2937", "height_min": 9, "height_max": 24, "ground": "#161616",
\t\t"polygon": PackedVector2Array([
\t\t\tVector2(-180, -120), Vector2(-80, -120), Vector2(-80, 40), Vector2(-180, 40)
\t\t])
\t},
\t"suburbs": {
\t\t"color": "#525252", "height_min": 4, "height_max": 9, "ground": "#1a2a1a",
\t\t"polygon": PackedVector2Array([
\t\t\t# West suburbs
\t\t\tVector2(-180, -120), Vector2(-80, -120), Vector2(-80, 40), Vector2(-180, 40),
\t\t\t# East suburbs (between downtown and harbor)
\t\t\tVector2(80, -80), Vector2(120, -80), Vector2(120, 80), Vector2(80, 80)
\t\t])
\t},
\t"rural": {
\t\t"color": "#6b5b4a", "height_min": 3, "height_max": 6, "ground": "#2a3a1a",
\t\t# Rural is everything outside the city (handled by distance check in get_district_at)
\t\t"polygon": PackedVector2Array([])
\t},
}'''

new = '''# District definitions (built at runtime via _init_districts() because
# PackedVector2Array constructor can't be used in const expression)
static var DISTRICTS: Dictionary = {}

static func _init_districts() -> void:
\tif not DISTRICTS.is_empty():
\t\treturn  # already initialized
\tDISTRICTS = {
\t\t"downtown": {
\t\t\t"color": "#475569", "height_min": 24, "height_max": 80, "ground": "#1a1a1a",
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(-80, -80), Vector2(80, -80), Vector2(80, 80), Vector2(-80, 80)
\t\t\t])
\t\t},
\t\t"harbor": {
\t\t\t"color": "#1c1917", "height_min": 8, "height_max": 22, "ground": "#171717",
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(80, -100), Vector2(260, -100), Vector2(260, 180),
\t\t\t\tVector2(180, 180), Vector2(180, -60), Vector2(80, -60), Vector2(80, 80), Vector2(120, 80)
\t\t\t])
\t\t},
\t\t"slums": {
\t\t\t"color": "#451a03", "height_min": 5, "height_max": 14, "ground": "#1a0f0a",
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(-180, 40), Vector2(-80, 40), Vector2(-80, 180), Vector2(-180, 180)
\t\t\t])
\t\t},
\t\t"industrial": {
\t\t\t"color": "#1f2937", "height_min": 9, "height_max": 24, "ground": "#161616",
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(-180, -120), Vector2(-80, -120), Vector2(-80, 40), Vector2(-180, 40)
\t\t\t])
\t\t},
\t\t"suburbs": {
\t\t\t"color": "#525252", "height_min": 4, "height_max": 9, "ground": "#1a2a1a",
\t\t\t"polygon": PackedVector2Array([
\t\t\t\tVector2(-180, -120), Vector2(-80, -120), Vector2(-80, 40), Vector2(-180, 40),
\t\t\t\tVector2(80, -80), Vector2(120, -80), Vector2(120, 80), Vector2(80, 80)
\t\t\t])
\t\t},
\t\t"rural": {
\t\t\t"color": "#6b5b4a", "height_min": 3, "height_max": 6, "ground": "#2a3a1a",
\t\t\t"polygon": PackedVector2Array([])
\t\t},
\t}'''

assert old in c, "old block not found"
c = c.replace(old, new)

# Also update get_district_at to call _init_districts() first
old2 = '''static func get_district_at(x: float, z: float) -> String:
\tvar point = Vector2(x, z)'''
new2 = '''static func get_district_at(x: float, z: float) -> String:
\t_init_districts()  # ensure DISTRICTS is populated
\tvar point = Vector2(x, z)'''
assert old2 in c, "old2 not found"
c = c.replace(old2, new2)

with open(PATH, 'w') as f:
    f.write(c)
print("OK")
