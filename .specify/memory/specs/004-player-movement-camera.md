# Feature Specification: Player Movement & Camera

**Feature Branch**: `004-player-movement-camera`

**Created**: 2026-06-27

**Status**: Implemented (retroactive spec)

## User Scenarios & Testing

### User Story 1 - Walk in First Person (Priority: P1)

Player uses WASD to walk and mouse to look around in first-person view. The camera is at eye height (1.6m). Movement is direction-relative to where the player is facing.

**Acceptance Scenarios**:
1. **Given** game is playing and mouse is captured, **When** player presses W, **Then** player moves forward in the direction the camera faces.
2. **Given** player presses Shift while moving, **Then** speed increases from 5 m/s to 8 m/s (sprint).

### User Story 2 - Toggle Third Person (Priority: P2)

Player presses V to switch to third-person view. The player mesh becomes visible and the camera orbits behind the player at 4.5m distance, 1.6m height.

**Acceptance Scenarios**:
1. **Given** camera_mode is "first", **When** player presses V, **Then** camera_mode changes to "third", player mesh becomes visible, camera moves behind player.
2. **Given** camera_mode is "third", **When** player presses V, **Then** camera_mode changes to "first", player mesh becomes invisible, camera moves to eye height.

### User Story 3 - Mouse Capture Toggle (Priority: P2)

Player presses Esc to release the mouse cursor (for UI interaction). Clicking the game window recaptures the mouse.

**Acceptance Scenarios**:
1. **Given** mouse is captured, **When** player presses Esc, **Then** mouse mode changes to VISIBLE.
2. **Given** mouse is visible, **When** player clicks left mouse button, **Then** mouse mode changes to CAPTURED.

### User Story 4 - Building Proximity Detection (Priority: P1)

As the player walks near a scheme building (within 8m), the system auto-detects the nearest building and logs "Press E to enter [building name]".

**Acceptance Scenarios**:
1. **Given** player is 7m from Trading Floor, **When** _check_nearby() runs, **Then** nearby_building_id = "trading" and log shows "Press E to enter Trading Floor".
2. **Given** player is 10m from all buildings, **When** _check_nearby() runs, **Then** nearby_building_id = "" (no prompt).

## Requirements

### Functional Requirements

- **FR-001**: Player MUST be a CharacterBody3D with MOTION_MODE_GROUNDED, floor_snap_length=0.3, floor_max_angle=50°
- **FR-002**: Camera MUST be top_level (detached from player transform) for stable framing
- **FR-003**: Mouse sensitivity MUST be 0.0022 rad/pixel
- **FR-004**: Pitch MUST be clamped to ±1.5 rad (±86°)
- **FR-005**: Movement vector MUST be: forward = (-sin(yaw), 0, -cos(yaw)), right = (cos(yaw), 0, -sin(yaw))
- **FR-006**: Walk speed = 5.0 m/s, sprint speed = 8.0 m/s
- **FR-007**: Gravity = 9.8 m/s² when not on floor, velocity.y = 0 when on floor
- **FR-008**: Player collision: CapsuleShape3D, radius=0.35, height=1.7, center y=0.85
- **FR-009**: All input MUST be gated by GameManager.phase == "playing"
- **FR-010**: Player MUST be in group "player" (for vehicle sync)
- **FR-011**: Player mesh MUST load Suit.fbx (Quaternius Modular Character), fallback to capsule+head+beanie
- **FR-012**: Press E to interact with nearest building (within 8m)
- **FR-013**: Press B to end day when actions_left == 0
- **FR-014**: Press F to enter/exit vehicle (within 5m)
- **FR-015**: camera_yaw variable MUST be independent from yaw (for free-look in vehicle)

## Success Criteria

- **SC-001**: Player moves smoothly in all 8 directions (WASD combinations)
- **SC-002**: Camera doesn't flip or glitch at pitch limits
- **SC-003**: Building proximity detection works within 8m radius
- **SC-004**: First/third person toggle works without camera jumps
- **SC-005**: Player stays on ground (no floating or sinking) with floor_snap

## Assumptions

- Camera is a child of Player node in GameScene.tscn, but top_level=true detaches its transform
- Player spawn position is set in GameScene.tscn (currently x=0, y=0.1, z=30)
- Input is checked via Input.is_key_pressed() (not InputMap actions) for WASD
