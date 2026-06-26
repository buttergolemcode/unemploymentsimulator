# Feature Specification: Meta/System (Singleton, Signals, Discovery)

**Feature Branch**: `012-meta-system`

**Created**: 2026-06-27

**Status**: Implemented (retroactive spec)

## User Scenarios & Testing

### User Story 1 - Game State Singleton (Priority: P1)

GameManager is an autoload singleton accessible from any script via `GameManager.<property>`. It holds all game state and provides action/event methods.

**Acceptance Scenarios**:
1. **Given** any script, **When** it accesses GameManager.money, **Then** current money value is returned.
2. **Given** any script, **When** it calls GameManager.perform_action(scheme_id, action_id), **Then** action is executed and result returned.

### User Story 2 - Signal-Based Communication (Priority: P1)

UI components connect to GameManager signals on _ready(). When state changes, signals fire and UI updates automatically. No direct UI calls from GameManager.

**Acceptance Scenarios**:
1. **Given** HUD._ready() connects to money_changed signal, **When** money changes, **Then** _on_money_changed(amount) fires and HUD updates money label.
2. **Given** GameManager.phase_changed.emit("lost"), **Then** GameScene._on_phase_changed("lost") fires and transitions to EndScreen.

### User Story 3 - Group-Based Discovery (Priority: P2)

Runtime objects are discovered via Godot groups: "player", "vehicle", "pedestrian", "merchant", "scheme_building". No hardcoded node paths.

**Acceptance Scenarios**:
1. **Given** Vehicle.gd needs player position, **When** get_tree().get_first_node_in_group("player") is called, **Then** player node is returned.
2. **Given** PlayerController needs nearby buildings, **When** get_tree().get_nodes_in_group("scheme_building") is called, **Then** all 8 scheme building meshes are returned.

### User Story 4 - Meta-Based Building Tagging (Priority: P2)

Scheme buildings are tagged with scheme_id, scheme_name, scheme_emoji via set_meta(). Runtime code retrieves these via get_meta() for interaction.

**Acceptance Scenarios**:
1. **Given** player is near a scheme building mesh, **When** mesh.get_meta("scheme_id") is called, **Then** returns "trading" (or other scheme ID).
2. **Given** player interacts, **When** mesh.get_meta("scheme_name") is called, **Then** returns "Trading Floor" for panel title.

## Requirements

### Functional Requirements

- **FR-001**: GameManager MUST be autoload singleton (registered in project.godot as `GameManager="*res://scripts/GameManager.gd"`)
- **FR-002**: AutoUpdater MUST be autoload singleton (registered as `AutoUpdater="*res://scripts/AutoUpdater.gd"`)
- **FR-003**: 8 signals: money_changed(float), heat_changed(float), day_changed(int), actions_changed(int,int), phase_changed(String), log_message(String,String), reputation_changed(float), event_triggered(Dictionary)
- **FR-004**: _reset_state() zeroes: phase, lose_reason, money, day, actions_left, heat, reputation, tax_setup, stats, skills, skill_xp, pending_event
- **FR-005**: Phase state machine: "menu" → "playing" → "won"/"lost" → "menu" (on reset)
- **FR-006**: Groups: "player" (PlayerController._ready), "vehicle" (Vehicle._ready), "pedestrian"/"merchant" (NPC._ready), "scheme_building" (WorldBuilder._build_scheme_buildings)
- **FR-007**: Meta tags on scheme buildings: scheme_id, scheme_name, scheme_emoji
- **FR-008**: NPC collision separation: collision_layer=4 (layer 3), collision_mask=1 (ground only) — vehicles pass through NPCs
- **FR-009**: SchemeData, EventData, VehicleData, WorldBuilder are class_name static classes (extends RefCounted)
- **FR-010**: Scene transitions via get_tree().change_scene_to_file() on phase_changed

## Success Criteria

- **SC-001**: GameManager accessible from all scripts without node path
- **SC-002**: All 8 signals fire correctly on state changes
- **SC-003**: Group-based discovery finds all runtime objects
- **SC-004**: Meta tags correctly identify scheme buildings
- **SC-005**: NPC/vehicle collision separation works (NPCs don't block vehicles physically)

## Assumptions

- No save/load system (state is in-memory only)
- No scene instancing for UI (all built in code except MainMenu.tscn and EndScreen.tscn)
- Autoloads are registered in project.godot [autoload] section
