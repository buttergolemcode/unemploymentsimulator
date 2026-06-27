# Feature Specification: Vehicle Visuals & Animations

**Feature Branch**: `011-vehicle-visuals`

**Created**: 2026-06-27

**Status**: Implemented (retroactive spec)

## User Scenarios & Testing

### User Story 1 - Real Car Models (Priority: P1)

Vehicles use Quaternius CC0 FBX car models (7 types). Each car model is loaded from assets/quaternius_cars/FBX/. If FBX fails to load, a procedural box-mesh car is used as fallback.

**Acceptance Scenarios**:
1. **Given** game spawns a vehicle with car_model="Taxi", **Then** Taxi.fbx is loaded and displayed.
2. **Given** FBX file is missing, **Then** box-mesh fallback is used (body + cabin + windshield + 4 wheels + lights).

### User Story 2 - Body Roll & Pitch (Priority: P2)

Car body visually rolls into turns (lean outside) and pitches on accel/brake (squat/dive). Smooth lerping, subtle angles (max ~4.5° roll, ~1.7° pitch).

**Acceptance Scenarios**:
1. **Given** car turns right at 15 m/s, **Then** body rolls left (outside of turn) by up to 4.5°.
2. **Given** player accelerates hard (W), **Then** body pitches nose-up (squat) by up to 1.7°.
3. **Given** player brakes hard (Space), **Then** body pitches nose-down (dive) by up to 1.7°.

### User Story 3 - Wheel Spin & Steering (Priority: P3)

Wheels spin on X-axis based on speed (box-mesh fallback only). Front wheels turn left/right on Y-axis when steering (box-mesh fallback only). FBX models: steering animation disabled (mesh offset issue).

**Acceptance Scenarios**:
1. **Given** box-mesh car is moving at 10 m/s, **Then** all 4 wheels rotate on X-axis (spin).
2. **Given** box-mesh car steers right, **Then** front 2 wheels rotate on Y-axis (steering).
3. **Given** FBX car steers right, **Then** wheels do NOT rotate (steering disabled for FBX — known limitation).

### User Story 4 - Headlights & Taillights (Priority: P3)

Each car has 2 headlights (warm white OmniLight, front) and 2 taillights (red OmniLight, rear). Lights are added separately (not part of FBX model).

**Acceptance Scenarios**:
1. **Given** car spawns, **Then** 4 OmniLights are visible (2 front warm, 2 rear red).

## Requirements

### Functional Requirements

- **FR-001**: 7 car models: NormalCar1, NormalCar2, SportsCar, SportsCar2, SUV, Taxi, Cop (all FBX)
- **FR-002**: _build_mesh() tries FBX first, falls back to _build_box_mesh()
- **FR-003**: FBX model: instantiate PackedScene, scale 1.0, add to CarMesh node
- **FR-004**: Box-mesh fallback: body (BoxMesh 2.0×1.2×4.5), cabin (BoxMesh 1.7×0.8×2.0), windshield, 4 wheels (CylinderMesh r=0.4)
- **FR-005**: _find_wheels(): walks tree, collects nodes with "wheel" in name (Quaternius: FrontLeftWheel, FrontRightWheel, BackWheels)
- **FR-006**: Wheel spin (box-mesh only): rotate_x(speed * 3.0 * delta)
- **FR-007**: Front wheel steering (box-mesh only): pivot.rotation.y = lerp(current, -steer * 0.5 * factor, delta * 8.0)
- **FR-008**: Body roll: mesh.rotation.z = lerp(current, -steer * speed_factor * 0.08, delta * 5.0)
- **FR-009**: Body pitch: mesh.rotation.x = lerp(current, -throttle * 0.03, delta * 4.0)
- **FR-010**: Headlights: 2x OmniLight3D at (±0.75, 0.85, 2.25), warm white, energy 1.5, range 8.0
- **FR-011**: Taillights: 2x OmniLight3D at (±0.75, 0.85, -2.25), red, energy 0.8, range 4.0
- **FR-012**: _use_box_mesh flag: true for box-mesh fallback, false for FBX (controls animation)

## Success Criteria

- **SC-001**: All 7 car models load and display correctly
- **SC-002**: Box-mesh fallback works when FBX is missing
- **SC-003**: Body roll/pitch animation is smooth and subtle
- **SC-004**: Wheel spin visible on box-mesh cars
- **SC-005**: Steering visible on box-mesh front wheels

## Assumptions

- FBX wheel steering is DISABLED (mesh offset != node origin causes arc-swing bug)
- Real wheel animations planned for Sprint D.5 (Universal Animation Library + proper rigging)
- Body roll/pitch affects mesh.rotation, not physics (visual only)
