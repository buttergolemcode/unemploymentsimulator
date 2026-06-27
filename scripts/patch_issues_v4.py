#!/usr/bin/env python3
"""Fix 4 issues:
1. NPCs only walk on sidewalks/crosswalks/buildings (not on streets)
2. Car scale relative to player (slightly larger to feel more substantial)
3. Real harbor (docks, ships, harbor basin) instead of floating boxes
4. Rural collision: cover entire rural area + larger rural zone
"""

# ============ NPC.gd: stay on sidewalks, avoid streets ============
PATH1 = "/home/z/my-project/godot/scripts/NPC.gd"
with open(PATH1) as f:
    c = f.read()

# Replace _physics_process and _pick_new_target with street-aware versions
old1 = """func _physics_process(delta):
\tif is_merchant:
\t\treturn

\t# Handle knockdown state
\tif is_down:
\t\tdown_timer -= delta
\t\t# Stay down, slowly recover
\t\tmesh.rotation.x = lerp(mesh.rotation.x, -PI / 2, delta * 5)
\t\tvelocity = Vector3.ZERO
\t\tmove_and_slide()
\t\tif down_timer <= 0:
\t\t\tis_down = false
\t\t\tmesh.rotation.x = 0
\t\t\t_pick_new_target()
\t\treturn

\t# Check for nearby vehicles (get run over)
\tfor vehicle in get_tree().get_nodes_in_group("vehicle"):
\t\tvar vd = global_position.distance_to(vehicle.global_position)
\t\tif vd < 2.5 and abs(vehicle.speed) > 3.0:
\t\t\t# Knocked down by vehicle
\t\t\tis_down = true
\t\t\tdown_timer = 4.0  # down for 4 seconds
\t\t\t# Knockback in vehicle's movement direction
\t\t\tvar kb_dir = (global_position - vehicle.global_position).normalized()
\t\t\tvelocity = kb_dir * 5.0
\t\t\tmove_and_slide()
\t\t\treturn

\tvar dx = target_pos.x - global_position.x
\tvar dz = target_pos.z - global_position.z
\tvar dist = sqrt(dx * dx + dz * dz)

\tif dist < 0.5:
\t\t_pick_new_target()
\telse:
\t\tvelocity = Vector3(dx / dist * speed, 0, dz / dist * speed)
\t\t# Godot Y-rotation convention: forward = (-sin(yaw), 0, -cos(yaw))
\t\t# We want forward to equal movement direction (dx, dz), so:
\t\t# -sin(yaw) = dx/dist, -cos(yaw) = dz/dist
\t\t# yaw = atan2(-dx, -dz)
\t\tfacing = atan2(-dx, -dz)
\t\trotation.y = facing
\t\twalk_phase += delta * 8
\t\t# Walk bob animation (procedural — will be replaced with real anim later)
\t\tmesh.position.y = abs(sin(walk_phase)) * 0.03  # subtle bob (was 0.06)
\t\t# Subtle forward lean when walking
\t\tmesh.rotation.x = lerp(mesh.rotation.x, 0.08, delta * 5.0)
\t\tmove_and_slide()

func _pick_new_target():
\tvar angle = randf() * TAU
\tvar dist = 15 + randf() * 25
\ttarget_pos = global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)"""

