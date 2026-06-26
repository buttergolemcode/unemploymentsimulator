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

## Sprint Roadmap (revised 2026-06-26)

> **Why this order:** Foundation first (engine, world, assets), then systems on top.
> Developing features like Police 2.0 or Minigames on placeholder-box visuals
> means doing the visual integration twice — once on boxes, once on real assets.
> Assets + Map Polish comes BEFORE feature sprints so all later features
> are built on the actual look & feel of the final game.

### Sprint A — City & Atmosphere (PLACEHOLDER) ✅
- Districts: Downtown / Slums / Harbor / Industrial with distinct building styles
- NPCs: pedestrians with spawn/walk/despawn, merchant NPCs at fixed locations
- Weather: rain particles, wet streets, dynamic fog
- District lighting: Slums darker, Harbor foggy, etc.
- **Status:** Box-block placeholder world. Functional but ugly.

### Sprint B — Native .exe (was Tauri, now Godot) ✅
- Pivot to Godot 4.7 (Three.js perf was unusable for an open-world 3D game)
- GDScript rewrite of all 16 scripts (GameManager, Schemes, Events, etc.)
- First runnable .exe via Godot's export templates
- GitHub repo: `buttergolemcode/unemploymentsimulator`
- Simple Auto-Updater (HTTP version check + dialog, opens browser for download)

### Sprint C — Vehicles & Driving (BASIC) ✅
- Custom CharacterBody3D-based vehicle physics (no external physics engine)
- First drivable car (enter/exit F, WASD/Space, third-person chase cam)
- NPCs can be run over (knockdown + recovery state)
- Realistic steering (speed-dependent, no tank-spin, reverse-inverts-steering)
- **Status:** Box-mesh car with placeholder model. Physics done.

### Sprint D — Assets & Map Polish ⬅️ CURRENT
Replace all placeholder boxes with real CC0 assets and design a proper city map.

> **Physics engine decision (locked):** Stay with custom CharacterBody3D.
> VehicleBody3D and Jolt physics plugin are overkill for arcade-style driving.

#### D.0 — Asset download ✅
All 8 CC0 asset packs downloaded to `godot/assets/` (see `godot/assets/README.md`).

#### D.1 — Godot project structure + import config ✅
Asset directory structure established, inventory README in place.

#### D.2 — Vehicle model integration (Quaternius Cars) ✅
Replace box-mesh vehicles with real Quaternius car models. Add wheel-spin, front-wheel steering, body roll/pitch animations. Free-look chase camera.

#### D.3 — NPC model integration (Quaternius Modular Characters) ✅
- Replaced capsule NPCs with 11 real character models (Adventurer, Beach, Casual, Casual2, Farmer, King, Punk, Spacesuit, Suit, Swat, Worker)
- Player uses "Suit" character model in third-person view
- Walk animation: procedural bob + forward lean (real animations pending in D.5)
- Idle/knockdown states preserved
- Fallback to capsule mesh if FBX missing
- Source: Quaternius Ultimate Modular Characters Pack (CC0, FBX format)

#### D.4 — Map layout redesign (functional grid) ✅
NYC-style grid with 1200×1200m playable area, 6 districts, sidewalks with collision,
crosswalks, harbor, rural zone, mountain walls. Functional but uses procedural box
placeholders for buildings/props/trees. Collision works (cars can drive on sidewalks).

