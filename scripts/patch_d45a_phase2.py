#!/usr/bin/env python3
"""D.4.5a Phase 2: Update terrain, water, roads, buildings, harbor, landmarks
for 3000m Küstenstadt layout. All positions and sizes updated."""

PATH = "/home/z/my-project/godot/scripts/WorldBuilder.gd"
with open(PATH) as f:
    c = f.read()

# ============================================================
# 1. TERRAIN: bigger mesh, bigger collision, repositioned mountains
# ============================================================
old_terrain = """static func _build_terrain(parent: Node3D) -> void:
\tvar size = 1400  # larger terrain mesh for bigger map
\tvar segs = 120"""

new_terrain = """static func _build_terrain(parent: Node3D) -> void:
\tvar size = 3200  # 3000m playable + 100m margin each side
\tvar segs = 150"""

assert old_terrain in c, "old_terrain not found"
c = c.replace(old_terrain, new_terrain)

# City ground collision — 3000m
old_city_ground = "\tcity_shape.size = Vector3(1200, 1.0, 1200)  # 1200x1200 flat ground (covers city + inner rural)"
new_city_ground = "\tcity_shape.size = Vector3(3000, 1.0, 3000)  # 3000x3000 flat ground (covers entire playable area)"
assert old_city_ground in c, "old_city_ground not found"
c = c.replace(old_city_ground, new_city_ground)

# Rural collision grid — extend to cover new rural area
old_rural = """\tvar rural_grid = 50  # 50m spacing
\tfor gx in range(-600, 601, rural_grid):
\t\tfor gz in range(-600, 601, rural_grid):"""
new_rural = """\tvar rural_grid = 80  # 80m spacing (larger grid for bigger area)
\tfor gx in range(-1200, 1201, rural_grid):
\t\tfor gz in range(-1200, 1201, rural_grid):"""
assert old_rural in c, "old_rural not found"
c = c.replace(old_rural, new_rural)

# Mountain walls — repositioned for 3000m map
old_north = """\tnorth_shape.size = Vector3(1800, 100, 200)
\tnorth_col.shape = north_shape
\tnorth_col.position = Vector3(0, 50, -700)"""
new_north = """\tnorth_shape.size = Vector3(3600, CANYON_HEIGHT, 300)
\tnorth_col.shape = north_shape
\tnorth_col.position = Vector3(0, CANYON_HEIGHT / 2, -1350)"""
assert old_north in c, "old_north not found"
c = c.replace(old_north, new_north)

old_south = """\tsouth_shape.size = Vector3(1800, 100, 200)
\tsouth_col.shape = south_shape
\tsouth_col.position = Vector3(0, 50, 700)"""
new_south = """\tsouth_shape.size = Vector3(3600, CANYON_HEIGHT, 300)
\tsouth_col.shape = south_shape
\tsouth_col.position = Vector3(0, CANYON_HEIGHT / 2, 1350)"""
assert old_south in c, "old_south not found"
c = c.replace(old_south, new_south)

old_west = """\twest_shape.size = Vector3(200, 100, 1800)
\twest_col.shape = west_shape
\twest_col.position = Vector3(-700, 50, 0)"""
new_west = """\twest_shape.size = Vector3(300, CANYON_HEIGHT, 3600)
\twest_col.shape = west_shape
\twest_col.position = Vector3(-1350, CANYON_HEIGHT / 2, 0)"""
assert old_west in c, "old_west not found"
c = c.replace(old_west, new_west)

# East harbor barrier — at water edge
old_east = """\teast_shape.size = Vector3(20, 4, 1800)
\teast_col.shape = east_shape
\teast_col.position = Vector3(610, 2, 0)"""
new_east = """\teast_shape.size = Vector3(20, 4, 3600)
\teast_col.shape = east_shape
\teast_col.position = Vector3(1510, 2, 0)"""
assert old_east in c, "old_east not found"
c = c.replace(old_east, new_east)

# ============================================================
# 2. WATER: repositioned for east coast at x=1500
# ============================================================
old_water = """\tmi.position = Vector3(1200, -3.0, 0)  # east side, larger offset for bigger map"""
new_water = """\tmi.position = Vector3(3000, -3.0, 0)  # far east, ocean beyond coast"""
assert old_water in c, "old_water not found"
c = c.replace(old_water, new_water)

# ============================================================
# 3. ROADS: street length covers new downtown area
# ============================================================
old_road_len = "\tvar length = 1100.0  # spans entire city (extended for larger map)"
new_road_len = "\tvar length = 1200.0  # spans Downtown area (-100 to +1100 in Z)"
assert old_road_len in c, "old_road_len not found"
c = c.replace(old_road_len, new_road_len)