new1 = """func _physics_process(delta):
\tif is_merchant:
\t\treturn

\t# Handle knockdown state
\tif is_down:
\t\tdown_timer -= delta
\t\tmesh.rotation.x = lerp(mesh.rotation.x, -PI / 2, delta * 5)
\t\tvelocity = Vector3.ZERO
\t\tmove_and_slide()
\t\tif down_timer <= 0:
\t\t\tis_down = false
\t\t\tmesh.rotation.x = 0
\t\t\t_pick_new_target()
\t\treturn

\t# Check for nearby vehicles (get run over)
\tfor vehicle in get_tree().get_nodes_in_group("vehicle"):
\t\tvar vd = global_position.distance_to(vehicle.global_position)
\t\tif vd < 2.5 and abs(vehicle.speed) > 3.0:
\t\t\tis_down = true
\t\t\tdown_timer = 4.0
\t\t\tvar kb_dir = (global_position - vehicle.global_position).normalized()
\t\t\tvelocity = kb_dir * 5.0
\t\t\tmove_and_slide()
\t\t\treturn

\tvar dx = target_pos.x - global_position.x
\tvar dz = target_pos.z - global_position.z
\tvar dist = sqrt(dx * dx + dz * dz)

\tif dist < 0.5:
\t\t_pick_new_target()
\telse:
\t\t# Check if next position would be on a street — if so, pick new target
\t\tvar next_x = global_position.x + (dx / dist) * 2.0
\t\tvar next_z = global_position.z + (dz / dist) * 2.0
\t\tif _is_on_street(next_x, next_z):
\t\t\t_pick_new_target()
\t\t\treturn
\t\tvelocity = Vector3(dx / dist * speed, 0, dz / dist * speed)
\t\tfacing = atan2(-dx, -dz)
\t\trotation.y = facing
\t\twalk_phase += delta * 8
\t\tmesh.position.y = abs(sin(walk_phase)) * 0.03
\t\tmesh.rotation.x = lerp(mesh.rotation.x, 0.08, delta * 5.0)
\t\tmove_and_slide()

# Streets are at positions [-300, -200, -100, 0, 100, 200, 300] in both axes
# with ROAD_HALF_WIDTH (4m) buffer. NPCs should stay on sidewalks (outside this buffer).
static var STREET_POSITIONS: Array = [-300, -200, -100, 0, 100, 200, 300]
static var ROAD_HALF: float = 4.5  # 4m half-width + 0.5m buffer

static func _is_on_street(x: float, z: float) -> bool:
\t# Check if position is on a street (within road half-width of any street line)
\tfor pos in STREET_POSITIONS:
\t\t# East-West street at z=pos
\t\tif abs(z - pos) < ROAD_HALF and abs(x) < 380:
\t\t\treturn true
\t\t# North-South street at x=pos
\t\tif abs(x - pos) < ROAD_HALF and abs(z) < 380:
\t\t\treturn true
\treturn false

func _pick_new_target():
\t# Try to find a target that's NOT on a street (keep NPC on sidewalks/buildings)
\tfor attempt in range(10):
\t\tvar angle = randf() * TAU
\t\tvar dist = 8 + randf() * 20  # shorter range, stay near current block
\t\tvar candidate = global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
\t\t# Skip if candidate is on a street
\t\tif not _is_on_street(candidate.x, candidate.z):
\t\t\ttarget_pos = candidate
\t\t\treturn
\t# Fallback: just pick any nearby point (NPC may briefly cross street)
\tvar angle = randf() * TAU
\tvar dist = 8 + randf() * 15
\ttarget_pos = global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)"""

assert old1 in c, "old1 (NPC physics) not found"
c = c.replace(old1, new1)

with open(PATH1, 'w') as f:
    f.write(c)
print("OK - NPC.gd: stay on sidewalks")

# ============ Vehicle.gd: slightly larger car for better proportion ============
PATH2 = "/home/z/my-project/godot/scripts/Vehicle.gd"
with open(PATH2) as f:
    c = f.read()

# Adjust max_speed (slower for better feel at city scale) and car body
old2 = """var max_speed: float = 22.0"""
new2 = """var max_speed: float = 18.0  # 18 m/s = ~65 km/h (city speed)"""
assert old2 in c, "old2 (max_speed) not found"
c = c.replace(old2, new2)

# Adjust box-mesh car body to be slightly larger (more substantial next to player)
old3 = """\tbody_m.size = Vector3(1.9, 1.0, 4.2)  # realistic car: 1.9m wide, 1.0m body height, 4.2m long
\tbody.mesh = body_m
\tbody.position = Vector3(0, 0.65, 0)  # body sits at 0.65m (wheel top)"""
new3 = """\tbody_m.size = Vector3(2.0, 1.2, 4.5)  # 2m wide, 1.2m body, 4.5m long (slightly larger)
\tbody.mesh = body_m
\tbody.position = Vector3(0, 0.75, 0)  # body sits at 0.75m"""
assert old3 in c, "old3 (car body) not found"
c = c.replace(old3, new3)

