# Feature Specification: Vehicle Driving System

**Feature Branch**: `005-vehicle-driving`

**Created**: 2026-06-27

**Status**: Implemented (retroactive spec)

## User Scenarios & Testing

### User Story 1 - Enter and Drive a Car (Priority: P1)

Player walks near a car (within 5m), presses F to enter. Camera switches to third-person chase cam. Player drives with WASD (W=throttle, S=reverse/brake, A/D=steer, Space=handbrake). Press F to exit.

**Acceptance Scenarios**:
1. **Given** player is within 5m of an unoccupied vehicle, **When** player presses F, **Then** player enters vehicle, camera switches to chase cam, player mesh hidden.
2. **Given** player is driving, **When** player presses F, **Then** player exits at 2.5m behind vehicle, camera returns to player mode, vehicle stops.

### User Story 2 - Realistic Steering (Priority: P1)

Steering authority follows a bell curve: ramps up from 0 at standstill to peak at 5 m/s, then decreases at high speed. Reverse inverts steering. No turning below 2 m/s (no tank-spin).

**Acceptance Scenarios**:
1. **Given** speed is 0, **When** player steers, **Then** no turning occurs (below min_turn_speed).
2. **Given** speed is 5 m/s, **When** player steers full right, **Then** yaw changes at maximum rate (~80°/s).
3. **Given** speed is 22 m/s (max), **When** player steers full right, **Then** yaw changes at reduced rate (~34°/s).
4. **Given** player is reversing (speed < 0), **When** player steers right, **Then** steering inverts (turns left visually).

### User Story 3 - Collision Impact (Priority: P2)

When the car hits a wall or obstacle, it loses speed proportional to impact strength and bounces back slightly.

**Acceptance Scenarios**:
1. **Given** car is driving at 20 m/s into a building, **When** collision occurs, **Then** speed reduced by 30-95% (depending on impact angle) and small pushback applied.

### User Story 4 - Free-Look Camera While Driving (Priority: P2)

While driving, the mouse controls camera_yaw independently of the car's heading. Player can look around the car without affecting driving direction.

**Acceptance Scenarios**:
1. **Given** player is driving, **When** player moves mouse left, **Then** camera orbits left around car, but car continues driving straight.
2. **Given** player enters vehicle, **Then** camera_yaw initializes to vehicle.yaw (no camera jump on entry).

## Requirements

### Functional Requirements

- **FR-001**: Vehicle MUST be CharacterBody3D with MOTION_MODE_GROUNDED, floor_snap_length=0.5, floor_max_angle=60°
- **FR-002**: Vehicle collision: CapsuleShape3D (radius=0.8, height=0.0 → total 1.6m), rotated PI/2 on X to lie along Z, center y=0.8
- **FR-003**: Engine params: max_speed=18 m/s, max_reverse=8 m/s, accel=10, brake_force=18, engine_brake=4
- **FR-004**: Steering: turn_rate=3.0, min_turn_speed=2.0, bell-curve speed_factor (peak 0.7 at 5 m/s, 0.3 at max speed)
- **FR-005**: Throttle < 0 when moving forward acts as brake first, then reverse
- **FR-006**: Gravity: 14.0 m/s² when not on floor (heavier than standard for car feel)
- **FR-007**: Collision response: sum slide collision normals, project velocity, reduce speed by impact_strength (0.3-0.95), apply 1.5 m/s pushback
- **FR-008**: Vehicle MUST sync player position and yaw every physics frame while driven
- **FR-009**: Vehicle MUST be in group "vehicle" for discovery
- **FR-010**: Enter radius: 5m, exit offset: 2.5m behind vehicle
- **FR-011**: 7 Quaternius car models: NormalCar1, NormalCar2, SportsCar, SportsCar2, SUV, Taxi, Cop
- **FR-012**: Box-mesh fallback if FBX load fails (body + cabin + windshield + 4 wheels + lights)
- **FR-013**: 11 pre-placed vehicles across downtown, slums, industrial, suburbs
- **FR-014**: Vehicle MUST NOT be driven by AI when is_driven=false (engine brake decelerates to 0)

### Key Entities

- **Vehicle**: CharacterBody3D with car_model, yaw, speed, is_driven, _wheel_nodes, _front_wheel_pivots
- **VehicleData**: Static class mapping model names to FBX paths, providing spawn positions

## Success Criteria

- **SC-001**: Car accelerates smoothly from 0 to max_speed
- **SC-002**: Steering feels responsive at city speeds (5-10 m/s) but stable at high speed
- **SC-003**: Car can drive over sidewalks (5cm collision + floor_snap)
- **SC-004**: Collision with buildings reduces speed (no infinite-push against wall)
- **SC-005**: Enter/exit works within 5m radius, player placed safely behind car on exit

## Assumptions

- Vehicle physics use CharacterBody3D.move_and_slide() (no RigidBody3D)
- Wheel visual animation only works for box-mesh fallback (FBX steering disabled due to mesh offset)
- Body roll/pitch animation is visual-only (does not affect physics)
- camera_yaw is separate from yaw to allow independent camera orbit while driving
