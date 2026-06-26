# Feature Specification: Random Event System

**Feature Branch**: `003-random-events`

**Created**: 2026-06-27

**Status**: Implemented (retroactive spec)

## User Scenarios & Testing

### User Story 1 - Trigger Random Event at Day End (Priority: P1)

Player ends a day. There is a 35% chance a random event triggers instead of advancing the day. The event modal appears with title, description, and choice buttons.

**Acceptance Scenarios**:
1. **Given** player ends day and RNG rolls < 0.35, **When** event pool is built, **Then** a random event from the pool is selected and event modal appears.
2. **Given** player ends day and RNG rolls >= 0.35, **When** no event triggers, **Then** day advances normally.

### User Story 2 - Resolve Event Choice (Priority: P1)

Player clicks a choice button on the event modal. The event resolves: money/heat/rep change, log entries appear, and the modal closes. Day then advances.

**Acceptance Scenarios**:
1. **Given** "Police Raid" event is active, **When** player clicks "Lawyer up ($5,000)" and has $5,000+, **Then** money -5000, heat -35, modal closes, day advances.
2. **Given** "Police Raid" event is active, **When** player clicks "Lawyer up" but has <$5,000, **Then** heat only -5 (can't afford retainer), modal closes, day advances.

### User Story 3 - Event Pool Filtering (Priority: P2)

The event pool is built based on current game state. Some events only appear under specific conditions (heat threshold, money threshold, reputation threshold).

**Acceptance Scenarios**:
1. **Given** heat >= 60, **Then** "Police Raid" event is in the pool.
2. **Given** heat < 60, **Then** "Police Raid" event is NOT in the pool.
3. **Given** money < 100, **Then** "McDonald's Is Hiring" event is in the pool.
4. **Given** reputation >= 30, **Then** "A Crew Wants to Hire You" event is in the pool.

### User Story 4 - McDonald's Event Can End Game (Priority: P2)

If player chooses "Take the job" in the McDonald's event, the game immediately ends with lose reason "mcdonalds".

**Acceptance Scenarios**:
1. **Given** "McDonald's Is Hiring" event, **When** player clicks "Take the job. Game over.", **Then** phase changes to "lost" with reason "mcdonalds".

## Requirements

### Functional Requirements

- **FR-001**: System MUST define 8 events: raid, witness, mcdonalds, hot_tip, uncle, crew, mom, mugging
- **FR-002**: Each event MUST have: title, description, choices array (2-3 choices), event_type
- **FR-003**: System MUST build event pool based on: heat >= 60 (raid), heat 35-60 (witness), money < 100 (mcdonalds), reputation >= 30 (crew)
- **FR-004**: 4 events (hot_tip, uncle, mom, mugging) MUST always be in pool
- **FR-005**: System MUST resolve choice via apply_choice(gm, event, choice_index) returning result dict
- **FR-006**: Result dict MUST support: money_delta, heat_delta, rep_delta, log_entries array, optional phase + lose_reason
- **FR-007**: If result contains "phase" key, game ends immediately (win/lose)
- **FR-008**: Event modal MUST block all underlying input while visible
- **FR-009**: After event resolution (if still playing), day MUST advance

### Key Entities

- **EventData**: Static class providing get_random_event(gm), apply_choice(gm, event, choice_index)
- **Event**: {title, description, choices: [{label}], event_type}
- **Event Result**: {money_delta?, heat_delta?, rep_delta?, log_entries?: [{text, type}], phase?, lose_reason?}

## Success Criteria

- **SC-001**: All 8 events trigger only under correct conditions
- **SC-002**: All choice resolutions produce correct money/heat/rep changes
- **SC-003**: McDonald's "take job" choice ends game immediately
- **SC-004**: Event modal blocks input correctly
- **SC-005**: Day advances after event resolution (unless game ended)

## Assumptions

- EventData is a static class (class_name EventData, extends RefCounted)
- 35% event trigger chance is hardcoded in GameManager.end_day()
- Event modal is built procedurally in EventModal.gd (no .tscn dependency)
