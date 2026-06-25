# WorldBuilder.gd — Builds the entire world: districts, roads, buildings, borders, terrain
# Called by GameScene on ready
class_name WorldBuilder
extends RefCounted

# District definitions
const DISTRICTS: Dictionary = {
        "downtown": {"color": "#475569", "height_min": 24, "height_max": 80, "ground": "#1a1a1a"},
        "harbor": {"color": "#1c1917", "height_min": 8, "height_max": 22, "ground": "#171717"},
        "slums": {"color": "#451a03", "height_min": 5, "height_max": 14, "ground": "#1a0f0a"},
        "industrial": {"color": "#1f2937", "height_min": 9, "height_max": 24, "ground": "#161616"},
        "suburbs": {"color": "#525252", "height_min": 4, "height_max": 9, "ground": "#1a2a1a"},
        "rural": {"color": "#6b5b4a", "height_min": 3, "height_max": 6, "ground": "#2a3a1a"},
}

const CITY_RADIUS = 80.0
const WORLD_RADIUS = 250.0
const ROAD_HALF_MAIN = 8.0
const ROAD_HALF_SIDE = 5.5
const SIDEWALK = 3.0

# Scheme building positions
const SCHEME_BUILDINGS: Array = [
        {"id": "trading", "name": "Trading Floor", "emoji": "📈", "x": -18, "z": -55, "w": 14, "d": 12, "h": 42, "color": "#22d3ee"},
        {"id": "wirefraud", "name": "Corporate Tower", "emoji": "💸", "x": -50, "z": -30, "w": 18, "d": 16, "h": 80, "color": "#64748b"},
        {"id": "taxfraud", "name": "Accountant Office", "emoji": "🧾", "x": -30, "z": -18, "w": 12, "d": 10, "h": 24, "color": "#eab308"},
        {"id": "drugs", "name": "Trap House", "emoji": "💊", "x": 38, "z": -50, "w": 10, "d": 9, "h": 9, "color": "#a855f7"},
        {"id": "scam", "name": "Internet Cafe", "emoji": "🎣", "x": -38, "z": 30, "w": 9, "d": 8, "h": 7, "color": "#ec4899"},
        {"id": "robbery", "name": "Corner Store", "emoji": "🔫", "x": -22, "z": 50, "w": 8, "d": 8, "h": 5, "color": "#ef4444"},
        {"id": "ecom", "name": "E-Com Warehouse", "emoji": "📦", "x": 30, "z": 38, "w": 16, "d": 14, "h": 11, "color": "#4ade80"},
        {"id": "gambling", "name": "Casino", "emoji": "🎰", "x": 55, "z": 22, "w": 16, "d": 14, "h": 14, "color": "#f59e0b"},
]

static func get_district_at(x: float, z: float) -> String:
        var r = sqrt(x * x + z * z)
        if r > 220:
                return "rural"
        if r > CITY_RADIUS:
                return "suburbs"
        if x < 0 and z < 0:
                return "downtown"
        if x >= 0 and z < 0:
                return "harbor"
        if x < 0 and z >= 0:
                return "slums"
        return "industrial"

# Terrain height function (matching web version)
static func terrain_height(x: float, z: float) -> float:
        var r = sqrt(x * x + z * z)
        if r < 80:
                return 0.0
        var blend = clamp((r - 80) / 20, 0, 1)
        var h = 0.0
        if r < 150:
                h = _fractal_noise(x, z, 1) * 4
        elif r < 220:
                h = 5 + _fractal_noise(x, z, 2) * 15
        else:
                if z < -120:
                        var mf = max(0, (r - 220) / 30)
                        h = 25 + _fractal_noise(x, z, 3) * 30 * min(1, mf)
                elif z > 120:
                        h = -2 - max(0, (r - 220) / 20) * 8
                else:
                        h = 10 + _fractal_noise(x, z, 2) * 15
        return h * blend

static func _hash2(x: float, z: float) -> float:
        var h = sin(x * 127.1 + z * 311.7) * 43758.5453
        return h - floor(h)

