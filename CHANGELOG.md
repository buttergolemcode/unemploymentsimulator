# Changelog

Detailed log of implementation work. The Masterplan defines what we WILL do; this file records what we DID do.

Format: entries are grouped by Sprint sub-step, newest first. Each entry has the commit hash, date, and a description of changes.

---

## Sprint D — Assets & Map Polish

### D.2 — Vehicle model integration ✅ (post-completion fixes)

**Commit `f7ca151` (2026-06-26): Front wheel steering direction inverted**
- A=left turned wheels RIGHT visually (wrong direction)
- Root cause: `pivot.rotation.y = +X` rotates counterclockwise from above.
  Positive steer (D=right) was mapped to positive Y rotation → wheels turned LEFT.
- Fix: Negate the steering input in `target_steer_angle = -current_steer * 0.5 * steer_visual_factor`
- Now: A → wheels turn left, D → wheels turn right

**Commit `edee88f` (2026-06-26): Pivot-based wheel steering (proper fix)**
- Front wheels appeared as black circles (Felge hidden) when steering
- Root cause: `wheel.rotation.y = X` rotated the wheel MESH around Y, which
  changed the cylinder's axis orientation. User saw tire's side profile
  instead of the rim.
- Fix: Wrap each front wheel in a parent `pivot` Node3D. Rotate PIVOT on Y,
  not the wheel mesh itself. Preserves wheel's local orientation.
- New vars: `_front_wheel_pivots`, `_front_wheels_raw`
- `_find_wheels()` now creates pivot Node3Ds and reparents wheels into them
- `_collect_wheels()` detects Quaternius naming ("FrontLeftWheel", "FrontRightWheel", "BackWheels")
- Box-mesh fallback also uses pivots (consistent behavior)

**Commit `e4d07ec` (2026-06-26): Indentation fix**
- Converted PlayerController.gd, GameScene.gd, WorldBuilder.gd from spaces to tabs
- Godot 4.7 linter was warning "Used space character for indentation instead of tab"
- All 16 .gd files now use tabs consistently

**Commit `ecacf0b` (2026-06-26): NPC orientation fix + re-enable wheel steering**
- Re-enabled `instance.rotation.y = PI` in NPC.gd and PlayerController.gd
  (had been removed in previous attempt to fix backwards walking)
- Re-enabled front-wheel steering animation (was disabled to fix glitching)

**Commit `dac7ed8` (2026-06-26): Wheel glitching + NPC T-pose diagnosis**
- Diagnosed: Quaternius Modular Characters pack has no animations (T-pose expected)
- Diagnosed: NPCs walking backwards due to wrong mesh orientation
- Reduced walk bob amplitude (0.06 → 0.03) for subtler animation

**Commits `698b197` + `e443928` (2026-06-26): abs_speed scope fixes**
- Fixed two instances of `Identifier 'abs_speed' not declared in current scope`
- Bug introduced during front-wheel steering refactor
- Added `var abs_speed = abs(speed)` declarations in both `_physics_process` and `_animate_wheels_and_body`

### D.3 — NPC model integration ✅ (post-completion fixes)

**Commit `a2dc007` (2026-06-26): NPC/player walking backwards (final fix)**
- Math-based fix (`atan2(-dx, -dz)`) didn't work for Quaternius FBX models
- Pragmatic fix per user suggestion: rotate mesh by PI (180 degrees)
- `instance.rotation.y = PI` in both NPC.gd and PlayerController.gd
- T-pose remains (no animations in Modular Characters pack — expected)
- Real walk animations would need Universal Animation Library (not auto-downloadable from itch.io)

**Commit `4595322` (2026-06-26): Initial D.3 implementation**
- Downloaded Quaternius Ultimate Modular Characters Pack via gdown from Google Drive
- 12 FBX files added to `godot/assets/quaternius_modular_chars/FBX/`:
  Adventurer, Beach, Casual, Casual2, Farmer, King, Punk, Spacesuit, Suit, Swat, Worker + Humans_Master
- `NPC.gd`: Added `CHARACTER_MODELS` const (11 names), `get_model_path()` static helper
- `NPC.gd _build_mesh()`: Loads random character FBX, falls back to capsule
- `PlayerController.gd _build_mesh()`: Loads `Suit.fbx` as player model
- `PlayerController.gd`: Extracted `_build_capsule_mesh(mesh_node)` as fallback helper
- Merchant badge added separately on top of real character model
- Existing knockdown state + walk bob preserved

**Note on animations:** Universal Animation Library (120+ anims) could not be
downloaded — itch.io purchase flow blocks scripted downloads. Using procedural
walk bob + forward lean for now. Real animations will be integrated when available.

**Commit `52ed661` (2026-06-26): Cleanup**
- Removed accidentally committed HTML files (char_page.html, page.html, search.html)
- Updated `.gitignore` to exclude *.html (except index.html)

### D.2 — Vehicle model integration ✅ (initial)

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
