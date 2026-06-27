# Unemployment Simulator 3D

A satirical open-world game where you hustle your way from broke to millionaire via 8 shady schemes. Don't get arrested. Don't end up at McDonald's.

**Repo:** https://github.com/buttergolemcode/unemploymentsimulator (private)

**Status:** Vertical slice (Sprint A complete). See `MASTERPLAN.md` for the full roadmap.

## Quick Start (Browser Dev)

```bash
bun install
bun run dev
```

Open http://localhost:3000 — the game loads with HMR for fast iteration.

## Build Native .exe (Tauri)

The game can be packaged as a standalone Windows `.exe` via Tauri.

### Prerequisites (one-time setup on your dev machine)

1. **Rust** — install from https://rustup.rs
   ```bash
   rustc --version
   cargo --version
   ```

2. **Tauri CLI** — install via cargo
   ```bash
   cargo install tauri-cli --version "^2.0"
   cargo tauri --version
   ```

3. **Windows Build Tools** (only if building on Windows)
   - Visual Studio Build Tools 2022 with "Desktop development with C++" workload
   - WebView2 (bundled with Windows 11; on Windows 10 install from https://developer.microsoft.com/microsoft-edge/webview2/)

### First-time Build

```bash
# 1. Build the static frontend (Next.js → out/)
bun run build:static

# 2. Build the Tauri .exe
bun run tauri:build
```

Output:
- Installer: `src-tauri/target/release/bundle/msi/UnemploymentSimulator_0.1.0_x64_en-US.msi`
- NSIS installer: `src-tauri/target/release/bundle/nsis/UnemploymentSimulator_0.1.0_x64-setup.exe`
- Standalone exe: `src-tauri/target/release/unemployment-simulator.exe`

### Dev Mode (with Tauri)

For fast iteration with Tauri's native window + dev server:

```bash
bun run tauri:dev
```

This launches the Next.js dev server + opens a native Tauri window pointing at it. HMR works.

## Distribution: GitHub Releases + Auto-Update

See `WALKTHROUGH.md` for the step-by-step guide on:
- Setting up Rust + Tauri CLI
- Building the first .exe
- Publishing a GitHub Release with `latest.json` manifest
- Testing the auto-updater

**Code-signing:** weggelassen (private Projekt, "Trotzdem ausführen" im SmartScreen akzeptabel).

## Project Structure

```
.
├── src/                          # Next.js app (game code)
│   ├── app/                      # App router (page.tsx = main game)
│   ├── components/
│   │   ├── game/                 # Game UI (menu, HUD, dialogs, UpdateDialog)
│   │   └── game3d/               # 3D scene (Three.js / R3F)
│   └── lib/
│       ├── game/                 # Game logic (schemes, events, store)
│       └── updater.ts            # Tauri auto-updater hook
├── src-tauri/                    # Tauri (Rust) wrapper
│   ├── src/
│   │   ├── main.rs               # Binary entry point
│   │   └── lib.rs                # App setup + plugin registration
│   ├── Cargo.toml                # Rust dependencies
│   ├── tauri.conf.json           # Tauri config (window, bundle, updater)
│   ├── build.rs                  # Tauri build script
│   ├── capabilities/default.json # Permission capabilities
│   └── latest.json.template      # Template for auto-update manifest
├── public/                       # Static assets (logo, icons)
├── MASTERPLAN.md                 # Game vision + sprint roadmap
├── WALKTHROUGH.md                # Step-by-step first-build guide
├── ASSETS_RESEARCH.md            # CC0 asset sources
└── package.json
```

## Available Scripts

| Script | Description |
|---|---|
| `bun run dev` | Next.js dev server (browser, HMR) — for fast iteration |
| `bun run build:static` | Build static export to `out/` (for Tauri) |
| `bun run tauri:dev` | Tauri dev mode (native window + dev server) |
| `bun run tauri:build` | Build the .exe installer |
| `bun run lint` | ESLint check |

## Tech Stack

- **Frontend:** Next.js 16 + TypeScript + Tailwind CSS 4 + shadcn/ui
- **3D:** Three.js via @react-three/fiber + @react-three/drei
- **State:** Zustand
- **Native wrapper:** Tauri 2 (Rust)
- **Auto-update:** Tauri built-in updater → GitHub Releases
- **Future:** @react-three/rapier (physics), Rust WebSocket server (multiplayer)

See `MASTERPLAN.md` for the full roadmap (Sprints A-K).