static func _smooth_noise(x: float, z: float) -> float:
        var ix = floor(x)
        var iz = floor(z)
        var fx = x - ix
        var fz = z - iz
        var sx = fx * fx * (3 - 2 * fx)
        var sz = fz * fz * (3 - 2 * fz)
        var n00 = _hash2(ix, iz)
        var n10 = _hash2(ix + 1, iz)
        var n01 = _hash2(ix, iz + 1)
        var n11 = _hash2(ix + 1, iz + 1)
        return n00 * (1 - sx) * (1 - sz) + n10 * sx * (1 - sz) + n01 * (1 - sx) * sz + n11 * sx * sz

static func _fractal_noise(x: float, z: float, octaves: int) -> float:
        var value = 0.0
        var amp = 1.0
        var freq = 1.0
        var max_val = 0.0
        for i in octaves:
                value += _smooth_noise(x * freq * 0.01, z * freq * 0.01) * amp
                max_val += amp
                amp *= 0.5
                freq *= 2
        return value / max_val

# ============================================================
# Build everything
# ============================================================
static func build_world(parent: Node3D) -> void:
        _build_terrain(parent)
        _build_water(parent)
        _build_roads(parent)
        _build_scheme_buildings(parent)
        _build_filler_buildings(parent)
        _build_map_borders(parent)
        _build_street_lamps(parent)

static func _build_terrain(parent: Node3D) -> void:
        var size = 600
        var segs = 150
        var mesh = PlaneMesh.new()
        mesh.size = Vector2(size, size)
        mesh.subdivide_width = segs
        mesh.subdivide_depth = segs
        
        var _arr_mesh = ArrayMesh.new()
        var surf = SurfaceTool.new()
        surf.create_from(mesh, 0)
        
        # Displace vertices by terrain_height
        var mdt = MeshDataTool.new()
        mdt.create_from_surface(surf.commit(), 0)
        
        for i in mdt.get_vertex_count():
                var v = mdt.get_vertex(i)
                var h = terrain_height(v.x, v.z)
                v.y = h
                mdt.set_vertex(i, v)
                
                # Vertex color based on height
                var r = sqrt(v.x * v.x + v.z * v.z)
                var col: Color
                if r < 80:
                        col = Color(0.1, 0.1, 0.12)
                elif h < 0:
                        col = Color(0.54, 0.48, 0.35)
                elif h < 1:
                        col = Color(0.35, 0.45, 0.2)
                elif h < 8:
                        col = Color(0.22, 0.36, 0.16)
                elif h < 20:
                        col = Color(0.29, 0.24, 0.16)
                else:
                        col = Color(0.42, 0.36, 0.29)
                mdt.set_vertex_color(i, col)
        
        var final_mesh = ArrayMesh.new()
        mdt.commit_to_surface(final_mesh)
        
        var mi = MeshInstance3D.new()
        mi.mesh = final_mesh
        mi.rotation.x = -PI / 2  # PlaneMesh is XY, rotate to XZ
        mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        
        # Material that uses vertex colors
        var mat = StandardMaterial3D.new()
        mat.vertex_color_use_as_albedo = true
        mat.roughness = 0.95
        mi.material_override = mat
        
        # Add collision (simple flat plane, good enough for walking)
        var body = StaticBody3D.new()
        var col = CollisionShape3D.new()
        var shape = WorldBoundaryShape3D.new()
        col.shape = shape
        body.add_child(col)
        parent.add_child(body)
        
        parent.add_child(mi)

static func _build_water(parent: Node3D) -> void:
        var plane = PlaneMesh.new()
        plane.size = Vector2(600, 600)
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color(0.1, 0.29, 0.42, 0.75)
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.roughness = 0.2
        mat.metalness = 0.3
        plane.material = mat
        var mi = MeshInstance3D.new()
        mi.mesh = plane
        mi.position = Vector3(0, -0.8, 0)
        parent.add_child(mi)

