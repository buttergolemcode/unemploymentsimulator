# Unemployment Simulator 3D — Master Plan

This document captures the agreed-upon vision and the sprint roadmap. Update it whenever scope changes.

---

## Game Vision (locked in 2026-06-21)

### Core Identity
- **PvP-rivalry** at the core, with **optional cooperation** (2v2 possible at 4 players), wrapped in **story elements**
- **Sandboxy** — typical session 1-3h, but players can stay longer if they want
- Vibe: **GTA meets Breaking Bad meets Scarface**, with Saints/Yakuza humor

### Top 3 Priorities for v1.0
1. **Big, alive city with atmosphere** — multiple districts, NPCs, weather, day/night
2. **Vehicles + driving** — full palette (car, motorcycle, van, boat), tuning/garage, smuggling missions, police chases
3. **Native .exe** — must run as standalone game, not just browser

### Feature Scope (planned)

#### Gameplay
- **Minigames per scheme**: real roulette, trading chart, hack-minigames, lockpicking, driving missions, interrogations, plus simple button-press where it fits
- **Drug buff/debuff system**: consumable drugs give temporary buffs (alcohol=casino, amphetamine=trading, cocaine=negotiation, marijuana=heat-decay, heroin=big buff with addiction risk). Side effects: addiction → withdrawal debuff, overdose risk, public consumption raises suspicion
- **Weapons & robbery overhaul**:
  - Robbing stores requires a weapon (real or fake)
  - Real weapons from dealers (expensive, reliable)
  - Fake weapons (cheap, can fail — misfire, target notices, alarm)
  - Pickpocketing = only no-weapon robbery option (cash only, small amounts, high heat per attempt)
  - Weapon type affects: damage, noise (heat), recognition (suspicion)
- **Properties system**: apartments, warehouses, garages, safehouses — save points + passive bonuses
- **Build businesses**: own casino, drug lab, shop — passive income + upgrades
- **Inventory system**: physical items (weapons, drugs, tools) with carry limit, storage, sale
- **Skill tree**: perks — better deals, faster hacking, more stamina
- **Dynamic economy**: prices react to player behavior, stock market speculation
- **Crew / gang hierarchy**: recruit NPCs, assign missions, manage loyalty

#### Police System (complex)
- **Suspicion Counter** (replaces simple Heat): rises with crime, decays over time/cover
- **Bribery thresholds**:
  - Low suspicion → bribery works fine
  - Medium suspicion → bribery more expensive, NPCs hesitant, some refuse
  - High suspicion → bribery useless ("under integrity investigation")
- **Police raids on known properties**: high suspicion → cops raid apartments/warehouses/casinos, confiscate cash/items
- **Insider loyalty system**:
  - Recruit insiders in cops/courts/justice (costs money + time)
  - Loyalty level affects: how early raid warnings come, reliability of info, betrayal risk
  - **Early warning**: loyal insider tips you off hours before raid → can move assets (cash to friend, drugs to stash, weapons dumped)
  - **Betrayal**: underpaid/pressured insider can give false info or actively sell you out
- **Snitches**: NPCs can become snitches, feed info to cops about your operations

#### Win Conditions — Game Mode Selection (before session start)
1. **Kingpin mode** (classic): reach $1M (or other amount) → win
2. **Turf War mode**: crew vs crew — control X% of districts → win
3. **Survival mode**: survive Y days without bankruptcy/arrest → win
4. **Story mode**: multi-stage milestones (survive → crew → empire → boss) → win
5. **Sandbox mode**: no win condition, free play
6. **Exit mode**: once X money reached, can "exit" (flee country) — or keep playing
- Mode determines: starting cash, day limit, NPC density, police aggressiveness, which schemes are active

#### Lawyer System (optional, later)
- Hire lawyers for: negotiations, delaying proceedings, suppressing evidence, intimidating witnesses
- Quality tiers (Public Defender → Top Attorney)
- Cost-benefit: expensive lawyer reduces conviction chance, but at high suspicion even best lawyer is powerless

#### Multiplayer Communication (two-channel)
1. **Proximity Voice Chat** — native (Rust-side), positional audio, distance-based volume
2. **In-Game Phone**:
   - Text chat with contacts (crew, friendly NPCs, other players)
   - Calls (voice calls) for secret scheming outside proximity range
   - Phone also for: mission calls, news updates, bribery requests, SMS from snitches
   - UI: phone icon bottom corner, click opens phone interface

#### World
- **Multiple districts**: Downtown, Slums, Harbor, Industrial — different vibes, NPCs, deals
- **Walkable interiors**: when entering buildings, actually walk inside (not just menu overlay)
- **Destructible environment**: vehicles damageable, buildings take damage, bullet holes persist
- **Day/night cycle**: already implemented (90s cycle)
- **Weather**: rain (particles, wet streets, reduced visibility), dynamic fog, clear sky, night-neon atmosphere

#### Player Customization
- **Full character creator**: body type, face, hair, skin color, voice
- **Outfit system**: clothes, accessories — bought at stores
- **Skill tree**: perks across all schemes