# ============================================================
# 4. FILLER BUILDINGS: block centers for new Downtown grid
# ============================================================
old_blocks = "\tvar block_centers = [-250, -150, -50, 50, 150, 250]"
new_blocks = "\tvar block_centers = [250, 350, 450, 550, 650, 750]  # Downtown: +100..+800"
assert old_blocks in c, "old_blocks not found"
c = c.replace(old_blocks, new_blocks)

# ============================================================
# 5. HARBOR: reposition basin, piers, ships, cranes to new coast
# ============================================================
old_basin = "\tbasin.position = Vector3(500, -2.0, 0)  # above water plane (y=-3.0) to avoid z-fight"
new_basin = "\tbasin.position = Vector3(1350, -2.0, 0)  # harbor basin at new coast (x=+1350)"
assert old_basin in c, "old_basin not found"
c = c.replace(old_basin, new_basin)

# Piers — repositioned
old_pier_pos = "\t\tp_mesh.size = Vector3(120, 1.0, 20)  # 120m long, 20m wide pier\n\t\tpier.position = Vector3(500, 0.5, pier_z)  # at water level"
new_pier_pos = "\t\tp_mesh.size = Vector3(120, 1.0, 20)\n\t\tpier.position = Vector3(1350, 0.5, pier_z)  # at new harbor basin"
assert old_pier_pos in c, "old_pier_pos not found"
c = c.replace(old_pier_pos, new_pier_pos)

old_pier_col = "\t\tpier_body.position = Vector3(500, 0.5, pier_z)"
new_pier_col = "\t\tpier_body.position = Vector3(1350, 0.5, pier_z)"
assert old_pier_col in c, "old_pier_col not found"
c = c.replace(old_pier_col, new_pier_col)

# Ships — repositioned
old_ship_pos = "\tship.position = Vector3(540, 4, ship_z + 15)  # next to pier, half in water"
new_ship_pos = "\tship.position = Vector3(1390, 4, ship_z + 15)  # next to pier at new harbor"
assert old_ship_pos in c, "old_ship_pos not found"
c = c.replace(old_ship_pos, new_ship_pos)

old_bridge_pos = "\tbridge.position = Vector3(540, 12, ship_z + 15)  # on top of ship"
new_bridge_pos = "\tbridge.position = Vector3(1390, 12, ship_z + 15)  # on top of ship"
assert old_bridge_pos in c, "old_bridge_pos not found"
c = c.replace(old_bridge_pos, new_bridge_pos)

# Container positions
old_container_x = "\t\tvar cx = 460 + (i / 3) % 5 * 12  # along pier length"
new_container_x = "\t\tvar cx = 1310 + (i / 3) % 5 * 12  # along new pier length"
assert old_container_x in c, "old_container_x not found"
c = c.replace(old_container_x, new_container_x)

old_container_y = "\t\tcontainer.position = Vector3(cx, 1.5 + stack_h, cz)"
new_container_y = "\t\tcontainer.position = Vector3(cx, 1.5 + stack_h, cz)  # on pier surface"
assert old_container_y in c, "old_container_y not found"
c = c.replace(old_container_y, new_container_y)

# Cranes
old_crane_x = "\t\tvar crane_x = 480 + (i / 3) * 30"
new_crane_x = "\t\tvar crane_x = 1330 + (i / 3) * 30  # on new piers"
assert old_crane_x in c, "old_crane_x not found"
c = c.replace(old_crane_x, new_crane_x)

old_crane_pos = "\tcrane.position = Vector3(crane_x, 1.0, crane_z)  # on pier"
new_crane_pos = "\tcrane.position = Vector3(crane_x, 1.0, crane_z)  # on new pier"
assert old_crane_pos in c, "old_crane_pos not found"
c = c.replace(old_crane_pos, new_crane_pos)

# ============================================================
# 6. LANDMARKS: reposition for new 3000m layout
# ============================================================
old_landmarks = """\t# Central Park (large green area in downtown)
\t_park(parent, -50, 100, 80, 50)
\t# Skyline row (3 tall towers)
\t_skyscraper(parent, 150, -100, 18, 110, "#1e293b")
\t_skyscraper(parent, 175, -100, 18, 140, "#0f172a")
\t_skyscraper(parent, 200, -100, 18, 120, "#1e293b")
\t# Bridge at harbor
\t_bridge(parent, 250, 0, 0)
\t# Fortress on west hill
\t_fortress(parent, -300, -300)
\t# Stadium
\t_stadium(parent, -250, 100)
\t# Bus station
\t_bus_station(parent, 100, 150)
\t# Gas stations
\t_gas_station(parent, -200, -200)
\t_gas_station(parent, 200, 200)"""