static func _build_roads(parent: Node3D) -> void:
        # Main axes
        for axis in ["x", "z"]:
                for pos in [0, 78, -78]:
                        if pos == 0 and axis == "x":
                                pass  # Main road
                        _make_road(parent, axis, pos, ROAD_HALF_MAIN, SIDEWALK, true)
        
        # Internal city streets every 20m
        for p in range(-60, 61, 20):
                if p == 0:
                        continue
                _make_road(parent, "x", p, ROAD_HALF_SIDE, SIDEWALK, false)
                _make_road(parent, "z", p, ROAD_HALF_SIDE, SIDEWALK, false)
        
        # Suburb roads
        for p in range(-140, 141, 30):
                if abs(p) <= 78:
                        continue
                _make_road(parent, "x", p, ROAD_HALF_SIDE, 2.0, false)
                _make_road(parent, "z", p, ROAD_HALF_SIDE, 2.0, false)
        
        # Rural roads
        for p in range(-200, 201, 50):
                if abs(p) <= 140:
                        continue
                _make_road(parent, "x", p, 4.0, 0, false)
                _make_road(parent, "z", p, 4.0, 0, false)

static func _make_road(parent: Node3D, axis: String, pos: float, half_w: float, sw: float, _is_main: bool):
        var length = 320.0
        # Asphalt
        var asphalt = MeshInstance3D.new()
        var a_mesh = BoxMesh.new()
        if axis == "x":
                a_mesh.size = Vector3(length, 0.02, half_w * 2)
                asphalt.position = Vector3(0, 0.02, pos)
        else:
                a_mesh.size = Vector3(half_w * 2, 0.02, length)
                asphalt.position = Vector3(pos, 0.02, 0)
        asphalt.mesh = a_mesh
        var amat = StandardMaterial3D.new()
        amat.albedo_color = Color(0.09, 0.09, 0.09)
        amat.roughness = 0.95
        asphalt.material_override = amat
        parent.add_child(asphalt)
        
        # Sidewalks
        if sw > 0:
                for side in [-1, 1]:
                        var sidewalk = MeshInstance3D.new()
                        var s_mesh = BoxMesh.new()
                        if axis == "x":
                                s_mesh.size = Vector3(length, 0.06, sw)
                                sidewalk.position = Vector3(0, 0.03, pos + side * (half_w + sw / 2))
                        else:
                                s_mesh.size = Vector3(sw, 0.06, length)
                                sidewalk.position = Vector3(pos + side * (half_w + sw / 2), 0.03, 0)
                        sidewalk.mesh = s_mesh
                        var smat = StandardMaterial3D.new()
                        smat.albedo_color = Color(0.23, 0.23, 0.23)
                        smat.roughness = 0.9
                        sidewalk.material_override = smat
                        parent.add_child(sidewalk)
        
        # Center line markings
        var dash_spacing = 3.0
        var count = int(length / dash_spacing)
        for i in count:
                var t = (i - (count - 1) / 2.0) * dash_spacing
                var dash = MeshInstance3D.new()
                var d_mesh = BoxMesh.new()
                if axis == "x":
                        d_mesh.size = Vector3(1.5, 0.01, 0.15)
                        dash.position = Vector3(t, 0.04, pos)
                else:
                        d_mesh.size = Vector3(0.15, 0.01, 1.5)
                        dash.position = Vector3(pos, 0.04, t)
                dash.mesh = d_mesh
                var dmat = StandardMaterial3D.new()
                dmat.albedo_color = Color(0.9, 0.9, 0.9)
                dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
                dash.material_override = dmat
                parent.add_child(dash)

static func _build_scheme_buildings(parent: Node3D) -> void:
        for b in SCHEME_BUILDINGS:
                var mesh = MeshInstance3D.new()
                var b_mesh = BoxMesh.new()
                b_mesh.size = Vector3(b.w, b.h, b.d)
                mesh.mesh = b_mesh
                mesh.position = Vector3(b.x, b.h / 2.0, b.z)
                var mat = StandardMaterial3D.new()
                mat.albedo_color = Color.from_string(b.color, Color.GRAY)
                mat.roughness = 0.6
                mat.metalness = 0.1
                mesh.material_override = mat
                mesh.add_to_group("scheme_building")
                mesh.set_meta("scheme_id", b.id)
                mesh.set_meta("scheme_name", b.name)
                mesh.set_meta("scheme_emoji", b.emoji)
                parent.add_child(mesh)
                
                # Collision
                var body = StaticBody3D.new()
                body.position = Vector3(b.x, b.h / 2.0, b.z)
                var col = CollisionShape3D.new()
                var shape = BoxShape3D.new()
                shape.size = Vector3(b.w, b.h, b.d)
                col.shape = shape
                body.add_child(col)
                parent.add_child(body)
                
                # Label
                var label = Label3D.new()
                label.text = "%s %s" % [b.emoji, b.name]
                label.position = Vector3(b.x, b.h + 2, b.z)
                label.font_size = 48
                label.outline_size = 6
                label.outline_modulate = Color.BLACK
                label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
                label.no_depth_test = true
                parent.add_child(label)

