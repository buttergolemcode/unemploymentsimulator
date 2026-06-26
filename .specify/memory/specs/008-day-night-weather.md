# Feature Specification: Day/Night Cycle & Weather

**Feature Branch**: `008-day-night-weather`

**Created**: 2026-06-27

**Status**: Implemented (retroactive spec)

## User Scenarios & Testing

### User Story 1 - Day/Night Cycle (Priority: P2)

The game has a 12-minute real-time day/night cycle (720 seconds = 24h). Sun rotates around the scene. Lighting changes through 4 phases: night, dawn, day, dusk. Game starts at noon (t=0.5).

**Acceptance Scenarios**:
1. **Given** game starts, **Then** elapsed_time = 360.0 (noon), sun at zenith, phase = "day".
2. **Given** t = 0.0 (midnight), **Then** phase = "night", sun energy = 0.05, sun color = cold blue.
3. **Given** t = 0.15 (dawn), **Then** phase = "dawn", sun energy = 0.4, sun color = orange.
4. **Given** t = 0.75 (dusk), **Then** phase = "dusk", sun energy = 0.4, sun color = red-orange.

### User Story 2 - Rain Weather System (Priority: P3)

Rain triggers randomly (20-90s after clear, 30-90s during rain). Rain fades in over 4s, rains, then fades out over 4s. Rain particles follow the camera. Cloud overlay appears. Ambient rain light dims.

**Acceptance Scenarios**:
1. **Given** phase = "clear" for 20-90s, **When** timer expires, **Then** phase transitions to "fading_in".
2. **Given** phase = "fading_in", **When** 4s pass, **Then** rain_opacity reaches 1.0, phase transitions to "raining".
3. **Given** phase = "raining" for 30-90s, **When** timer expires, **Then** phase transitions to "fading_out".
4. **Given** phase = "fading_out", **When** 4s pass, **Then** rain_opacity reaches 0.0, phase transitions to "clear".

## Requirements

### Functional Requirements

- **FR-001**: Day/night cycle: CYCLE_SECONDS = 720.0 (12 min = 24h)
- **FR-002**: Sun angle: sun_angle = PI - t * TAU (t = elapsed_time / CYCLE_SECONDS)
- **FR-003**: Game starts at noon: elapsed_time = 360.0 (t = 0.5)
- **FR-004**: 4 phases: night (t<0.08 or t>=0.92), dawn (t<0.20), day (t<0.70), dusk (t<0.83)
- **FR-005**: Sun energy: night=0.05, dawn/dusk=0.4, day=1.2
- **FR-006**: Sun color: night=(0.3,0.4,0.9), dawn=(0.98,0.57,0.23), day=(1,0.97,0.91), dusk=(0.86,0.15,0.08)
- **FR-007**: Weather state machine: clear → fading_in → raining → fading_out → clear
- **FR-008**: Rain: 800 MultiMesh drops, BoxMesh(0.04, 0.6, 0.04), follow camera, recycle at y<0
- **FR-009**: Rain drop speed: 22-34 m/s downward
- **FR-010**: Cloud overlay: 200×200m plane at y=30, dark blue, fades with rain_opacity
- **FR-011**: Ambient rain light: OmniLight3D, cold blue (0.23, 0.31, 0.43), energy = 0.08 × rain_opacity
- **FR-012**: Rain opacity transitions: 4s fade in/out, lerp material alpha
- **FR-013**: Scheduling: clear→rain in 20-60s, rain→clear in 30-90s

## Success Criteria

- **SC-001**: Sun moves continuously across sky over 12 minutes
- **SC-002**: Lighting changes are smooth between phases
- **SC-003**: Rain appears and disappears with fade transitions
- **SC-004**: Rain particles follow camera (always visible during rain)
- **SC-005**: Game always starts at noon (day phase)

## Assumptions

- DirectionalLight3D is in GameScene.tscn (not created by code)
- WorldEnvironment is in GameScene.tscn with fog, ACES tonemap, ambient light
- Weather.gd is added as child of GameScene at runtime (preload + new + add_child)
