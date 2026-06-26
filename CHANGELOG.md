# Changelog

Detailed log of implementation work. The Masterplan defines what we WILL do; this file records what we DID do.

Format: entries are grouped by Sprint sub-step, newest first. Each entry has the commit hash, date, and a description of changes.

---

## Sprint D — Assets & Map Polish

### D.2 — Vehicle model integration ✅

**Commit `b564d53` (2026-06-26): Front-wheel steering animation**
- `Vehicle.gd _animate_wheels_and_body()`: front wheels now turn on Y-axis based on steer input
- Visual steering factor: full lock (1.0) below 5 m/s, reduced to 0.3 at high speed
- Max angle: 0.5 rad (~28°, matches real car full lock)
- Smooth lerping via `lerp(wheel.rotation.y, target, delta * 8.0)`
- Front wheels identified via Quaternius naming ("Wheel_FL", "Wheel_FR") with fallback to first 2 wheels
- `_build_box_mesh()`: front/rear wheel assignment added for fallback mode

**Commit `9558d3b` (2026-06-26): Free-look camera + realistic low-speed turning**
- `PlayerController.gd`: Added `camera_yaw` variable separate from `yaw`
  - Mouse-look updates `camera_yaw` when in vehicle, not `yaw`
  - `camera_yaw` initialized to `vehicle.yaw` on enter (no jump)
  - `_update_vehicle_camera()` orbits camera around `camera_yaw`
  - Result: mouse can freely look around car while driving
- `Vehicle.gd`: Replaced inverse steering formula with bell curve
  - Old: `clamp(2.0/(s+0.5), 0.4, 1.5)` × `turn_rate=3.0` → 230°/s at 1 m/s (tank-spin)
  - New: linear ramp 0→0.7 (0-5 m/s), then decay to 0.3 (5-22 m/s), `turn_rate=2.0`
  - `min_turn_speed: 1.0 → 2.0` (no turning under 2 m/s)
  - New yaw rates: 32°/s @ 2 m/s, 80°/s @ 5 m/s, 66°/s @ 10 m/s, 34°/s @ 22 m/s

**Commit `5ff490c` (2026-06-26): Initial D.2 implementation**
- `VehicleData.gd`: Added `CAR_MODELS` dict mapping 7 model names to FBX paths
- `VehicleData.gd`: `VEHICLE_POSITIONS` references model names (not colors)
- `Vehicle.gd`: Added `car_model` variable, `_build_mesh()` tries real FBX first
  - Falls back to box mesh if asset missing
  - `ResourceLoader.exists()` check + fallback `load()` for unimported FBX
- `Vehicle.gd _instantiate_model()`: Scales model, finds wheel nodes
- `Vehicle.gd _find_wheels()`: Walks tree, collects nodes with "wheel" in name
  - Separates front/rear via "_f"/"front" and "_r"/"rear"/"_b" in name
- `Vehicle.gd _animate_wheels_and_body()`: New function
  - Wheel spin: `rotate_x(speed * 3 * delta)` for visual feedback
  - Body roll: `target_roll = -steer * speed_factor * 0.08` (max ~4.5°)
  - Body pitch: squat on accel, dive on brake (max ~1.7°)
- `GameScene.gd _spawn_vehicles()`: Passes model name (not color)
- Lights (headlights/taillights) added separately

### D.0 / D.1 — Assets download + project structure ✅

**Commits `a7264d6` and earlier (2026-06-25):**
- 8 CC0 asset packs downloaded to `godot/assets/` via curl + gdown:
  - Kenney City Kit: Commercial (42 GLB), Suburban (35+), Industrial, Roads (65+)
  - Quaternius: Cars (7 FBX), Characters (.blend), Streets (.blend)
  - KayKit: City Builder Bits (GLTF/FBX/OBJ)
- Total: 43MB, 1078 files
- `godot/assets/README.md` asset inventory with sources, licenses, formats

---

## Sprint C — Vehicles & Driving (BASIC) ✅

Multiple commits (2026-06-25 through 2026-06-26):
- Custom CharacterBody3D-based vehicle physics (no external physics engine)
- Enter/exit vehicles (F key), WASD driving, Space brake
- Third-person chase camera (top_level detached from player transform)
- NPC run-over mechanic (knockdown + 4s recovery state)
- Collision response: speed bleed on wall impact
- Realistic steering (speed-dependent, no tank-spin, reverse-inverts-steering)

---

## Sprint B — Native .exe (Godot) ✅

(2026-06-25):
- Pivoted from Three.js + Tauri to Godot 4.7
- Full GDScript rewrite of all 16 scripts
- GitHub repo: `buttergolemcode/unemploymentsimulator`
- Simple `AutoUpdater.gd` (HTTP version check + dialog)

---

## Sprint A — City & Atmosphere (placeholder) ✅

(2026-06-25):
- 6 districts (Downtown, Harbor, Slums, Industrial, Suburbs, Rural)
- 8 scheme buildings placed
- Box-mesh NPCs with simple walk animation
- Weather system (rain particles, clouds, ambient light)
- Day/night cycle (12-min cycle, starts at noon)
- WorldBuilder.gd: terrain, roads, buildings, borders, lamps
- PlayerController.gd: WASD + mouse, first/third person, vehicle enter/exit

---

## Pre-Sprint work

- Initial Godot 4.7 project setup
- 8 schemes (ecom, trading, gambling, drugs, scam, robbery, taxfraud, wirefraud) with 22 actions
- 8 random events with branching choices
- Heat/Money/Rep/Day/Skills systems
- Main menu, game scene, end screen
