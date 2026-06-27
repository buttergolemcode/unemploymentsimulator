#!/usr/bin/env python3
"""Patch NPC.gd to insert new _physics_process body with vehicle knockdown logic."""

PATH = "/home/z/my-project/godot/scripts/NPC.gd"

NEW_BODY = '''func _physics_process(delta):
\tif is_merchant:
\t\treturn
\t
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
\t
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
\t
\tvar dx = target_pos.x - global_position.x
\tvar dz = target_pos.z - global_position.z
\tvar dist = sqrt(dx * dx + dz * dz)
\t
\tif dist < 0.5:
\t\t_pick_new_target()
\telse:
\t\tvelocity = Vector3(dx / dist * speed, 0, dz / dist * speed)
\t\tfacing = atan2(dx, dz)
\t\trotation.y = facing
\t\twalk_phase += delta * 8
\t\tmesh.position.y = abs(sin(walk_phase)) * 0.06
\t\tmove_and_slide()

func _pick_new_target():'''

with open(PATH, "r") as f:
    content = f.read()

old = "func _physics_process(delta):\nfunc _pick_new_target():"
content = content.replace(old, NEW_BODY)

with open(PATH, "w") as f:
    f.write(content)

print("Patched NPC.gd successfully")