static func _build_filler_buildings(parent: Node3D) -> void:
        var grid = 20
        var half = 220
        for gx in range(-half, half + 1, grid):
                for gz in range(-half, half + 1, grid):
                        var cx = gx + grid / 2.0
                        var cz = gz + grid / 2.0
                        var r = sqrt(cx * cx + cz * cz)
                        if r < 18 or r > 235:
                                continue
                        if _is_on_road(cx, cz):
                                continue
                        # Skip near scheme buildings
                        var too_close = false
                        for b in SCHEME_BUILDINGS:
                                if sqrt((cx - b.x) ** 2 + (cz - b.z) ** 2) < max(b.w, b.d) / 2 + 6:
                                        too_close = true
                                        break
                        if too_close:
                                continue
                        # Hash-based random
                        var seed_val = abs((gx * 73856093) ^ (gz * 19349663)) % 99991
                        var rng = func(salt): return float((seed_val * (salt + 1) * 9301 + 49297) % 233280) / 233280
                        # Gap chance
                        var dist_id = get_district_at(cx, cz)
                        var gap = 0.25 if dist_id in ["downtown", "harbor", "slums", "industrial"] else (0.4 if dist_id == "suburbs" else 0.7)
                        if rng.call(99) < gap:
                                continue
                        # Dimensions
                        var w: float
                        var d: float
                        var h: float
                        var dist = DISTRICTS[dist_id]
                        if dist_id == "rural":
                                w = 5 + rng.call(1) * 3
                                d = 4 + rng.call(2) * 3
                                h = 3 + rng.call(3) * 3
                        elif dist_id == "suburbs":
                                w = 7 + rng.call(1) * 4
                                d = 6 + rng.call(2) * 3
                                h = dist.height_min + rng.call(3) * (dist.height_max - dist.height_min)
                        else:
                                w = 8 + rng.call(1) * 6
                                d = 7 + rng.call(2) * 5
                                h = dist.height_min + rng.call(3) * (dist.height_max - dist.height_min)
                        # Offset
                        var margin = 2.0
                        var max_off = max(0, (grid - w - margin * 2) / 2)
                        var ox = (rng.call(4) - 0.5) * max_off
                        var oz = (rng.call(5) - 0.5) * max_off
                        var fx = cx + ox
                        var fz = cz + oz
                        # Corner check
                        if _is_on_road(fx - w / 2, fz - d / 2) or _is_on_road(fx + w / 2, fz + d / 2):
                                continue
                        if _is_on_road(fx - w / 2, fz + d / 2) or _is_on_road(fx + w / 2, fz - d / 2):
                                continue
                        # Build it
                        var mesh = MeshInstance3D.new()
                        var f_mesh = BoxMesh.new()
                        f_mesh.size = Vector3(w, h, d)
                        mesh.mesh = f_mesh
                        var ground_y = terrain_height(fx, fz)
                        mesh.position = Vector3(fx, ground_y + h / 2, fz)
                        var mat = StandardMaterial3D.new()
                        var palette = ["#475569", "#334155", "#1e293b", "#64748b", "#3f3f46"]
                        mat.albedo_color = Color.from_string(palette[int(rng.call(6) * palette.size()) % palette.size()], Color.GRAY)
                        mat.roughness = 0.85
                        mesh.material_override = mat
                        parent.add_child(mesh)
                        # Collision
                        var body = StaticBody3D.new()
                        body.position = Vector3(fx, ground_y + h / 2, fz)
                        var col = CollisionShape3D.new()
                        var shape = BoxShape3D.new()
                        shape.size = Vector3(w, h, d)
                        col.shape = shape
                        body.add_child(col)
                        parent.add_child(body)

