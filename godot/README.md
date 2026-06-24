# Unemployment Simulator 3D — Godot 4 Edition

A satirical open-world game where you hustle your way from broke to millionaire via 8 shady schemes. Don't get arrested. Don't end up at McDonald's.

## Quick Start

### 1. Download Godot 4

Go to https://godotengine.org/download/ and download **Godot 4.x** (Standard version is fine, .NET not required).

Godot is portable — no installation needed. Just extract and run.

### 2. Clone the repo

```bash
git clone https://github.com/buttergolemcode/unemploymentsimulator.git
cd unemploymentsimulator/godot
```

### 3. Open the project

1. Start Godot
2. Click **"Import"**
3. Select `godot/project.godot` from the cloned repo
4. Click **"Import & Edit"**

### 4. Run the game

Press **F5** (or click the play button). The game starts at the main menu.

### 5. Export as .exe

1. **Project → Export**
2. Click **"Add..."** → **Windows Desktop**
3. Click **"Export Project"**
4. Save as `UnemploymentSimulator.exe`
5. Done — you have a standalone .exe

## Controls

| Key | Action |
|---|---|
| WASD | Walk |
| Mouse | Look around |
| E | Enter building |
| F | Enter/exit vehicle |
| V | Toggle 1st/3rd person |
| B | End day |
| Shift | Sprint |
| Esc | Release mouse |

## Project Structure

```
godot/
├── project.godot          # Godot project config
├── icon.svg               # App icon
├── .gitignore
├── scenes/
│   ├── MainMenu.tscn      # Main menu scene
│   ├── GameScene.tscn     # Main game scene (player + world + HUD)
│   └── EndScreen.tscn     # Win/lose screen
├── scripts/
│   ├── GameManager.gd     # Autoload singleton — game state, schemes, events
│   ├── SchemeData.gd      # All 8 schemes with actions
│   ├── EventData.gd       # Random events with branching choices
│   ├── PlayerController.gd # First-person movement, interaction, vehicles
│   ├── GameScene.gd       # Scene setup, buildings, day/night cycle
│   ├── HUD.gd             # In-game HUD overlay
│   ├── MainMenu.gd        # Menu logic
│   └── EndScreen.gd       # End screen logic
├── assets/
│   ├── models/            # GLB/FBX 3D models (CC0 assets go here)
│   ├── textures/          # Textures
│   ├── sounds/            # Audio files
│   └── fonts/             # Custom fonts
└── ui/                    # UI scenes
```

## Game Design

See `../MASTERPLAN.md` for the full game vision, sprint roadmap, and feature plans.

## Tech Stack

- **Engine:** Godot 4.x (GDScript)
- **Version Control:** Git + GitHub
- **Assets:** CC0 open-source (Kenney, Quaternius, KayKit, Poly Pizza)
- **Export:** One-click Windows .exe (no Tauri, no build pipeline needed)