# Cabin
old4 = """\tcabin_m.size = Vector3(1.6, 0.7, 1.8)  # cabin: 1.6m wide, 0.7m tall, 1.8m long
\tcabin.mesh = cabin_m
\tcabin.position = Vector3(0, 1.5, -0.2)  # sits on top of body"""
new4 = """\tcabin_m.size = Vector3(1.7, 0.8, 2.0)  # cabin: 1.7m wide, 0.8m tall, 2.0m long
\tcabin.mesh = cabin_m
\tcabin.position = Vector3(0, 1.7, -0.2)  # sits on top of body"""
assert old4 in c, "old4 (car cabin) not found"
c = c.replace(old4, new4)

# Windshield
old5 = """\twind_m.size = Vector3(1.5, 0.6, 0.1)
\twind.mesh = wind_m
\twind.position = Vector3(0, 1.5, 0.85)  # at cabin height"""
new5 = """\twind_m.size = Vector3(1.6, 0.7, 0.1)
\twind.mesh = wind_m
\twind.position = Vector3(0, 1.7, 0.95)  # at cabin height"""
assert old5 in c, "old5 (windshield) not found"
c = c.replace(old5, new5)

# Wheels — slightly larger
old6 = """\tfor pos in [Vector3(-0.9, 0.35, 1.4), Vector3(0.9, 0.35, 1.4), Vector3(-0.9, 0.35, -1.4), Vector3(0.9, 0.35, -1.4)]:
\t\tvar wheel = MeshInstance3D.new()
\t\tvar w_m = CylinderMesh.new()
\t\tw_m.top_radius = 0.35  # 35cm radius = 70cm diameter (realistic)
\t\tw_m.bottom_radius = 0.35
\t\tw_m.height = 0.25  # 25cm tire width"""
new6 = """\tfor pos in [Vector3(-0.95, 0.4, 1.5), Vector3(0.95, 0.4, 1.5), Vector3(-0.95, 0.4, -1.5), Vector3(0.95, 0.4, -1.5)]:
\t\tvar wheel = MeshInstance3D.new()
\t\tvar w_m = CylinderMesh.new()
\t\tw_m.top_radius = 0.4  # 40cm radius = 80cm diameter (realistic SUV)
\t\tw_m.bottom_radius = 0.4
\t\tw_m.height = 0.3  # 30cm tire width"""
assert old6 in c, "old6 (wheels) not found"
c = c.replace(old6, new6)

# Headlights
old7 = """\tfor x in [-0.7, 0.7]:
\t\tvar hl = OmniLight3D.new()
\t\thl.position = Vector3(x, 0.7, 2.1)  # at front of body"""
new7 = """\tfor x in [-0.75, 0.75]:
\t\tvar hl = OmniLight3D.new()
\t\thl.position = Vector3(x, 0.85, 2.25)  # at front of body"""
assert old7 in c, "old7 (headlights) not found"
c = c.replace(old7, new7)

# Taillights
old8 = """\tfor x in [-0.7, 0.7]:
\t\tvar tl = OmniLight3D.new()
\t\ttl.position = Vector3(x, 0.7, -2.1)  # at rear of body"""
new8 = """\tfor x in [-0.75, 0.75]:
\t\tvar tl = OmniLight3D.new()
\t\ttl.position = Vector3(x, 0.85, -2.25)  # at rear of body"""
assert old8 in c, "old8 (taillights) not found"
c = c.replace(old8, new8)

with open(PATH2, 'w') as f:
    f.write(c)
print("OK - Vehicle.gd: larger car body, slower max speed")

# ============ GameScene.gd: update vehicle collision to match ============
PATH3 = "/home/z/my-project/godot/scripts/GameScene.gd"
with open(PATH3) as f:
    c = f.read()

old9 = """\t\tshape.size = Vector3(1.9, 1.5, 4.2)  # matches new car body size
\t\tcol.shape = shape
\t\tcol.position = Vector3(0, 0.85, 0)  # center of 1.5m tall body"""
new9 = """\t\tshape.size = Vector3(2.0, 1.5, 4.5)  # matches new larger car body
\t\tcol.shape = shape
\t\tcol.position = Vector3(0, 0.9, 0)  # center of body"""
assert old9 in c, "old9 (vehicle collision) not found"
c = c.replace(old9, new9)

with open(PATH3, 'w') as f:
    f.write(c)
print("OK - GameScene.gd: vehicle collision updated")