new_landmarks = """\t# Central Park (Downtown, between skyscrapers)
\t_park(parent, 400, 300, 100, 60)
\t# Skyline row (3 tall towers in Downtown East, near harbor)
\t_skyscraper(parent, 700, -100, 20, 110, "#1e293b")
\t_skyscraper(parent, 730, -100, 20, 140, "#0f172a")
\t_skyscraper(parent, 760, -100, 20, 120, "#1e293b")
\t# Bridge at harbor entrance
\t_bridge(parent, 1200, 0, 0)
\t# Fortress on west canyon rim (visible from far)
\t_fortress(parent, -1000, -800)
\t# Stadium in Industrial area
\t_stadium(parent, -300, 200)
\t# Bus station in Downtown
\t_bus_station(parent, 450, -250)
\t# Gas stations (Industrial + Harbor entrance)
\t_gas_station(parent, -300, -200)
\t_gas_station(parent, 700, 300)"""

assert old_landmarks in c, "old_landmarks not found"
c = c.replace(old_landmarks, new_landmarks)

# ============================================================
# 7. STREET LAMPS: reposition for new Downtown area
# ============================================================
old_lamps = """\tvar positions = [
\t\tVector3(-6, 0, -4), Vector3(6, 0, -4), Vector3(-6, 0, 6), Vector3(6, 0, 6),
\t\tVector3(-20, 0, -20), Vector3(20, 0, -20), Vector3(-20, 0, 20), Vector3(20, 0, 20),
\t\tVector3(-30, 0, -40), Vector3(-45, 0, -15), Vector3(30, 0, -40), Vector3(45, 0, -15),
\t\tVector3(-30, 0, 40), Vector3(-45, 0, 15), Vector3(30, 0, 40), Vector3(45, 0, 15),
\t]"""

new_lamps = """\tvar positions = [
\t\tVector3(250, 0, -50), Vector3(350, 0, -50), Vector3(450, 0, -50), Vector3(550, 0, -50),
\t\tVector3(250, 0, 50), Vector3(350, 0, 50), Vector3(450, 0, 50), Vector3(550, 0, 50),
\t\tVector3(650, 0, -50), Vector3(750, 0, -50), Vector3(650, 0, 50), Vector3(750, 0, 50),
\t\tVector3(300, 0, -200), Vector3(500, 0, -200), Vector3(300, 0, 200), Vector3(500, 0, 200),
\t]"""

assert old_lamps in c, "old_lamps not found"
c = c.replace(old_lamps, new_lamps)

# ============================================================
# 8. _is_on_road: update for new street grid
# ============================================================
old_is_on_road = """\t# Streets are at STREET_GRID positions (-300, -200, -100, 0, 100, 200, 300)
\t# with sidewalk buffer
\tvar road_buffer = ROAD_HALF_WIDTH + SIDEWALK_WIDTH
\tfor pos in STREET_GRID:
\t\tif abs(z - pos) < road_buffer and abs(x) < 400:
\t\t\treturn true
\t\tif abs(x - pos) < road_buffer and abs(z) < 400:
\t\t\treturn true
\treturn false"""

new_is_on_road = """\t# Streets are at STREET_GRID positions (Downtown: 200, 300, 400, 500, 600, 700)
\tvar road_buffer = ROAD_HALF_WIDTH + SIDEWALK_WIDTH
\tfor pos in STREET_GRID:
\t\tif abs(z - pos) < road_buffer and abs(x) > 50 and abs(x) < 850:
\t\t\treturn true
\t\tif abs(x - pos) < road_buffer and abs(z) > -600 and abs(z) < 600:
\t\t\treturn true
\treturn false"""

assert old_is_on_road in c, "old_is_on_road not found"
c = c.replace(old_is_on_road, new_is_on_road)

# ============================================================
# 9. NPC street positions: update for new grid
# ============================================================
old_npc_streets = """static var STREET_POSITIONS: Array = [-300, -200, -100, 0, 100, 200, 300]"""
new_npc_streets = """static var STREET_POSITIONS: Array = [200, 300, 400, 500, 600, 700]"""
assert old_npc_streets in c, "old_npc_streets not found"
c = c.replace(old_npc_streets, new_npc_streets)

# Update NPC _is_on_street bounds
old_npc_street_check = """\tif abs(z - pos) < ROAD_HALF and abs(x) < 380:
\t\t\treturn true
\t\tif abs(x - pos) < ROAD_HALF and abs(z) < 380:"""
new_npc_street_check = """\tif abs(z - pos) < ROAD_HALF and abs(x) > 50 and abs(x) < 850:
\t\t\treturn true
\t\tif abs(x - pos) < ROAD_HALF and abs(z) > -600 and abs(z) < 600:"""
assert old_npc_street_check in c, "old_npc_street_check not found"
c = c.replace(old_npc_street_check, new_npc_street_check)

with open(PATH, 'w') as f:
    f.write(c)
print("OK — Phase 2 complete: terrain, water, roads, buildings, harbor, landmarks, lamps all repositioned")
