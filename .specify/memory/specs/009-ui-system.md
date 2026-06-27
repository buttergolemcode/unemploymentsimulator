# Feature Specification: UI System (HUD, Panels, Menus)

**Feature Branch**: `009-ui-system`

**Created**: 2026-06-27

**Status**: Implemented (retroactive spec)

## User Scenarios & Testing

### User Story 1 - HUD Stats Bar (Priority: P1)

Top-left HUD shows: Cash, Heat, Day, Actions, Reputation. Heat color changes based on level (green/yellow/orange/red). Actions display updates when actions are used.

**Acceptance Scenarios**:
1. **Given** game starts, **Then** HUD shows "$500", "0/100" (green), "1", "3/3", "0/100".
2. **Given** heat reaches 80, **Then** heat label turns red.
3. **Given** player uses 1 action, **Then** actions display changes to "2/3" and end-day button shows "Sleep Early" (disabled).

### User Story 2 - Building Action Panel (Priority: P1)

Player presses E near a building. A modal panel appears with scheme name/emoji, description, skill level + XP, heat risk, and action cards. Each card has label, description, cost, and a Run button.

**Acceptance Scenarios**:
1. **Given** player presses E near Trading Floor, **Then** panel appears with "📈 Trading Floor", description, "Skill: Lv.1 (0/100 XP) — LOW HEAT", and 3 action cards.
2. **Given** action costs 2 but player has 1 action, **Then** Run button is disabled on that card.
3. **Given** player clicks Run on an available action, **Then** action executes, panel refreshes (updated skills/XP/actions), or closes if game ended.

### User Story 3 - Event Modal (Priority: P1)

When a random event triggers, a modal appears with event title, description, and choice buttons. Modal blocks all underlying input.

**Acceptance Scenarios**:
1. **Given** event triggers, **Then** modal appears with "📰 [Event Title]", description, and 2-3 choice buttons.
2. **Given** event modal is visible, **When** player tries to move/interact, **Then** all input is blocked (set_input_as_handled).
3. **Given** player clicks a choice, **Then** event resolves, modal hides, game continues.

### User Story 4 - End Day with Confirmation (Priority: P2)

Player can end the day early via the End Day button. If actions remain, a confirmation dialog appears. If no actions remain, day ends immediately.

**Acceptance Scenarios**:
1. **Given** player has 2 actions left, **When** player clicks "Sleep Early", **Then** ConfirmationDialog appears "End the day early?".
2. **Given** player has 0 actions, **When** end-day button shows "End Day" (enabled), **Then** clicking it ends day immediately.

### User Story 5 - End Screen (Priority: P2)

Game over screen shows win/lose title (green/red), flavor text based on lose reason, and final stats (Cash, Days Survived, Total Earned, Deals Closed).

**Acceptance Scenarios**:
1. **Given** player wins ($1M), **Then** end screen shows "YOU MADE IT" (green) + "$1,000,000 in the bank. No job. No boss."
2. **Given** player loses (arrested), **Then** end screen shows "GAME OVER" (red) + "Federal agents kicked your door in at 4 AM."

## Requirements

### Functional Requirements

- **FR-001**: All UI MUST be built procedurally in code (no .tscn for HUD/panels/modals)
- **FR-002**: HUD: HBoxContainer top-left with 5 stat pairs (name: value), ScrollContainer log bottom-left (450×180, max 30 entries)
- **FR-003**: Heat color thresholds: <25 green, <50 yellow, <80 orange, >=80 red
- **FR-004**: Log colors: money=#4ade80, danger=#ef4444, heat=#fb923c, event=#a855f7, success=#22c55e, info=#94a3b8
- **FR-005**: Log entries: "[D{day}] {text}" format, autowrap WORD_SMART
- **FR-006**: Building action panel: dark overlay (0.7 alpha) + centered panel (650px wide) with styled border
- **FR-007**: Action cards: Panel with HBoxContainer (info VBox + Run Button), availability check, cost display
- **FR-008**: Panel refresh: after action, rebuild action cards with updated skill/XP/actions
- **FR-009**: Esc closes building panel + recaptures mouse
- **FR-010**: Event modal: dark overlay (0.7 alpha) + centered panel (550px wide), purple border
- **FR-011**: Event modal MUST block all input via _unhandled_input + set_input_as_handled
- **FR-012**: End day button: bottom-center, disabled when 0 < actions_left < max, shows "Sleep Early" when actions remain
- **FR-013**: ConfirmationDialog for early end-day
- **FR-014**: Main menu: Title + Subtitle + Start/Quit buttons + controls hint
- **FR-015**: End screen: Title (color-coded), flavor text (per lose reason), stats, Restart/Quit buttons
- **FR-016**: Scene transitions: menu→game (start), game→end (win/lose), end→menu (restart)
- **FR-017**: HUD connects to GameManager signals on _ready()

## Success Criteria

- **SC-001**: HUD updates in real-time when money/heat/day/actions/rep change
- **SC-002**: Action panel correctly shows/hides action availability
- **SC-003**: Event modal blocks all game input while visible
- **SC-004**: End screen shows correct title, flavor text, and stats per win/lose reason
- **SC-005**: All UI is code-built (no .tscn dependencies for HUD/panels)

## Assumptions

- HUD is a CanvasLayer child of GameScene (added in .tscn)
- BuildingActionPanel and EventModal are Control nodes added at runtime by GameScene._create_ui()
- MainMenu.tscn and EndScreen.tscn are simple .tscn files with VBoxContainer + buttons (connections via .tscn)