**Known Issues (to be fixed in D.4.5 or D.5):**
- Vehicle wheels visually glitch when driving over sidewalk (collision works, visual doesn't follow)
- Buildings are colored BoxMeshes (not real CC0 assets yet)
- Trees, landmarks, harbor props are procedural primitives

#### D.4.5 — Map Design Finish & Asset Styling ⬅️ NEXT
Replace ALL procedural placeholders with styled CC0 assets and finish the complete
map design — including everything outside the big city.

**Asset Integration (replace box placeholders):**
- Buildings: Replace BoxMesh buildings with Kenney GLB modular buildings per district
- Vehicles: Style Quaternius Cars in Blender (custom colors, unique look)
- Characters: Style Quaternius Modular Characters in Blender (custom outfits, proportions)
- Trees: Replace procedural (cylinder+prism) with styled tree models
- Landmarks: Replace box landmarks with styled versions (bridge, fortress, stadium, etc.)
- Harbor: Replace box ships/containers/cranes with styled versions
- Street props: Replace box lamps with KayKit prop models

**Map Design Finish (everything outside big city):**
- Mountains: Real mountain geometry (not just box walls) — visible terrain with peaks/ridges
- Forests: Dense tree coverage in rural/suburb border zones (not just scattered trees)
- Highways: Highway roads connecting city to map edges (with guardrails, signage)
- Rural areas: Farms, barns, fields, dirt roads — not just empty green hills
- Coastline: Beach/shore where land meets water (not just a hard edge)
- District borders: Natural transitions (rivers, parks, elevation changes) between districts
- Suburbs: Residential streets with houses, gardens, fences — not just city-grid extension
- Slums: Dense narrow alleyways, not just smaller buildings on the same grid

**Style Guide (unique game look, not raw CC0):**
- Define a cohesive color palette (desaturated, slightly gritty, neon accents at night)
- Material treatment: flat colors with subtle roughness variation (not realistic PBR)
- Vehicle style: matte paint, slightly夸张 proportions (arcade feel)
- Character style: slightly stylized proportions (bigger heads, shorter limbs — Saints Row vibe)
- Building style: flat facades with bold color blocks, minimal texture detail
- Overall: "Low-poly stylized with attitude" — not generic CC0, not realistic

**Acceptance:**
- [ ] No procedural box placeholders visible anywhere in the world
- [ ] All buildings use styled CC0 models (Kenney base, custom materials)
- [ ] Mountains are real terrain (not box walls)
- [ ] Forests are dense and visible from city edge
- [ ] Rural area has farms/barns/fields (not empty hills)
- [ ] Coastline has beach/shore transition
- [ ] District borders feel natural (not hard polygon edges)
- [ ] Suburbs look residential (gardens, fences, houses)
- [ ] Slums have narrow alleyways (not just smaller grid buildings)
- [ ] Vehicle/character models have unique style (not raw CC0)
- [ ] Color palette is cohesive across all assets
- [ ] Map feels like a real city with surroundings, not a grid on flat ground

#### D.5 — Animations (NPCs, vehicles, player) ⬅️ AFTER MAP DESIGN FINISH
Add real animations to replace current procedural hacks. Builds on D.4.5 styled models.

**NPC animations:**
- Get Quaternius Universal Animation Library (CC0) — currently blocked by itch.io purchase flow, user may need to download manually
- Set up shared AnimationLibrary across all character models
- Animations needed: idle, walk, run, talk, knocked-down, get-up
- Replace procedural walk bob + forward lean with real walk animation
- Add idle animation when NPC reaches target
- Add 'scream'/fall animation on vehicle knockdown

**Vehicle animations:**
- Wheel spin (rotate_x) — currently disabled for FBX models because it conflicts with baked orientation
- Solution: Reparent wheel meshes into spin-pivot Node3Ds (similar to steer-pivot approach)
- Then: front wheels have BOTH a steer-pivot (Y) AND a spin-pivot (X) as parent chain
- Spin rate based on vehicle speed (visual feedback)
- Body roll/pitch already done — keep

**Player animations:**
- Walk, run, idle, enter-vehicle, exit-vehicle
- Third-person view should show these animations
- First-person: only arm/hand animations if any (optional)

**Acceptance:**
- NPCs visibly walk (legs moving) instead of just bobbing
- Car wheels visibly spin when car is moving
- Player has walk/run animation in third-person

#### D.6 — Building system overhaul (Kenney City Kit)
- Build a **MeshLibrary** from Kenney modular building parts
- Create a `BuildingGenerator.gd` that assembles buildings from modular parts:
  - Pick base tile (1×1, 2×2, 4×4 footprint)
  - Stack N floors (per district height range)
  - Add roof variation (flat, pitched, with AC units)
- Replace `_build_scheme_buildings()` to use real buildings per scheme type:
  - Trading Floor → tall commercial tower
  - Trap House → small suburban house
  - Casino → ornate downtown building
  - etc.
- Replace `_build_filler_buildings()` to use modular commercial/suburban/industrial parts
- Buildings placed WITHIN the district polygons defined in D.4
- Districts have **distinct visual identity**:
  - Downtown: tall commercial towers, glass facades
  - Harbor: low industrial warehouses + cranes
  - Slums: rundown suburban houses, boarded windows
  - Industrial: factories, silos, pipes
  - Suburbs: clean single-family homes, gardens
  - Rural: farmhouses, barns, fields

#### D.7 — Road network redesign (Kenney Roads + Quaternius Streets)
- Replace current grid-with-asphalt-planes with **modular road tiles**:
  - Straight, curve, T-junction, 4-way intersection
  - With/without sidewalk, with/without crosswalk
- Build a real **road graph** (not just grid) within district polygons:
  - Main avenues (4-lane, with center divider)
  - Side streets (2-lane, residential)
  - Alleyways (1-lane, slums)
  - Highway loops around city
- Add **traffic lights** at major intersections (visual only for now)
- Add **road markings**: lane lines, crosswalks, stop lines
- Snap road tiles to 10m grid for clean layout

#### D.8 — Street props & polish (KayKit + Downtown MegaKit)
- Distribute street props: lamps, benches, hydrants, trash cans, planters
- Add storefront props (Quaternius Downtown MegaKit): awnings, signs, neon
- Add parked cars along streets (using Quaternius Cars, non-drivable instances)
- Add district-specific props:
  - Harbor: cargo containers, cranes, pallets
  - Industrial: pipes, barrels, machinery
  - Slums: graffiti decals, trash piles, broken cars
  - Downtown: planters, art installations, fancy lamps
- Add **decals** for road damage, graffiti, oil stains

#### D.9 — Lighting & atmosphere polish
- Per-district lighting setup:
  - Downtown: warm white street lamps, neon accent
  - Harbor: cold blue, foggy
  - Slums: dim yellow, flickering
  - Industrial: harsh sodium vapor
  - Suburbs: warm residential porch lights
  - Rural: moonlight only
- Skybox: gradient sky with sun position synced to day/night cycle
- Better fog: distance + height fog for depth
- Reflection probes at key intersections (for wet-street look)
- Particle effects: dust in industrial, leaves in suburbs, mist in harbor

#### D.10 — Water shader (harbor)
- Animated water plane with vertex displacement (waves)
- Reflection of sky + nearby buildings
- Foam at shoreline
- Distant fog over water for horizon blend

#### D.11 — Sprint D acceptance test
- [ ] All 8 scheme buildings use styled CC0 models
- [ ] All vehicles use styled Quaternius car models (not boxes)
- [ ] All NPCs use animated character models with real walk animation
- [ ] Player has a styled character model with walk/run animations
- [ ] City has 6 visually distinct districts arranged in logical layout
- [ ] Road network is logically laid out (not random grid)
- [ ] Street props distributed naturally
- [ ] Per-district lighting makes each area feel different
- [ ] Vehicle wheels visibly spin and steer
- [ ] No placeholder boxes visible anywhere in the world
- [ ] Mountains are real terrain (not box walls)
- [ ] Forests, rural areas, coastline are designed (not empty)
- [ ] District borders feel natural (not hard polygon edges)
- [ ] Color palette is cohesive across all assets
- [ ] FPS stays above 60 on target hardware

### Sprint E — Sound & Atmosphere ⬅️ NEXT AFTER D
Build the audio layer that turns the visual world into a "living" world.


- **Background music**: Pixabay Lo-Fi (CC0) — district-specific playlists
- **Ambient SFX**:
  - Traffic hum (downtown)
  - Industrial clanks (industrial)
  - Seagulls + waves (harbor)
  - Crickets + wind (suburbs/rural)
  - Rain + thunder variations (weather)
- **Vehicle SFX**: engine RPM loop, tire screech on sharp turn, crash sound on impact, horn
- **NPC SFX**: idle chatter snippets, footsteps, scream when run over
- **UI SFX**: button clicks, money ka-ching, danger alert, success chime
- **Voice lines** (optional): key NPCs (uncle Louie, mom, merchants) with short barks

### Sprint F — Police 2.0 (was Sprint D)
- Suspicion system (replaces simple Heat)
- Bribery mechanic with thresholds
- Insider loyalty system
- Raids on properties
- Snitches/betrayal mechanic
- **Visuals:** Police car models (from Sprint D assets), police NPC uniforms, arrest animation

### Sprint G — Weapons & Robbery Overhaul (was Sprint E)
- Weapon dealer system
- Fake vs real weapons
- Pickpocketing vs armed robbery
- Robbery minigame
- **Visuals:** Weapon models (CC0 from Kenney/Quaternius), muzzle flash VFX

### Sprint H — Drug Buff/Debuff System (was Sprint F)
- Consumable items
- Buff effects per scheme
- Addiction/withdrawal mechanic
- **Visuals:** Drug item models, screen distortion VFX for high/withdrawal

### Sprint I — Properties & Businesses (was Sprint G)
- Buy real estate
- Build own businesses
- Storage system
- **Visuals:** Interior environments (now that we have real building assets)

### Sprint J — Game Mode Selection (was Sprint H)
- Mode selection screen
- Various win conditions
- Mode-dependent configuration

### Sprint K — Multiplayer Prototype (was Sprint I)
- Server-authoritative game logic
- Proximity voice (native Rust side)
- In-game phone (text + calls)

### Sprint L — Lawyer System (was Sprint J, optional)
- Hire lawyers
- Negotiation minigames
- Proceedings mechanic

### Sprint M — Character Creator & Outfits (was Sprint K)
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

## Tech Stack (updated 2026-06-26)
- **Godot 4.7** (engine) — GDScript, native .exe export
- **No external physics engine** — CharacterBody3D-based vehicle physics (custom)
- **GitHub**: Version control + Releases hosting (private repo: buttergolemcode/unemploymentsimulator)
- **Future (Sprint K)**: Rust WebSocket server for multiplayer

---

## Update & Distribution Strategy

### Version Control: GitHub (private repo)
- Code in privatem GitHub Repo: `buttergolemcode/unemploymentsimulator`
- AI macht alle Code-Änderungen, commitet + pusht
- Tags für Releases (v0.1.0, v0.2.0, etc.)

### Distribution: GitHub Releases
- Jede stabile Version = neuer GitHub Release
- Release enthält: Godot-exportierte `.exe` (Windows) + `version.txt` Manifest
- Download-URL: `https://github.com/buttergolemcode/unemploymentsimulator/releases/latest/download/...`

### Auto-Updater (Godot AutoUpdater.gd)
- Spiel checkt beim Start die `version.txt` vom GitHub Release
- Falls neue Version: Dialog "Update available — Please download from GitHub"
- User klickt OK → Browser öffnet Release-Page → manuell herunterladen
- (Einfacher als Tauri-Binary-Patching, ausreichend für privates Projekt)

### Workflow aus Users-Sicht (du = Spieler)
1. Sag der AI: "Neue Version 0.1.0 bauen"
2. AI pusht Tag `v0.1.0` + triggert Godot-Export (manuell oder via GitHub Action)
3. GitHub Release mit .exe erscheint
4. Du startest altes Spiel → Update-Dialog → Download → neue Version läuft
