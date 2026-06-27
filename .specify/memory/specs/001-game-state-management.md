# Feature Specification: Game State Management

**Feature Branch**: `001-game-state-management`

**Created**: 2026-06-27

**Status**: Implemented (retroactive spec)

## User Scenarios & Testing

### User Story 1 - Start a New Game (Priority: P1)

Player clicks "Start Hustling" on the main menu. The game initializes with $500 cash, 0 heat, 0 reputation, day 1, 3 actions, and 8 skills at level 1. The game phase transitions to "playing" and the 3D world loads.

**Why this priority**: Without state initialization, no other feature can function.

**Independent Test**: Start game → verify HUD shows $500, Day 1, 3/3 actions, 0/100 heat, 0/100 rep.

**Acceptance Scenarios**:
1. **Given** the main menu is visible, **When** player clicks "Start Hustling", **Then** game state resets to defaults and 3D scene loads.
2. **Given** a previous game was running, **When** player starts a new game, **Then** all state (money, heat, rep, skills, stats) is zeroed before new game begins.

### User Story 2 - Win the Game (Priority: P1)

Player accumulates $1,000,000 through any combination of schemes. The game immediately transitions to the win screen with "YOU MADE IT" and final stats.

**Why this priority**: The win condition is the primary goal of the game.

**Independent Test**: Use console/debug to set money to $1M → verify win screen appears.

**Acceptance Scenarios**:
1. **Given** player has $999,999, **When** player completes an action earning $1+, **Then** money reaches $1M and phase changes to "won".
2. **Given** phase is "won", **Then** scene transitions to EndScreen.tscn.

### User Story 3 - Lose by Arrest (Priority: P1)

Player's heat reaches 100. The game immediately transitions to the lose screen with "arrested" reason.

**Independent Test**: Set heat to 99 → perform action with heat delta → verify lose screen.

**Acceptance Scenarios**:
1. **Given** heat is 99, **When** player performs an action that adds heat, **Then** heat reaches 100 and phase changes to "lost" with reason "arrested".

### User Story 4 - Lose by Bankruptcy (Priority: P2)

Player's money drops below -$1,000. The game transitions to lose screen with "bankrupt" reason.

**Acceptance Scenarios**:
1. **Given** money is -$900, **When** player loses $200 on a scheme action, **Then** money drops below -$1000 and phase changes to "lost" with reason "bankrupt".

### User Story 5 - Lose by McDonald's (Priority: P2)

Player reaches day 61 with less than $50,000. The game transitions to lose screen with "mcdonalds" reason.

**Acceptance Scenarios**:
1. **Given** day is 60 and money is $30,000, **When** player ends the day, **Then** day becomes 61, money < $50k, and phase changes to "lost" with reason "mcdonalds".

### User Story 6 - Skill Progression (Priority: P2)

Player performs scheme actions and earns XP. At 100 XP, the skill levels up (max level 10), increasing rewards for that scheme.

**Acceptance Scenarios**:
1. **Given** trading skill is level 1 with 90 XP, **When** player earns 15 XP from a trade action, **Then** skill reaches level 2 and log shows "Trading skill reached Level 2!".

### User Story 7 - Day Cycle & Heat Decay (Priority: P2)

Player ends a day (either by using all 3 actions or pressing B). Heat decays by 0-3 points depending on current heat level. Actions reset to 3.

**Acceptance Scenarios**:
1. **Given** heat is 50 and player ends day, **Then** heat decays by 1 (3 - int(50/30) = 3-1 = 2... actually: max(0, 3 - int(50/30)) = max(0, 3-1) = 2) and day increments.
2. **Given** heat is 90 and player ends day, **Then** heat decays by 0 (max(0, 3 - int(90/30)) = max(0, 3-3) = 0).

## Requirements

### Functional Requirements

- **FR-001**: System MUST track money (float), starting at $500.0
- **FR-002**: System MUST track heat (float, 0-100), clamped on overflow
- **FR-003**: System MUST track reputation (float, 0-100), clamped on overflow
- **FR-004**: System MUST track day (int), starting at 1, max 60
- **FR-005**: System MUST track actions_left (int), starting at 3, max 3
- **FR-006**: System MUST track 8 skills (ecom, trading, gambling, drugs, scam, robbery, taxfraud, wirefraud), each level 1-10
- **FR-007**: System MUST track skill_xp per scheme, 0-100 per level
- **FR-008**: System MUST track stats: total_earned, total_lost, deals_closed, days_survived
- **FR-009**: System MUST emit signals on state change (money_changed, heat_changed, day_changed, actions_changed, reputation_changed, phase_changed, log_message, event_triggered)
- **FR-010**: System MUST check win/lose conditions after every action and event resolution
- **FR-011**: System MUST auto-end day when actions_left reaches 0
- **FR-012**: System MUST have 35% chance to trigger a random event at end of day, otherwise advance day directly
- **FR-013**: System MUST decay heat at day advance: max(0, 3 - int(heat/30))
- **FR-014**: System MUST reset all state via _reset_state() before new game
- **FR-015**: System MUST format money as $X, $X.Xk, or $X.XXM depending on magnitude

### Key Entities

- **GameManager**: Autoload singleton holding all game state. Properties: phase, money, day, actions_left, heat, reputation, tax_setup, stats, skills, skill_xp, pending_event, lose_reason.
- **Signal Bus**: 8 signals for loose coupling between GameManager and UI/systems.

## Success Criteria

- **SC-001**: Game state persists correctly across all actions within a session
- **SC-002**: Win/lose conditions trigger reliably at exact thresholds
- **SC-003**: Heat decay formula produces values 0-3 depending on heat level
- **SC-004**: All 8 signals fire correctly when corresponding state changes
- **SC-005**: State reset produces identical initial state every time

## Assumptions

- GameManager is an autoload singleton (registered in project.godot)
- Game state is in-memory only (no save/load persistence yet)
- Signal connections are established by HUD, BuildingActionPanel, EventModal, GameScene on _ready()
