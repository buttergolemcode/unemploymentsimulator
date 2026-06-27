# Feature Inventory — (Put the) Fries in the Bag

> Sortiert nach Spec-Nummer. Datum = Spec-Erstellungsdatum (retroaktiv).
> Status: ✅ Implemented / 🔄 In Progress / ⬜ Planned

| # | Spec | Feature | Beschreibung | Datum | Status |
|---|------|---------|--------------|-------|--------|
| 001 | game-state-management | Money System | Verfolgt Spielergeld ($500 Start, $1M Win, -$1k Bankrott) | 2026-06-27 | ✅ |
| 001 | game-state-management | Heat System | Polizei-Aufmerksamkeit 0-100, Arrest bei 100 | 2026-06-27 | ✅ |
| 001 | game-state-management | Reputation System | Ruf 0-100, freut Crew-Events bei ≥30 | 2026-06-27 | ✅ |
| 001 | game-state-management | Day Counter | Tag-Zähler, max 60 Tage, McDonald's-Lose bei <$50k | 2026-06-27 | ✅ |
| 001 | game-state-management | Actions Per Day | 3 Aktionen/Tag, Auto-End bei 0 | 2026-06-27 | ✅ |
| 001 | game-state-management | Win Condition | $1.000.000 erreicht → Win | 2026-06-27 | ✅ |
| 001 | game-state-management | Lose: Arrested | Heat 100 → "Federal agents kicked your door" | 2026-06-27 | ✅ |
| 001 | game-state-management | Lose: Bankrupt | Geld < -$1000 → "Broke beyond recovery" | 2026-06-27 | ✅ |
| 001 | game-state-management | Lose: McDonald's | Tag 60 + <$50k → "You walked into McDonald's" | 2026-06-27 | ✅ |
| 001 | game-state-management | Heat Decay | Heat kühlt pro Tag um 0-3 Punkte | 2026-06-27 | ✅ |
| 001 | game-state-management | Skill System | 8 Skills Level 1-10, skaliert Belohnungen | 2026-06-27 | ✅ |
| 001 | game-state-management | Skill XP Progression | 100 XP = Level-Up, Max Level 10 | 2026-06-27 | ✅ |
| 001 | game-state-management | Stats Tracking | total_earned, total_lost, deals_closed, days_survived | 2026-06-27 | ✅ |
| 001 | game-state-management | End-Day Flow | 35% Event-Chance, sonst Tag vorrücken | 2026-06-27 | ✅ |
| 001 | game-state-management | Log Message System | Farbige Log-Einträge mit Tag-Präfix | 2026-06-27 | ✅ |
| 001 | game-state-management | Money Formatting | $X, $Xk, $X.XXM je nach Größe | 2026-06-27 | ✅ |
| 002 | scheme-system | Scheme: E-Com | Thrift flips, Dropship, Review Farms (low heat) | 2026-06-27 | ✅ |
| 002 | scheme-system | Scheme: Trading | Meme stocks, 0DTE options, Pump & Dump (low heat) | 2026-06-27 | ✅ |
| 002 | scheme-system | Scheme: Gambling | Slots, Roulette, Blackjack counting (low heat) | 2026-06-27 | ✅ |
| 002 | scheme-system | Scheme: Drugs | Slang bud, Flip pills, Supply run (high heat) | 2026-06-27 | ✅ |
| 002 | scheme-system | Scheme: Scam | Phishing, Romance, Pig-butchering (medium heat) | 2026-06-27 | ✅ |
| 002 | scheme-system | Scheme: Robbery | Phone snatch, Burglary, Armed robbery (extreme heat) | 2026-06-27 | ✅ |
| 002 | scheme-system | Scheme: Tax Fraud | Setup + Harvest refunds (medium heat) | 2026-06-27 | ✅ |
| 002 | scheme-system | Scheme: Wire Fraud | Fake invoices, CEO impersonation (high heat) | 2026-06-27 | ✅ |
| 002 | scheme-system | Action Cost System | Jede Aktion kostet 1-3 der 3 Tagesaktionen | 2026-06-27 | ✅ |
| 002 | scheme-system | Risk/Reward Outcomes | Chance-basierte Erfolge/Misserfolge mit Skill-Scaling | 2026-06-27 | ✅ |
| 002 | scheme-system | Tax Fraud Setup Gate | Setup erforderlich vor Harvest | 2026-06-27 | ✅ |
| 003 | random-events | Event: Police Raid | Heat ≥60, 3 Choices (bolt/flush/lawyer $5k) | 2026-06-27 | ✅ |
| 003 | random-events | Event: Witness | Heat 35-60, 2 Choices (lawyer $1.5k/lay low) | 2026-06-27 | ✅ |
| 003 | random-events | Event: McDonald's | Geld <$100, 2 Choices (take job=lose/decline+$50) | 2026-06-27 | ✅ |
| 003 | random-events | Event: Hot Tip | r/WallStreetBets, 2 Choices (ape $2k/skip), 55% win | 2026-06-27 | ✅ |
| 003 | random-events | Event: Uncle Louie | Umschlag mit Geld, 2 Choices (take/refuse+rep) | 2026-06-27 | ✅ |
| 003 | random-events | Event: Crew Offer | Rep ≥30, 2 Choices (join $2-5k+heat+rep/stay solo) | 2026-06-27 | ✅ |
| 003 | random-events | Event: Mom Needs Cash | $500, 2 Choices (send-heat/ignore-rep) | 2026-06-27 | ✅ |
| 003 | random-events | Event: Mugging | 2 Choices (take loss/fight back 35%+skill) | 2026-06-27 | ✅ |
| 003 | random-events | Event Pool Builder | Filtert Events nach Game-State | 2026-06-27 | ✅ |
| 004 | player-movement-camera | First-Person Walk | WASD + Mouse-Look, 5 m/s walk speed | 2026-06-27 | ✅ |
| 004 | player-movement-camera | Sprint | Shift = 8 m/s | 2026-06-27 | ✅ |
| 004 | player-movement-camera | Third-Person Toggle | V wechselt 1st/3rd Person, Mesh sichtbar/unsichtbar | 2026-06-27 | ✅ |
| 004 | player-movement-camera | Mouse Capture Toggle | Esc released Mouse, Click recaptured | 2026-06-27 | ✅ |
| 004 | player-movement-camera | Building Proximity | Auto-Detekt Gebäude innerhalb 8m, "Press E" Prompt | 2026-06-27 | ✅ |
| 004 | player-movement-camera | Top-Level Camera | Camera detached from player transform | 2026-06-27 | ✅ |
| 004 | player-movement-camera | Player Model | Suit.fbx (Quaternius), Capsule+Head+Beanie Fallback | 2026-06-27 | ✅ |
| 004 | player-movement-camera | Phase-Gated Input | Input ignoriert wenn phase != "playing" | 2026-06-27 | ✅ |
| 005 | vehicle-driving | Vehicle Enter/Exit | F zum Einsteigen (5m), F zum Aussteigen (2.5m hinter) | 2026-06-27 | ✅ |
| 005 | vehicle-driving | Engine Model | Throttle, Brake, Engine Brake, Max Speed 18 m/s | 2026-06-27 | ✅ |
| 005 | vehicle-driving | Bell-Curve Steering | Peak bei 5 m/s, abnehmend bei Highspeed, keine Tank-Spin | 2026-06-27 | ✅ |
| 005 | vehicle-driving | Reverse Steering Invert | Lenkung invertiert beim Rückwärtsfahren | 2026-06-27 | ✅ |
| 005 | vehicle-driving | Collision Impact | Speed-Verlust bei Wand-Kollision, Pushback | 2026-06-27 | ✅ |
| 005 | vehicle-driving | Chase Camera | 3rd-Person Verfolgungskamera (7m zurück, 2.5m hoch) | 2026-06-27 | ✅ |
| 005 | vehicle-driving | Free-Look Camera | Mouse orbitiert Kamera unabhängig vom Auto | 2026-06-27 | ✅ |
| 005 | vehicle-driving | Vehicle Collision | CapsuleShape (rotated), Bodenfreiheit via floor_snap | 2026-06-27 | ✅ |
| 005 | vehicle-driving | 7 Car Models | NormalCar1/2, SportsCar/2, SUV, Taxi, Cop (FBX) | 2026-06-27 | ✅ |
| 005 | vehicle-driving | Box-Mesh Fallback | Prozedurales Auto wenn FBX fehlt | 2026-06-27 | ✅ |
| 006 | npc-system | Pedestrians | ~121 NPCs wandern zu zufälligen Zielen | 2026-06-27 | ✅ |
| 006 | npc-system | Merchants | 9 Merchant NPCs an fixen Positionen mit Badge | 2026-06-27 | ✅ |
| 006 | npc-system | Street Avoidance | NPCs meiden Straßen (5.5m Buffer, 20 Versuche) | 2026-06-27 | ✅ |
| 006 | npc-system | Knockdown | NPC umfahren → 4s am Boden, Knockback, dann Aufstehen | 2026-06-27 | ✅ |
| 006 | npc-system | Walk Bob | Prozedurale Walk-Animation (bob + forward lean) | 2026-06-27 | ✅ |
| 006 | npc-system | Character Models | 11 Quaternius Modular Characters, Capsule Fallback | 2026-06-27 | ✅ |
| 006 | npc-system | District Distribution | 35 Downtown, 30 Slums, 18 Industrial, 15 Harbor, 15 Suburbs, 8 Rural | 2026-06-27 | ✅ |
| 007 | world-generation | NYC Grid City | 1200×1200m, 7 Streets pro Achse, 100m Blocks | 2026-06-27 | ✅ |
| 007 | world-generation | District System | 6 Districts mit Polygon-Boundaries | 2026-06-27 | ✅ |
| 007 | world-generation | Polygon District Lookup | Geometry2D.is_point_in_polygon() | 2026-06-27 | ✅ |
| 007 | world-generation | Roads & Sidewalks | 8m Straßen + 2.5m Sidewalks (15cm visuell, 5cm Collision) | 2026-06-27 | ✅ |
| 007 | world-generation | Crosswalks | Zebrastreifen an allen 49 Kreuzungen | 2026-06-27 | ✅ |
| 007 | world-generation | Sidewalk Corners | Eck-Stücke an Kreuzungen (smooth corners) | 2026-06-27 | ✅ |
| 007 | world-generation | Lane Markings | Gestrichelte gelbe Mittellinien | 2026-06-27 | ✅ |
| 007 | world-generation | Scheme Buildings | 8 farbige Gebäude mit Label3D | 2026-06-27 | ✅ |
| 007 | world-generation | Filler Buildings | 2×2-3×3 pro Block, pro-District Stil | 2026-06-27 | ✅ |
| 007 | world-generation | District Building Styles | Downtown=Glass, Harbor=Dark, Slums=Brick, Industrial=Gray, Suburbs=Light | 2026-06-27 | ✅ |
| 007 | world-generation | Harbor | Becken, 3 Piers, 3 Ships, 60 Container, 6 Kräne | 2026-06-27 | ✅ |
| 007 | world-generation | Landmarks | Park, Skyline(3), Bridge, Fortress, Stadium, Bus Station, 2 Gas Stations | 2026-06-27 | ✅ |
| 007 | world-generation | Terrain | Flach city, fractal hills rural, mountain walls edges | 2026-06-27 | ✅ |
| 007 | world-generation | Rural Collision | 50m Grid BoxShape3D, matching terrain_height | 2026-06-27 | ✅ |
| 007 | world-generation | Mountain Walls | Undurchdringliche BoxShape3D an 4 Kanten | 2026-06-27 | ✅ |
| 007 | world-generation | Water Plane | 2400×2400, y=-3.0, Ostseite | 2026-06-27 | ✅ |
| 007 | world-generation | Trees | Prozedural (Trunk + Foliage), in Park + Rural | 2026-06-27 | ✅ |
| 007 | world-generation | Street Lamps | 16 Lampen mit OmniLight | 2026-06-27 | ✅ |
| 007 | world-generation | Day/Night Start | Spiel startet bei Mittag (t=0.5) | 2026-06-27 | ✅ |
| 008 | day-night-weather | Day/Night Cycle | 12min = 24h, Sun rotation, 4 Phasen | 2026-06-27 | ✅ |
| 008 | day-night-weather | Phase-Based Lighting | Night=blue, Dawn=orange, Day=warm, Dusk=red | 2026-06-27 | ✅ |
| 008 | day-night-weather | Environment | Fog, ACES Tonemap, Ambient Light | 2026-06-27 | ✅ |
| 008 | day-night-weather | Rain State Machine | clear→fading_in→raining→fading_out→clear | 2026-06-27 | ✅ |
| 008 | day-night-weather | Rain Particles | 800 MultiMesh Drops, folgen Kamera | 2026-06-27 | ✅ |
| 008 | day-night-weather | Cloud Overlay | 200×200m plane, dark blue, fades with rain | 2026-06-27 | ✅ |
| 008 | day-night-weather | Ambient Rain Light | Dim cool OmniLight during rain | 2026-06-27 | ✅ |
| 009 | ui-system | HUD Stats Bar | Cash, Heat, Day, Actions, Rep (top-left) | 2026-06-27 | ✅ |
| 009 | ui-system | Heat Color Coding | Green→Yellow→Orange→Red | 2026-06-27 | ✅ |
| 009 | ui-system | Log Panel | Scrollable, 30 entries max, colored by type | 2026-06-27 | ✅ |
| 009 | ui-system | Building Action Panel | Modal mit Scheme-Info + Action Cards + Run Buttons | 2026-06-27 | ✅ |
| 009 | ui-system | Action Availability UI | Disabled wenn nicht verfügbar oder keine Actions | 2026-06-27 | ✅ |
| 009 | ui-system | Event Modal | Modal mit Title, Description, Choice Buttons | 2026-06-27 | ✅ |
| 009 | ui-system | End Day Button | Mit Confirmation Dialog bei übrigbleibenden Actions | 2026-06-27 | ✅ |
| 009 | ui-system | Main Menu | Start + Quit Buttons, Controls Hint | 2026-06-27 | ✅ |
| 009 | ui-system | End Screen | Win/Lose Title, Flavor Text, Stats, Restart/Quit | 2026-06-27 | ✅ |
| 009 | ui-system | Scene Transitions | menu↔game↔end via phase_changed | 2026-06-27 | ✅ |
| 009 | ui-system | Code-Built UI | Alle UI in Code, keine .tscn für HUD/Panels | 2026-06-27 | ✅ |
| 010 | auto-updater | Version Check | HTTPRequest holt version.txt von GitHub | 2026-06-27 | ✅ |
| 010 | auto-updater | Semver Compare | Numerischer Vergleich von X.Y.Z | 2026-06-27 | ✅ |
| 010 | auto-updater | Update Dialog | AcceptDialog mit aktueller vs. neuester Version | 2026-06-27 | ✅ |
| 011 | vehicle-visuals | 7 FBX Car Models | Quaternius Cars (NormalCar1/2, SportsCar/2, SUV, Taxi, Cop) | 2026-06-27 | ✅ |
| 011 | vehicle-visuals | Body Roll | Lean into turns (max ~4.5°), smooth lerp | 2026-06-27 | ✅ |
| 011 | vehicle-visuals | Body Pitch | Squat/Dive on accel/brake (max ~1.7°) | 2026-06-27 | ✅ |
| 011 | vehicle-visuals | Wheel Spin | Rotate X based on speed (box-mesh only) | 2026-06-27 | ✅ |
| 011 | vehicle-visuals | Front Wheel Steering | Rotate Y based on steer (box-mesh only) | 2026-06-27 | ✅ |
| 011 | vehicle-visuals | Headlights & Taillights | 2 front warm + 2 rear red OmniLights | 2026-06-27 | ✅ |
| 012 | meta-system | Game State Singleton | GameManager autoload, alle State-Properties | 2026-06-27 | ✅ |
| 012 | meta-system | Signal Bus | 8 Signals für loose coupling | 2026-06-27 | ✅ |
| 012 | meta-system | State Reset | _reset_state() nullt alles | 2026-06-27 | ✅ |
| 012 | meta-system | Phase State Machine | menu→playing→won/lost→menu | 2026-06-27 | ✅ |
| 012 | meta-system | Group-Based Discovery | "player", "vehicle", "pedestrian", "merchant", "scheme_building" | 2026-06-27 | ✅ |
| 012 | meta-system | Meta-Based Tagging | scheme_id/name/emoji via set_meta() | 2026-06-27 | ✅ |
| 012 | meta-system | Collision Layer Separation | NPCs layer 3 mask 1, vehicles pass through | 2026-06-27 | ✅ |
| 012 | meta-system | Static Data Registries | SchemeData, EventData, VehicleData, WorldBuilder (class_name) | 2026-06-27 | ✅ |
| 013 | debug-mode | Noclip (F1) | FLOATING motion_mode, 3D flight, Space/Ctrl up/down | 2026-06-27 | ✅ |
| 013 | debug-mode | Fast Speed (F2) | 4× walk/sprint speed, boosts noclip to 80 m/s | 2026-06-27 | ✅ |
| 013 | debug-mode | Teleport to Ground (F3) | Reads terrain_height(), places player 2m above | 2026-06-27 | ✅ |
| 013 | debug-mode | Print Position (F4) | Logs position + district to console | 2026-06-27 | ✅ |
| — | D.4-map-layout | NYC Grid Redesign | 1200×1200m, 7 avenues, 100m blocks | 2026-06-27 | ✅ |
| — | D.4-map-layout | Sidewalk Collision | 5cm collision, floor_snap kompatibel | 2026-06-27 | ✅ |
| — | D.4-map-layout | Real Harbor | Basin, Piers, Ships, Container, Cranes | 2026-06-27 | ✅ |
| — | D.4-map-layout | Rural Collision | 50m Grid, terrain-matching | 2026-06-27 | ✅ |
| — | D.4.5-styling | Kenney Building Integration | Replace BoxMesh mit Kenney GLB pro District | — | ⬜ |
| — | D.4.5-styling | Vehicle Styling | Quaternius Cars in Blender anpassen (custom colors, arcade proportions) | — | ⬜ |
| — | D.4.5-styling | Character Styling | Quaternius Characters in Blender anpassen (outfits, proportions) | — | ⬜ |
| — | D.4.5-styling | Tree/Prop Styling | Replace procedural trees/props mit styled Models | — | ⬜ |
| — | D.4.5-styling | Landmark Styling | Replace box landmarks mit styled versions | — | ⬜ |
| — | D.4.5-styling | Harbor Styling | Replace box ships/containers/cranes mit styled versions | — | ⬜ |
| — | D.4.5-styling | Mountain Terrain | Real mountain geometry (peaks/ridges, not box walls) | — | ⬜ |
| — | D.4.5-styling | Forest Zones | Dense tree coverage in rural/suburb borders | — | ⬜ |
| — | D.4.5-styling | Highway System | Highway roads to map edges (guardrails, signage) | — | ⬜ |
| — | D.4.5-styling | Rural Areas | Farms, barns, fields, dirt roads (not empty hills) | — | ⬜ |
| — | D.4.5-styling | Coastline | Beach/shore transition where land meets water | — | ⬜ |
| — | D.4.5-styling | District Borders | Natural transitions (rivers, parks, elevation) | — | ⬜ |
| — | D.4.5-styling | Suburb Design | Residential streets (gardens, fences, houses) | — | ⬜ |
| — | D.4.5-styling | Slum Alleyways | Dense narrow alleyways (not just smaller grid) | — | ⬜ |
| — | D.4.5-styling | Color Palette | Cohesive desaturated palette with neon accents | — | ⬜ |
| — | D.4.5-styling | Material Style | Flat colors, subtle roughness, not PBR | — | ⬜ |
| — | D.5-animations | NPC Walk Animations | Universal Animation Library (pending download) | — | ⬜ |
| — | D.5-animations | Vehicle Wheel Spin (FBX) | Spin-pivot Node3D für FBX-Räder | — | ⬜ |
| — | D.5-animations | Player Walk/Run Anim | Walk, Run, Idle, Enter/Exit Vehicle | — | ⬜ |
| — | D.6-buildings | Kenney Building System | Modular GLB Buildings pro District | — | ⬜ |
| — | D.7-roads | Modular Road Tiles | Kenney Roads + Quaternius Streets | — | ⬜ |
| — | D.8-props | Street Props | KayKit + Downtown MegaKit | — | ⬜ |
| — | D.9-lighting | Per-District Lighting | Warm/cold/dim/harsh per district | — | ⬜ |
| — | D.10-water | Water Shader | Animated waves, reflections, foam | — | ⬜ |
| — | E-sound | Background Music | Pixabay Lo-Fi, district-specific | — | ⬜ |
| — | E-sound | Ambient SFX | Traffic, industrial, seagulls, crickets | — | ⬜ |
| — | E-sound | Vehicle SFX | Engine RPM, tire screech, crash, horn | — | ⬜ |
| — | F-police | Suspicion System | Replaces Heat, rises with crime, decays | — | ⬜ |
| — | F-police | Bribery Thresholds | Low/Medium/High suspicion tiers | — | ⬜ |
| — | F-police | Insider Loyalty | Recruit insiders, early warnings, betrayal | — | ⬜ |
| — | F-police | Police Raids | Cops raid properties at high suspicion | — | ⬜ |
| — | G-weapons | Weapon Dealer | Buy real/fake weapons | — | ⬜ |
| — | G-weapons | Robbery Minigame | Interactive robbery gameplay | — | ⬜ |
| — | H-drugs | Drug Buff/Debuff | Temporary buffs per scheme, addiction risk | — | ⬜ |
| — | I-properties | Buy Real Estate | Apartments, warehouses, garages, safehouses | — | ⬜ |
| — | I-properties | Build Businesses | Own casino, drug lab, shop | — | ⬜ |
| — | J-modes | Game Mode Selection | Kingpin, Turf War, Survival, Story, Sandbox, Exit | — | ⬜ |
| — | K-multiplayer | Server-Authoritative | Rust WebSocket server | — | ⬜ |
| — | K-multiplayer | Proximity Voice | Positional audio, distance-based | — | ⬜ |
| — | K-multiplayer | In-Game Phone | Text chat, voice calls, missions | — | ⬜ |
| — | L-lawyer | Lawyer System | Hire lawyers, negotiation minigames | — | ⬜ |
| — | M-character | Character Creator | Body/face/hair editor, outfits, skill tree | — | ⬜ |
