# /speckit.remember

> Context refresh skill for long-running development sessions.

## When to Use

Use `/speckit.remember` when:
- A new session starts and context may have been lost
- Before starting work on a new feature or sprint
- After significant changes to verify alignment between specs, inventory, and plan
- When unsure what's been done vs. what's still planned

## What It Does

`/speckit.remember` performs two steps:

### Step 1: Check Game Description

Read `.specify/memory/game-description.md` and verify it exists and is current.

- If the file **does not exist**: Create it based on `MASTERPLAN.md`, `CHANGELOG.md`, and current chat context. Write it in Steam-store-page style (engaging, feature-focused, not technical).
- If the file **exists**: Read it and summarize the current game identity in 2-3 sentences (working title, genre, core loop, current sprint).

Output:
```
## Step 1: Game Description Check

**File**: .specify/memory/game-description.md
**Status**: exists / created
**Summary**: [2-3 sentence summary of game identity]
**Current Sprint**: [e.g., "Sprint D — Assets & Map Polish (In Progress)"]
```

### Step 2: Compare Latest Features vs. Masterplan

1. Read `.specify/memory/inventur_spec.md` and extract the **latest 10 features** (bottom of table, most recently added).
2. Read `MASTERPLAN.md` and extract the **current sprint sub-steps** and their statuses.
3. Compare:
   - Which inventory features map to which masterplan steps?
   - Are there inventory features NOT in the masterplan? (orphaned)
   - Are there masterplan steps NOT in the inventory? (untracked)
4. Output a comparison table:

```
## Step 2: Feature ↔ Masterplan Comparison

### Latest 10 Features (from inventur_spec.md)
| Feature | Spec | Status | Masterplan Step |
|---------|------|--------|-----------------|
| ... | ... | ✅/🔄/⬜ | D.4 / D.5 / — |

### Masterplan Current Sprint (Sprint D)
| Step | Title | Status | In Inventory? |
|------|-------|--------|---------------|
| D.4 | Map Layout | 🔄 | ✅ Yes |
| D.5 | Animations | ⬜ | ✅ Yes (planned) |
| ... | ... | ... | ... |

### Gaps
- **Orphaned features** (in inventory but not in masterplan): [list or "none"]
- **Untracked steps** (in masterplan but not in inventory): [list or "none"]
```

## Usage

```
/speckit.remember
```

No arguments needed. The skill reads existing files and produces the comparison output.

If `$ARGUMENTS` is provided, treat it as a focus area (e.g., "focus on Sprint D" or "focus on vehicle features") and filter the comparison accordingly.

## Output

The skill does NOT modify any files — it only reads and compares. The output is a structured summary that helps the AI (and user) understand:
1. What game we're building (game description)
2. What's been done recently (latest features)
3. What's planned next (masterplan alignment)
4. Where gaps exist (orphaned or untracked items)

## Files Read

- `.specify/memory/game-description.md` (created if missing)
- `.specify/memory/inventur_spec.md`
- `MASTERPLAN.md`

## Files Created (only if missing)

- `.specify/memory/game-description.md` — Steam-style game description
