# Feature Specification: NPC System

**Feature Branch**: `006-npc-system`

**Created**: 2026-06-27

**Status**: Implemented (retroactive spec)

## User Scenarios & Testing

### User Story 1 - Pedestrians Walk the Streets (Priority: P1)

NPCs spawn across all districts and walk to random nearby targets. They avoid streets (stay on sidewalks) and bob slightly while walking. ~121 NPCs total (35 downtown, 30 slums, 18 industrial, 15 harbor, 15 suburbs, 8 rural).

**Acceptance Scenarios**:
1. **Given** game starts, **When** NPCs spawn, **Then** ~121 NPCs are distributed across districts with district-appropriate colors.
2. **Given** NPC reaches its target, **When** _pick_new_target() runs, **Then** NPC picks a new nearby target that is NOT on a street (tries 20 times).

### User Story 2 - NPC Run Over by Vehicle (Priority: P1)

When a vehicle hits an NPC at speed > 3 m/s, the NPC is knocked down for 4 seconds with knockback impulse, then gets back up and resumes walking.

**Acceptance Scenarios**:
1. **Given** NPC is standing and vehicle approaches at 5 m/s within 2.5m, **When** collision check triggers, **Then** NPC enters is_down state for 4s, mesh rotates to -PI/2 (lying down), knockback velocity applied.
2. **Given** NPC is down for 4 seconds, **When** timer expires, **Then** NPC stands back up (mesh.rotation.x = 0), picks new target, resumes walking.

### User Story 3 - Merchants at Fixed Locations (Priority: P2)

Merchant NPCs are placed at fixed positions near scheme buildings. They have a glowing badge sphere on top and do NOT walk (is_merchant = true skips _physics_process movement).

**Acceptance Scenarios**:
1. **Given** game starts, **When** merchants spawn, **Then** 9 merchants appear at fixed positions near scheme buildings with glowing badges.
2. **Given** merchant NPC, **When** _physics_process runs, **Then** function returns immediately (no movement).

### User Story 4 - NPCs Avoid Streets (Priority: P2)

NPCs check if their next position would be on a street. If so, they pick a new target instead. Street buffer is 5.5m from street centerlines.

**Acceptance Scenarios**:
1. **Given** NPC is on a sidewalk and target is across a street, **When** NPC checks next position, **Then** if next position is within 5.5m of a street line, NPC picks a new target instead.
2. **Given** NPC tries 20 times to find a non-street target and fails, **When** fallback triggers, **Then** NPC picks any nearby point (may briefly cross street).

## Requirements

### Functional Requirements

- **FR-001**: NPC MUST be CharacterBody3D with collision_layer=4 (layer 3), collision_mask=1 (ground only)
- **FR-002**: NPC collision: CapsuleShape3D, radius=0.35, height=1.7, center y=0.85
- **FR-003**: NPC MUST load random Quaternius Modular Character FBX (11 models), fallback to capsule+head+hat
- **FR-004**: NPC mesh MUST be rotated PI on Y (to face movement direction)
- **FR-005**: NPC movement: speed=1.5 m/s, facing=atan2(-dx, -dz), walk_phase bob (0.03m amplitude)
- **FR-006**: NPC MUST check _is_on_street(next_x, next_z) before moving — if true, pick new target
- **FR-007**: Street positions: [-300, -200, -100, 0, 100, 200, 300] with 5.5m buffer
- **FR-008**: NPC knockdown: is_down=true, down_timer=4.0s, mesh rotates to -PI/2, knockback 5.0 m/s
- **FR-009**: NPC knockdown triggers when: vehicle within 2.5m AND abs(vehicle.speed) > 3.0
- **FR-010**: Merchant NPCs: is_merchant=true, add_to_group("merchant"), skip movement, glowing badge sphere
- **FR-011**: NPC distribution: 35 downtown, 15 harbor, 30 slums, 18 industrial, 15 suburbs, 8 rural
- **FR-012**: NPC colors per district (downtown: dark grays, slums: browns, harbor: dark, suburbs: light grays)

## Success Criteria

- **SC-001**: NPCs walk on sidewalks, not on streets (mostly)
- **SC-002**: NPCs get knocked down by fast vehicles and recover after 4s
- **SC-003**: Merchants stay at fixed positions with visible badges
- **SC-004**: NPC count is ~121 with correct district distribution
- **SC-005**: NPCs face their movement direction (not backwards)

## Assumptions

- NPCs pass through vehicles (collision_layer/mask separation) — knockdown is handled via distance check in code
- NPC character models have no animations (T-pose) — procedural walk bob is used instead
- Real walk animations planned for Sprint D.5 (Universal Animation Library)
