# Feature Specification: Auto-Updater

**Feature Branch**: `010-auto-updater`

**Created**: 2026-06-27

**Status**: Implemented (retroactive spec)

## User Scenarios & Testing

### User Story 1 - Check for Updates on Startup (Priority: P3)

When the game starts, AutoUpdater (autoload singleton) fetches version.txt from GitHub Releases. If the fetched version is newer than CURRENT_VERSION, an update dialog appears.

**Acceptance Scenarios**:
1. **Given** game starts with CURRENT_VERSION = "1.0.0", **When** GitHub returns "1.1.0", **Then** update dialog appears: "A new version is available: v1.1.0. You are running v1.0.0."
2. **Given** game starts with CURRENT_VERSION = "1.0.0", **When** GitHub returns "1.0.0", **Then** no dialog appears (versions equal).
3. **Given** HTTPRequest fails, **When** result != SUCCESS or response_code != 200, **Then** no dialog, error printed to console.

## Requirements

### Functional Requirements

- **FR-001**: AutoUpdater MUST be an autoload singleton (registered in project.godot)
- **FR-002**: VERSION_URL: "https://github.com/buttergolemcode/unemploymentsimulator/releases/latest/download/version.txt"
- **FR-003**: CURRENT_VERSION: "1.0.0" (hardcoded)
- **FR-004**: _check_for_updates() runs in _ready()
- **FR-005**: HTTPRequest fetches VERSION_URL, response parsed as UTF-8 string, strip_edges()
- **FR-006**: _is_newer(available, installed): splits by ".", compares each segment numerically
- **FR-007**: If newer: AcceptDialog with title "Update Available", dialog_text showing both versions, ok_button_text "OK"
- **FR-008**: Dialog is non-blocking (popup_centered, user dismisses with OK)

## Success Criteria

- **SC-001**: Version comparison works for all semver cases (1.0.0 < 1.0.1, 1.9.9 < 1.10.0, etc.)
- **SC-002**: Network failure doesn't crash the game
- **SC-003**: Dialog appears only when newer version available

## Assumptions

- Auto-update is notification-only (no auto-download or auto-restart)
- User must manually download from GitHub Releases page
- version.txt is a plain text file with just the version string (e.g., "1.0.0")
