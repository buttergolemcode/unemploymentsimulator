# Feature Specification: Scheme System (8 Money-Making Schemes)

**Feature Branch**: `002-scheme-system`

**Created**: 2026-06-27

**Status**: Implemented (retroactive spec)

## User Scenarios & Testing

### User Story 1 - Perform a Scheme Action (Priority: P1)

Player walks to a scheme building (e.g., Trading Floor), presses E, sees the action panel with available actions, clicks "Run" on an action, and observes money/heat/XP changes in the HUD log.

**Why this priority**: Scheme actions are the core gameplay loop — without them, the player cannot earn money.

**Independent Test**: Walk to any building → press E → click Run → verify money changes and log entry appears.

**Acceptance Scenarios**:
1. **Given** player is near Trading Floor with 3 actions left, **When** player presses E then clicks "Run" on "Yolo on Meme Stock", **Then** money changes by +/- amount, actions decrease by 1, and a colored log entry appears.
2. **Given** player has 0 actions left, **When** player opens action panel, **Then** all Run buttons are disabled.

### User Story 2 - Tax Fraud Setup Gate (Priority: P2)

Player must perform "Set Up Fake Tax Return Scheme" (costs 3 actions, $300) before "Harvest Tax Refund" becomes available.

**Acceptance Scenarios**:
1. **Given** tax_setup is false, **When** player opens Accountant Office panel, **Then** "Harvest Tax Refund" shows "(Set up first)" and Run is disabled.
2. **Given** player runs "Set Up Fake Tax Return Scheme", **Then** tax_setup becomes true and "Harvest Tax Refund" becomes available.

### User Story 3 - Action Cost System (Priority: P1)

Each scheme action costs 1-3 actions from the player's daily budget of 3. The system prevents running actions that cost more than remaining actions.

**Acceptance Scenarios**:
1. **Given** player has 1 action left, **When** player tries to run a 2-cost action, **Then** Run button is disabled and message shows "Not enough actions".
2. **Given** player has 3 actions and runs a 3-cost action, **Then** actions_left becomes 0 and day auto-ends.

### User Story 4 - Risk/Reward Outcomes (Priority: P1)

Each action has chance-based success/failure outcomes. Success grants money + XP; failure may lose money + add heat. Skill level scales rewards.

**Acceptance Scenarios**:
1. **Given** ecom skill is level 5, **When** player runs "Flip Thrift Finds" (base profit 40-180 × skill), **Then** profit is 200-900 (40-180 × 5).
2. **Given** player runs "Arm-Rob a Corner Store" with 35% fail chance, **When** failure occurs, **Then** heat +50, money +0, XP +4.

## Requirements

### Functional Requirements

- **FR-001**: System MUST define 8 schemes: ecom, trading, gambling, drugs, scam, robbery, taxfraud, wirefraud
- **FR-002**: System MUST define 22 total actions across all schemes (2-3 per scheme)
- **FR-003**: Each action MUST have: id, label, description, cost (1-3 actions)
- **FR-004**: Each action MUST have chance-based outcomes with money_delta, heat_delta, rep_delta, xp_gain
- **FR-005**: Action rewards MUST scale with skill level (profit × skill)
- **FR-006**: System MUST gate taxfraud actions: setup_tax_fraud required before harvest_refund
- **FR-007**: System MUST disable Run button when: not available OR actions_left < cost
- **FR-008**: System MUST dispatch to correct handler via match on scheme_id + "_" + action_id
- **FR-009**: System MUST return result dict with: success, money_delta, heat_delta, rep_delta, xp_gain, cost, log_text, log_type, optional tax_setup flag
- **FR-010**: Each scheme MUST have a heat_risk label (low/medium/high/extreme) and reward_range string

### Key Entities

- **SchemeData**: Static class providing get_all_schemes(), get_scheme(id), get_actions(id), get_action(id, action_id), is_action_available(gm, scheme_id, action_id), perform_action(gm, scheme_id, action_id)
- **Scheme**: {id, name, emoji, description, heat_risk, reward_range}
- **Action**: {id, label, description, cost}

## Success Criteria

- **SC-001**: All 22 actions produce valid results (money/heat/rep/xp changes)
- **SC-002**: Skill scaling works correctly (level 5 = 5× base reward)
- **SC-003**: Tax fraud gating works (setup required before harvest)
- **SC-004**: Action costs correctly decrement actions_left
- **SC-005**: Heat risk labels match actual heat deltas in outcomes

## Assumptions

- SchemeData is a static class (class_name SchemeData, extends RefCounted) — no instance needed
- All action handlers are static functions with no lambdas (GDScript compatibility)
- Random outcomes use GameManager.rand_int() and GameManager.chance() for deterministic testability