static func _is_on_road(x: float, z: float) -> bool:
        # Main axes at 0, ±78
        for pos in [0, 78, -78]:
                if abs(z - pos) < ROAD_HALF_MAIN + SIDEWALK and abs(x) < 160:
                        return true
                if abs(x - pos) < ROAD_HALF_MAIN + SIDEWALK and abs(z) < 160:
                        return true
        # Internal streets every 20m
        for p in range(-60, 61, 20):
                if p == 0:
                        continue
                if abs(z - p) < ROAD_HALF_SIDE + SIDEWALK and abs(x) < 80:
                        return true
                if abs(x - p) < ROAD_HALF_SIDE + SIDEWALK and abs(z) < 80:
                        return true
        # Suburb roads
        for p in range(-140, 141, 30):
                if abs(p) <= 78:
                        continue
                if abs(z - p) < ROAD_HALF_SIDE + 2 and abs(x) < 150:
                        return true
                if abs(x - p) < ROAD_HALF_SIDE + 2 and abs(z) < 150:
                        return true
        return false

static func _build_map_borders(parent: Node3D) -> void:
        # Mountains (North, z = -220 to -260)
        for i in range(-260, 261, 30):
                var mx = i + (randf() - 0.5) * 20
                var mz = -220 - randf() * 40
                var mh = 35 + randf() * 20
                var mr = 25 + randf() * 15
                var m = MeshInstance3D.new()
                var m_mesh = CylinderMesh.new()
                m_mesh.top_radius = 0
                m_mesh.bottom_radius = mr
                m_mesh.height = mh
                m.mesh = m_mesh
                m.position = Vector3(mx, terrain_height(mx, mz) + mh / 2, mz)
                m.rotation.y = randf() * PI
                var mat = StandardMaterial3D.new()
                mat.albedo_color = Color(0.35, 0.29, 0.23)
                mat.roughness = 0.95
                m.material_override = mat
                parent.add_child(m)
        
        # Dense forest (NW + NE)
        for i in range(240):
                var x: float
                var z: float
                if i < 120:
                        x = -220 - randf() * 50
                        z = -220 + randf() * 170
                else:
                        x = 220 + randf() * 50
                        z = -220 + randf() * 170
                _make_tree(parent, x, z, 0.8 + randf() * 0.6)
        
        # Highway barricade (East, x=240)
        var by = terrain_height(240, 0)
        for i in range(20):
                var bz = -100 + i * 12
                var b = MeshInstance3D.new()
                var b_mesh = BoxMesh.new()
                b_mesh.size = Vector3(1.2, 1.2, 8)
                b.mesh = b_mesh
                b.position = Vector3(240, by + 0.6, bz)
                var mat = StandardMaterial3D.new()
                mat.albedo_color = Color(0.63, 0.63, 0.63)
                b.material_override = mat
                parent.add_child(b)
        # Sign (renamed to avoid conflict with built-in sign())
        var road_sign = MeshInstance3D.new()
        var rs_mesh = BoxMesh.new()
        rs_mesh.size = Vector3(4, 1, 0.1)
        road_sign.mesh = rs_mesh
        road_sign.position = Vector3(240, by + 3, 0)
        var smat = StandardMaterial3D.new()
        smat.albedo_color = Color(0.86, 0.15, 0.08)
        smat.emission_enabled = true
        smat.emission = Color(0.86, 0.15, 0.08)
        smat.emission_energy_multiplier = 0.3
        road_sign.material_override = smat
        parent.add_child(road_sign)
        
        # Military fence (West, x=-240)
        var fy = terrain_height(-240, 0)
        for i in range(40):
                var fz = -200 + i * 10
                var post = MeshInstance3D.new()
                var p_mesh = CylinderMesh.new()
                p_mesh.top_radius = 0.05
                p_mesh.bottom_radius = 0.05
                p_mesh.height = 3
                post.mesh = p_mesh
                post.position = Vector3(-240, fy + 1.5, fz)
                var pmat = StandardMaterial3D.new()
                pmat.albedo_color = Color(0.29, 0.29, 0.23)
                post.material_override = pmat
                parent.add_child(post)
        # Warning sign
        var wsign = MeshInstance3D.new()
        var ws_mesh = BoxMesh.new()
        ws_mesh.size = Vector3(2, 1.5, 0.1)
        wsign.mesh = ws_mesh
        wsign.position = Vector3(-239.9, fy + 2.5, 0)
        var wsmat = StandardMaterial3D.new()
        wsmat.albedo_color = Color(0.98, 0.8, 0.08)
        wsmat.emission_enabled = true
        wsmat.emission = Color(0.98, 0.8, 0.08)
        wsmat.emission_energy_multiplier = 0.2
        wsign.material_override = wsmat
        parent.add_child(wsign)
        # Watchtower
        var tower = MeshInstance3D.new()
        var t_mesh = BoxMesh.new()
        t_mesh.size = Vector3(3, 8, 3)
        tower.mesh = t_mesh
        tower.position = Vector3(-235, fy + 4, 0)
        var tmat = StandardMaterial3D.new()
        tmat.albedo_color = Color(0.29, 0.29, 0.23)
        tower.material_override = tmat
        parent.add_child(tower)
        
        # Rural scattered trees
        for i in range(80):
                var angle = randf() * TAU
                var dist = 150 + randf() * 70
                var tx = cos(angle) * dist
                var tz = sin(angle) * dist
                if tz > 100 and dist > 150:
                        continue
                var ty = terrain_height(tx, tz)
                if ty < 0:
                        continue
                _make_tree(parent, tx, tz, 0.6 + randf() * 0.8)

