# Walkthrough: First .exe Build

Step-by-step guide for building the first native `.exe` of Unemployment Simulator 3D on your local Windows machine.

The sandbox where the AI develops doesn't have Rust installed, so the actual `cargo tauri build` must be run by you locally. Everything else (Tauri config, frontend static-export setup, auto-updater integration) is already committed in the repo.

---

## Step 1: Install Prerequisites (one-time, ~15 minutes)

### 1.1 Install Rust

Go to https://rustup.rs and download `rustup-init.exe`. Run it, accept the defaults.

Verify in a new PowerShell window:
```powershell
rustc --version
cargo --version
```

### 1.2 Install Visual Studio Build Tools

Download from: https://visualstudio.microsoft.com/visual-cpp-build-tools/

In the installer, select the **"Desktop development with C++"** workload. This gives you the MSVC compiler that Rust needs on Windows.

### 1.3 Install WebView2 (if Windows 10)

Windows 11 has it preinstalled. On Windows 10, download the Evergreen Bootstrapper from:
https://developer.microsoft.com/microsoft-edge/webview2/

### 1.4 Install Tauri CLI

```powershell
cargo install tauri-cli --version "^2.0"
cargo tauri --version
```

---

## Step 2: Clone the Repo

```powershell
git clone https://github.com/buttergolemcode/unemploymentsimulator.git
cd unemploymentsimulator
```

---

## Step 3: Build the .exe

### 3.1 Install frontend dependencies

```powershell
bun install
```

### 3.2 Build the static frontend

```powershell
bun run build:static
```

This runs `TAURI_BUILD=1 next build`, producing `out/` (a static HTML/JS/CSS folder).

### 3.3 Build the Tauri .exe

```powershell
bun run tauri:build
```

This will:
1. Run `bun run build:static` again (just to be safe)
2. Compile the Rust binary in `src-tauri/` (first build takes ~5 minutes — Rust is slow the first time)
3. Bundle the .exe + frontend into an installer

**First-run warning:** Windows may show "Windows protected your PC" because the binary is unsigned. Click **More info → Run anyway**.

### 3.4 Find your installer

After a successful build, look in:

```
src-tauri/target/release/bundle/nsis/UnemploymentSimulator_0.1.0_x64-setup.exe
```

There's also an `.msi` installer in `src-tauri/target/release/bundle/msi/` if you prefer that format.

### 3.5 Test it

Double-click the installer. It should:
1. Show a setup wizard
2. Install to `C:\Users\YOUR_NAME\AppData\Local\unemployment-simulator\`
3. Create a desktop shortcut
4. Launch the game

You should see the game open in a native window (not a browser tab). Try playing — movement, entering buildings, etc. should all work.

---

## Step 4: Publish the First Release

### 4.1 Create a GitHub Release

1. Go to https://github.com/buttergolemcode/unemploymentsimulator/releases/new
2. **Tag:** `v0.1.0` (click "Choose a tag" → type `v0.1.0` → click "Create new tag: v0.1.0 on publish")
3. **Release title:** `v0.1.0 — First Tauri Build`
4. **Description:** Something like:
   ```
   First native .exe build of Unemployment Simulator 3D.
   
   Features:
   - 3D city with 4 districts (Downtown, Harbor, Slums, Industrial)
   - First-person camera with pointer lock
   - 8 schemes to make money
   - Day/night cycle (12 min = 24 in-game hours)
   - Random rain weather
   - Building collision
   
   Known issues:
   - Unsigned binary — Windows SmartScreen will warn. Click "More info → Run anyway".
   ```

### 4.2 Upload the installer as an asset

Drag-and-drop these files into the release:
- `src-tauri/target/release/bundle/nsis/UnemploymentSimulator_0.1.0_x64-setup.exe`
- `src-tauri/target/release/bundle/nsis/UnemploymentSimulator_0.1.0_x64-setup.exe.sig` (if it exists; may be empty)

### 4.3 Create and upload `latest.json`

Copy `src-tauri/latest.json.template` to `latest.json` locally, then edit:

```json
{
  "version": "0.1.0",
  "notes": "First Tauri build. Initial vertical slice with city + 8 schemes.",
  "pub_date": "2026-06-22T12:00:00Z",
  "platforms": {
    "windows-x86_64": {
      "signature": "",
      "url": "https://github.com/buttergolemcode/unemploymentsimulator/releases/download/v0.1.0/UnemploymentSimulator_0.1.0_x64-setup.exe"
    }
  }
}
```

Upload `latest.json` to the same release.

### 4.4 Publish the release

Click **Publish release**.

---

## Step 5: Test the Auto-Updater

To verify the updater works, you need to publish a second version:

1. Edit `src-tauri/tauri.conf.json` → bump `"version": "0.1.0"` to `"0.1.1"`
2. Make a tiny change (e.g. add a log line somewhere visible)
3. Commit + push
4. Build a new .exe: `bun run tauri:build`
5. Create a new GitHub Release `v0.1.1` with the new installer + updated `latest.json` (bump version + URL)
6. Reinstall the old `v0.1.0` build on your machine
7. Launch it

Expected behavior:
- Game starts
- After a few seconds, an "Update available — v0.1.1" dialog appears
- Click "Download & Install"
- Progress bar fills
- App restarts with v0.1.1

---

## Troubleshooting

### Build fails with "link.exe not found"

You haven't installed Visual Studio Build Tools. Go back to Step 1.2.

### Build fails with "WebView2 not found"

Install WebView2 from Step 1.3.

### Tauri CLI not found after install

Close your terminal, open a new one, try again. The PATH needs to refresh.

### `bun: command not found`

Install Bun from https://bun.sh

### Game opens but shows a white screen

Open DevTools in the Tauri window (in dev mode it opens automatically; in release use F12 or right-click → Inspect). Check the console for errors. Most likely a static-export path issue — check `next.config.ts` has `trailingSlash: true` for Tauri builds.

### Auto-updater never fires

Verify in order:
1. `latest.json` is uploaded to the GitHub Release
2. The URL in `tauri.conf.json` points to the correct repo
3. The `version` field in `latest.json` is **higher** than the installed version
4. The `url` field in `latest.json` points to a downloadable .exe (test in browser — should download, not 404)
5. The Tauri app has the updater plugin registered (check `src-tauri/src/lib.rs` has `.plugin(tauri_plugin_updater::Builder::new().build())`)

### SmartScreen warning every launch

This is expected for unsigned binaries. Users click "More info → Run anyway" once per version. To suppress for future versions, you'd need to code-sign (costs ~$200/year for a cert). Not worth it for a private project.

---

## Next Steps

After the first build works:
1. Continue with **Sprint C (Vehicles & Driving)** — now you can develop with `@react-three/rapier` physics, and test in Tauri natively (`bun run tauri:dev`) for accurate perf
2. For each new feature: develop in browser (`bun run dev`) for fast HMR, then verify in Tauri (`bun run tauri:dev`) before release
3. When ready to release: bump version, build, push to GitHub Releases — your friends get the update automatically

See `MASTERPLAN.md` for the full roadmap.
