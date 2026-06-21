# Tauri Build Setup — Unemployment Simulator 3D

This folder contains the configuration needed to wrap the Next.js web game as a native Windows `.exe` using Tauri.

## Why Tauri?

- ~10 MB final `.exe` (vs. ~150 MB for Electron)
- Rust backend can later host the multiplayer WebSocket server directly
- Uses WebView2 (already installed on Windows 10/11) — no Chromium bundled
- Full filesystem, native dialogs, system tray, etc. available via Rust

## Prerequisites

1. **Rust** — install from https://rustup.rs
2. **Node.js 20+** + bun (already in this project)
3. **Windows build tools** (if building on Windows):
   - Visual Studio Build Tools 2022 with "Desktop development with C++" workload
   - WebView2 (bundled with Windows 11, separate install on Windows 10)

## Setup Steps

```bash
# 1. Install Tauri CLI globally
cargo install tauri-cli --version "^2.0"

# 2. Initialize Tauri inside the project
cargo tauri init

# When prompted:
# - App name: Unemployment Simulator
# - Window title: Unemployment Simulator 3D
# - Web assets location: ../out  (we'll use Next.js static export)
# - Dev server URL: http://localhost:3000
# - Frontend dev command: bun run dev
# - Frontend build command: bun run build:static

# 3. Add a static-export script to package.json (see below)

# 4. Build the .exe
cargo tauri build
```

## package.json additions

Add this script:

```json
{
  "scripts": {
    "build:static": "next build && cp -r .next/static .next/standalone/.next/ && cp -r public .next/standalone/"
  }
}
```

Also update `next.config.ts` to enable static export:

```ts
const nextConfig = {
  output: 'export',  // for Tauri static build
  // ... existing config
};
```

## tauri.conf.json (template)

```json
{
  "$schema": "https://schema.tauri.app/config/2",
  "productName": "Unemployment Simulator",
  "version": "0.1.0",
  "identifier": "com.unemploymentsim.game",
  "build": {
    "frontendDist": "../out",
    "devUrl": "http://localhost:3000",
    "beforeDevCommand": "bun run dev",
    "beforeBuildCommand": "bun run build:static"
  },
  "app": {
    "windows": [
      {
        "title": "Unemployment Simulator 3D",
        "width": 1280,
        "height": 800,
        "minWidth": 800,
        "minHeight": 600,
        "resizable": true,
        "fullscreen": false
      }
    ],
    "security": {
      "csp": null
    }
  },
  "bundle": {
    "active": true,
    "targets": ["msi", "nsis"],
    "icon": [
      "icons/32x32.png",
      "icons/128x128.png",
      "icons/icon.ico"
    ]
  }
}
```

## Future: Multiplayer Host in Rust

Once Tauri is set up, the Rust backend (`src-tauri/src/main.rs`) can host a WebSocket server for multiplayer. Suggested libraries:

- `tokio-tungstenite` — async WebSocket server
- `serde` + `serde_json` — message serialization

The Next.js frontend would then connect to `ws://localhost:PORT` (or a discovered LAN IP) instead of running locally.

## Notes

- The current project is **singleplayer only**. Multiplayer would require:
  1. Moving all game logic (schemes, events, day-advance) to a Rust server
  2. Defining a client-server protocol (intents → state snapshots)
  3. Adding per-player state (playerId, position, money, heat, etc.)
  4. Lobby system for host/join
- See `../PLAN_MULTIPLAYER.md` (to be written) for the full multiplayer architecture.

## Status

- [x] First-person camera + pointer lock (done)
- [x] Open-world city layout (done)
- [x] Day/night cycle (done)
- [ ] Tauri wrapper initialization (requires Rust install on dev machine)
- [ ] Multiplayer server (future Phase 2)
