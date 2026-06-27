# Feature Specification: Debug Mode (Noclip, Fast Speed, Teleport, Position Print)

**Feature Branch**: `013-debug-mode`

**Created**: 2026-06-27

**Status**: Implemented (retroactive spec) — REMOVE BEFORE RELEASE

## User Scenarios & Testing

### User Story 1 - Noclip Flight (Priority: P1)

Developer presses F1 to toggle noclip mode. Player switches to FLOATING motion mode — gravity and collision are disabled. WASD moves in the look direction (3D, including up/down based on camera pitch). Space flies straight up, Ctrl flies straight down. Pressing F1 again disables noclip and returns to normal grounded movement.

**Why this priority**: Noclip is the primary debug tool for inspecting terrain, building placement, and world geometry from any angle without being blocked by collision.

**Independent Test**: Press F1 → verify player floats, can fly through buildings/terrain. Press F1 again → verify player falls to ground normally.

**Acceptance Scenarios**:
1. **Given** game is playing, **When** developer presses F1, **Then** motion_mode changes to FLOATING, "[DEBUG] Noclip: true" prints to console, player can fly freely.
2. **Given** noclip is active, **When** developer presses Space, **Then** player ascends vertically at 30 m/s (80 m/s with Shift or F2 fast mode).
3. **Given** noclip is active, **When** developer presses Ctrl, **Then** player descends vertically.
4. **Given** noclip is active, **When** developer presses F1 again, **Then** motion_mode changes back to GROUNDED, player falls to terrain.

### User Story 2 - Fast Speed (Priority: P2)

Developer presses F2 to toggle 4× speed boost. Works in both normal movement (walk/sprint) and noclip mode. Useful for quickly traversing the 3000m map during testing.

**Acceptance Scenarios**:
1. **Given** normal movement (not noclip), **When** developer presses F2, **Then** walk speed becomes 20 m/s, sprint speed becomes 32 m/s.
2. **Given** noclip is active, **When** developer presses F2, **Then** fly speed increases from 30 to 80 m/s.

### User Story 3 - Teleport to Ground (Priority: P2)

Developer presses F3 to teleport player to terrain_height() at current XZ position + 2m. Useful when stuck inside terrain or buildings.

**Acceptance Scenarios**:
1. **Given** player is stuck in terrain or floating, **When** developer presses F3, **Then** player Y is set to terrain_height(x,z) + 2.0, "[DEBUG] Teleported to ground at Y=..." prints to console.

### User Story 4 - Print Position (Priority: P3)

Developer presses F4 to print current global position and district to the console. Useful for debugging building/scheme positions and verifying terrain heights.

**Acceptance Scenarios**:
1. **Given** game is playing, **When** developer presses F4, **Then** console shows "[DEBUG] Position: (X, Y, Z) District: downtown" (or whatever district the player is in).

### Edge Cases

- What happens if developer presses F1 while in a vehicle? → Noclip is ignored while in_vehicle (the _physics_process returns early for vehicles).
- What happens if noclip is active and developer enters a vehicle (F)? → Noclip remains toggled but has no effect while driving. When exiting vehicle, noclip state resumes.
- What happens if game phase changes (win/lose) while noclip is active? → Input is gated by `GameManager.phase == "playing"`, so debug keys stop working.

## Requirements

### Functional Requirements

- **FR-001**: F1 MUST toggle `debug_noclip` between true/false
- **FR-002**: When `debug_noclip` is true, `motion_mode` MUST be set to `CharacterBody3D.MOTION_MODE_FLOATING`
- **FR-003**: When `debug_noclip` is false, `motion_mode` MUST be set to `CharacterBody3D.MOTION_MODE_GROUNDED`
- **FR-004**: In noclip mode, movement MUST follow 3D look direction: `forward3 = Vector3(-sin(yaw), -sin(pitch), -cos(yaw)).normalized()`
- **FR-005**: In noclip mode, Space MUST set `velocity.y = +fly_speed`, Ctrl MUST set `velocity.y = -fly_speed`
- **FR-006**: Noclip speed: 30 m/s normal, 80 m/s with Shift or debug_fast
- **FR-007**: F2 MUST toggle `debug_fast` between true/false
- **FR-008**: When `debug_fast` is true (normal mode), walk/sprint speed MUST be multiplied by 4
- **FR-009**: F3 MUST teleport player to `terrain_height(x, z) + 2.0` at current XZ
- **FR-010**: F4 MUST print `[DEBUG] Position: <pos> District: <district>` to console
- **FR-011**: All debug keys MUST be gated by `GameManager.phase == "playing"`
- **FR-012**: Debug keys MUST be ignored while `in_vehicle` is true (F1-F4 still toggle state but movement code doesn't execute for vehicles)
- **FR-013**: All debug code MUST be clearly marked with `# === DEBUG MODE — REMOVE BEFORE RELEASE ===`
- **FR-014**: Before release, ALL debug code MUST be removed by searching for "DEBUG" in PlayerController.gd

### Key Entities

- **debug_noclip**: bool — toggles floating mode and 3D movement
- **debug_fast**: bool — toggles 4× speed multiplier
- **DEBUG_NOCLIP_SPEED**: const float = 30.0 — base noclip fly speed
- **DEBUG_NOCLIP_FAST_SPEED**: const float = 80.0 — fast noclip fly speed (Shift or F2)

## Success Criteria

- **SC-001**: F1 toggles noclip reliably (no stuck states)
- **SC-002**: Noclip movement follows look direction in 3D (up/down with pitch)
- **SC-003**: F2 speed boost applies to both normal and noclip movement
- **SC-004**: F3 teleport correctly reads terrain_height() and places player above ground
- **SC-005**: F4 prints accurate position and district info
- **SC-006**: Debug keys don't interfere with normal gameplay keys (E, F, V, B, Esc)
- **SC-007**: All debug code is clearly marked and easily removable before release

## Assumptions

- Debug mode is for DEVELOPMENT ONLY — not accessible by end users in release builds
- Debug keys (F1-F4) don't conflict with any existing gameplay keybindings
- `WorldBuilder.terrain_height()` and `WorldBuilder.get_district_at()` are accessible as static functions
- The debug section is at the top of PlayerController.gd, clearly separated from production code