### Graphics Style
- **Low-poly stylized** (current aesthetic) — colorful blocks, flat textures, performant

### References
- GTA series, Breaking Bad, Scarface / King of New York, Saints Row / Yakuza

---

## Sprint Roadmap

### Sprint A — City & Atmosphere (current)
- Districts: Downtown / Slums / Harbor / Industrial with distinct building styles
- NPCs: pedestrians with spawn/walk/despawn, merchant NPCs at fixed locations
- Weather: rain particles, wet streets, dynamic fog
- District lighting: Slums darker, Harbor foggy, etc.

### Sprint B — Native .exe (Tauri) — VORGEZOGEN
- Tauri initialisieren (vor Physik, damit wir nicht doppelt optimieren)
- Next.js Static Export
- Erste lauffähige .exe
- GitHub Repo + Releases für Version Control + Auto-Update
- Code-Signing weglassen (private Projekt, "Trotzdem ausführen" akzeptabel)
- Browser-dev (`bun run dev`) bleibt für schnelle Iteration möglich

### Sprint C — Vehicles & Driving
- `@react-three/rapier` for physics — jetzt nativ in Tauri, GPU-beschleunigt
- First drivable cars (enter/exit, steering, acceleration, collision)
- Load CC0 car models (Quaternius Cars Pack)
- Park cars in world, F to enter, camera switches to driver view

### Sprint D — Police 2.0
- Suspicion system (replaces simple Heat)
- Bribery mechanic with thresholds
- Insider loyalty system
- Raids on properties
- Snitches/betrayal mechanic

### Sprint E — Weapons & Robbery Overhaul
- Weapon dealer system
- Fake vs real weapons
- Pickpocketing vs armed robbery
- Robbery minigame

### Sprint F — Drug Buff/Debuff System
- Consumable items
- Buff effects per scheme
- Addiction/withdrawal mechanic

### Sprint G — Properties & Businesses
- Buy real estate
- Build own businesses
- Storage system

### Sprint H — Game Mode Selection
- Mode selection screen
- Various win conditions
- Mode-dependent configuration

### Sprint I — Multiplayer Prototype
- Server-authoritative game logic
- Proximity voice (native Rust side)
- In-game phone (text + calls)

### Sprint J — Lawyer System (optional)
- Hire lawyers
- Negotiation minigames
- Proceedings mechanic

### Sprint K — Character Creator & Outfits
- Body/face/hair editor
- Buy clothes
- Skill tree

---

## Asset Sources (CC0, see ASSETS_RESEARCH.md for full list)
- **Kenney City Kit** (CC0) — commercial/suburban/industrial/roads modular buildings
- **Quaternius Ultimate Animated Characters** (CC0) — 50+ NPCs × 17 animations
- **Quaternius Cars Pack** (CC0) — drivable vehicles
- **Quaternius Downtown City MegaKit** (CC0) — 300+ modular city pieces
- **KayKit City Builder Bits** (CC0) — street props
- **Pixabay Lo-Fi** (CC0-like) — background music

## Tech Stack
- Next.js 16 + TypeScript + Three.js (@react-three/fiber + @react-three/drei)
- @react-three/rapier for physics (Sprint C, after Tauri)
- Zustand for game state
- Tauri (Rust) for native .exe wrapper (Sprint B — vorgezogen)
- GitHub: Version control + Releases hosting (private repo: buttergolemcode/unemploymentsimulator)
- Future: Rust WebSocket server for multiplayer (Sprint I)

---

## Update & Distribution Strategy

### Version Control: GitHub (private repo)
- Code in privatem GitHub Repo: `buttergolemcode/unemploymentsimulator`
- Jeder Feature-Branch → Pull Request → Merge in `main`
- Tags für Releases (v0.1.0, v0.2.0, etc.)

### Distribution: GitHub Releases
- Jede Version = neuer GitHub Release
- Release enthält: `.exe` Installer + `latest.json` Manifest für Auto-Updater
- Download-URL: `https://github.com/buttergolemcode/unemploymentsimulator/releases/latest/download/...`

### Auto-Updater (Tauri built-in)
- Spiel checkt beim Start das `latest.json` Manifest
- Falls neue Version: Dialog "Update available — Download & Install?"
- User klickt ja → Download im Hintergrund → Spiel startet neu
- Code-Signing weggelassen ("Trotzdem ausführen" im SmartScreen akzeptabel für private Projekt)

### Update-Channel
- `stable` (für normale Spieler / Freunde)
- `beta` (optional, für Tester die neue Features früh wollen)
- `dev` (für dich selbst, lokale Builds)

### Zukünftige Erweiterung: Content-Updates ohne .exe-Rebuild
- Ab Sprint D: Content/Code-Trennung
- Schemes, Events, Items, Missionen als JSON in `/content/`
- Code lädt diese zur Runtime
- Serverseitige Balancing-Tweaks ohne Rebuild möglich
- Noch nicht aktiv — erst wenn nötig