static func _make_tree(parent: Node3D, x: float, z: float, s: float):
        var ground_y = terrain_height(x, z)
        # Trunk
        var trunk = MeshInstance3D.new()
        var trunk_mesh = CylinderMesh.new()
        trunk_mesh.top_radius = 0.2
        trunk_mesh.bottom_radius = 0.3
        trunk_mesh.height = 3
        trunk.mesh = trunk_mesh
        trunk.position = Vector3(x, ground_y + 1.5, z)
        var tmat = StandardMaterial3D.new()
        tmat.albedo_color = Color(0.29, 0.23, 0.1)
        tmat.roughness = 0.9
        trunk.material_override = tmat
        trunk.scale = Vector3(s, s, s)
        parent.add_child(trunk)
        # Foliage (cone)
        var foliage = MeshInstance3D.new()
        var fol_mesh = PrismMesh.new()
        fol_mesh.size = Vector3(3.6, 4, 3.6)
        foliage.mesh = fol_mesh
        foliage.position = Vector3(x, ground_y + 3.5, z)
        var fmat = StandardMaterial3D.new()
        fmat.albedo_color = Color(0.17, 0.29, 0.1)
        fmat.roughness = 0.85
        foliage.material_override = fmat
        foliage.scale = Vector3(s, s, s)
        parent.add_child(foliage)

static func _build_street_lamps(parent: Node3D) -> void:
        var positions = [
                Vector3(-6, 0, -4), Vector3(6, 0, -4), Vector3(-6, 0, 6), Vector3(6, 0, 6),
                Vector3(-20, 0, -20), Vector3(20, 0, -20), Vector3(-20, 0, 20), Vector3(20, 0, 20),
                Vector3(-30, 0, -40), Vector3(-45, 0, -15), Vector3(30, 0, -40), Vector3(45, 0, -15),
                Vector3(-30, 0, 40), Vector3(-45, 0, 15), Vector3(30, 0, 40), Vector3(45, 0, 15),
        ]
        for pos in positions:
                var pole = MeshInstance3D.new()
                var p_mesh = CylinderMesh.new()
                p_mesh.top_radius = 0.08
                p_mesh.bottom_radius = 0.08
                p_mesh.height = 4
                pole.mesh = p_mesh
                pole.position = pos + Vector3(0, 2, 0)
                var mat = StandardMaterial3D.new()
                mat.albedo_color = Color(0.06, 0.06, 0.06)
                pole.material_override = mat
                parent.add_child(pole)
                var light = OmniLight3D.new()
                light.position = pos + Vector3(0, 4, 0)
                light.light_color = Color(1, 0.95, 0.8)
                light.light_energy = 2.0
                light.omni_range = 12.0
                parent.add_child(light)
