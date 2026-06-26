# (Put the) Fries in the Bag — Constitution

> Working title: **(Put the) Fries in the Bag**
> Project name: **Unemployment Simulator**
> A satirical open-world 3D game built in Godot 4.7 where the player hustles from broke to millionaire via 8 shady schemes — without getting arrested or ending up at McDonald's.

## Core Principles

### I. Engine: Godot 4.7 + GDScript

Das Spiel wird ausschließlich in **Godot 4.7** mit **GDScript** entwickelt. Kein C#, keine externen Engines, keine Web-Wrapper. Der Grund: Godot 4.7 bietet native .exe-Export, eine integrierte 3D-Engine, und GDScript ist schnell zu schreiben und zu iterieren. Der frühere Three.js + Tauri-Ansatz wurde wegen Performance-Problemen (3 FPS im Headless-Browser) und unzuverlässigem Auto-Update verworfen. Alle 16 Skripte (GameManager, SchemeData, EventData, PlayerController, Vehicle, NPC, WorldBuilder, etc.) sind in GDScript geschrieben und nutzen Godot-spezifische APIs (CharacterBody3D, StaticBody3D, AnimationPlayer, etc.).

**Konsequenzen:**
- Keine Lambda-Ausdrücke in GDScript (verursachten früher Fehler) — stattdessen statische Methoden
- UI wird komplett in Code gebaut (keine .tscn-Abhängigkeiten für UI-Komponenten)
- Indentation: **Tabs** (nicht Spaces — Godot 4.7 Linter warnt bei Mixed Indentation)
- Assets müssen von Godot importiert werden (FBX → .import-Files beim ersten Editor-Öffnen)

### II. Arcade Physics — Custom CharacterBody3D

Das Spiel nutzt **custom CharacterBody3D-Physik** für Fahrzeuge und Spieler — kein VehicleBody3D, kein Jolt-Plugin, kein Rapier. Grund: Arcade-Style-Driving braucht volle Kontrolle über Lenkverhalten, Beschleunigung und Kollision. Sim-Style-Physik (VehicleBody3D mit Raycast-Wheels) wäre schwerer zu tunen und würde den Arcade-Charakter verlieren.

**Konsequenzen:**
- Vehicle-Collision: CapsuleShape3D (runde Unterseite gleitet über Sidewalk-Stufen) statt BoxShape3D (flache Unterseite verhakt)
- Boden-Collision überall: Jedes Boden-Objekt (Sidewalk, Asphalt, Park-Gras, Pier) braucht eigenen StaticBody3D + CollisionShape3D
- floor_snap_length und floor_max_angle müssen für Arcade-Driving getunt sein (snap=0.5m, max_angle=60°)
- Schwerkraft: 14.0 m/s² für Fahrzeuge (schwerer als Standard 9.8 für knackigeres Fahrgefühl)

### III. CC0 Assets Only

Alle 3D-Modelle, Texturen, Sounds und Animationen sind **CC0 (Public Domain)**. Keine lizenzierten Assets, keine Attribution-Required-Assets, keine kostenpflichtigen Packs. Grund: Das Spiel soll als .exe distributiert werden können ohne rechtliche Komplikationen, und CC0-Packs sind ausreichend für den Low-Poly-Stil.

**Installierte Asset-Packs (in `godot/assets/`):**
- Kenney City Kit (Commercial, Suburban, Industrial, Roads) — Gebäude und Straßen
- Quaternius Cars Pack — 7 Auto-Modelle (NormalCar1/2, SportsCar/2, SUV, Taxi, Cop)
- Quaternius Modular Characters — 11 Charakter-Modelle (Adventurer, Beach, Casual, etc.)
- KayKit City Builder Bits — Street Props (Lampen, Bänke, Hydranten)
- Quaternius Animated Characters (.blend) — benötigt Blender für Godot-Import
- Quaternius Modular Streets (.blend) — benötigt Blender für Godot-Import

**Offen:** Universal Animation Library (120+ Animationen) — itch.io Purchase-Flow blockt automatische Downloads, User muss manuell herunterladen.

### IV. Low-Poly Stylized Aesthetic

Das Spiel hat einen **Low-Poly-Stil** mit flachen Texturen und farbigen Blöcken — kein Realismus, keine High-Poly-Models. Grund: Performance (60+ FPS Ziel), schneller Asset-Workflow, klarer visueller Stil der zu dem satirischen GTA-meets-Saints-Row-Vibe passt.

**Konsequenzen:**
- Gebäude sind Box-Meshes mit Pro-District-Farben (Downtown: dunkelblau mit emissive Fenstern, Slums: braun/rot, etc.)
- Autos sind Quaternius Low-Poly-Modelle
- NPCs sind Quaternius Modular Characters (Low-Poly Humanoids)
- Terrain: Vertex-colored PlaneMesh mit Heightmap-Displacement
- Beleuchtung: Simple StandardMaterial3D (keine PBR-Texturen, keine komplexen Shader außer Water-Shader in D.10)

### V. NYC-Inspired City Layout

Die Stadt ist ein **NYC-inspiriertes Grid** mit klarer Zonen-Hierarchie: STREET → SIDEWALK → BUILDING → GRASS. Kein Random-Grid, kein radialer Layout. Die Stadt ist 1200×1200m groß (spielbare Fläche), umringt von Rural-Zone und Bergwänden als undurchdringliche Grenzen.

**District-Layout:**
- **Downtown** (Zentrum): Wolkenkratzer (40-150m), gläserne Fassaden, Casino, Trading Floor, Corporate Tower
- **Harbor** (Osten): Echter Hafen mit Becken, Piers, Containerschiffen, Kränen
- **Slums** (Südwesten): Kleine Backsteinhäuser (4-10m), Trap House, Internet Cafe, Corner Store
- **Industrial** (Nordwesten): Fabriken, Lagerhallen, E-Com Warehouse
- **Suburbs** (Westen): Kleine Hellfarbene Häuser mit Garten-Charakter
- **Rural** (außerhalb): Grüne Hügel, Bäume, Farms — befahrbar mit Collision

**Straßen-System:**
- 7 Hauptstraßen pro Achse (bei -300, -200, -100, 0, 100, 200, 300) — 100m Block-Abstand
- Jede Straße: Asphalt (8m breit, 2 Spuren) + Sidewalks (2.5m, 15cm hoch) + Zebrastreifen an Kreuzungen
- Sidewalk-Collision: 5cm hoch (floor_snap-kompatibel), visuell 15cm (Bordstein-Optik)
- Kreuzungen: Sidewalk-Ecken mit quadratischen Corner-Stücken, Zebrastreifen (weiße Balken)

### VI. Pragmatic Development — Fix the Cause, Not the Symptom

Bei Bugs wird die **Ursache** behoben, nicht das Symptom. Beispiel: Wenn Räder im Boden glitchen, wird nicht die Rad-Position verschoben (Symptom), sondern die Collision-Shape korrigiert (Ursache). Wenn NPCs rückwärts laufen, wird nicht einfach PI-Rotation drübergebügelt (Symptom-Hack), sondern die Mathematik korrigiert — oder wenn das nicht funktioniert, wird PI als pragmatischer Fix dokumentiert mit Begründung.

**Konsequenzen:**
- Jeder Bug-Fix muss Root-Cause-Analyse enthalten (was war die wahre Ursache?)
- Symptom-Fixes sind erlaubt, müssen aber als solche markiert sein mit "Trade-off"-Dokumentation
- Keine "Billig-Fixes" die das Problem nur verschieben (z.B. Height-Adjustments statt Collision-Fixes)

### VII. Iterative Polish — Each Sprint Must Be Playable

Nach jedem Sprint muss das Spiel **spielbar** sein. Kein Sprint darf das Spiel in einem unspielbaren Zustand hinterlassen. Das bedeutet: Bugs die das Spiel unspielbar machen (Crashes, nicht-funktionierende Steuerung, fehlende Collision) haben Priorität über neue Features.

**Konsequenzen:**
- Nach jedem Commit: Spiel muss startbar sein
- Major Bugs (Auto fliegt, NPCs durch Boden, etc.) werden sofort gefixt bevor neue Features
- "Playable" bedeutet: Spieler kann laufen, fahren, mit Gebäuden interagieren, Scheme-Actions ausführen
- Optische Bugs (Räder drehen sich nicht, T-Pose, etc.) sind tolerierbar solange das Spiel spielbar bleibt

## Technology Stack & Constraints

| Komponente | Technologie | Begründung |
|-----------|-------------|------------|
| Engine | Godot 4.7 | Native .exe-Export, GDScript, integrierte 3D-Engine |
| Programmiersprache | GDScript | Schnelle Iteration, Godot-native APIs |
| Physik | Custom CharacterBody3D | Arcade-Style-Driving, volle Kontrolle |
| 3D Assets | CC0 (Kenney, Quaternius, KayKit) | Rechtlich unkompliziert, Low-Poly-Stil |
| Version Control | Git + GitHub (private repo) | Standard, Auto-Update via Releases |
| Distribution | GitHub Releases (.exe + version.txt) | Einfach, kostenlos, ausreichend für privates Projekt |
| Auto-Updater | Godot AutoUpdater.gd (HTTP check) | Simpler als Binary-Patching, öffnet Browser für Download |
| Multiplayer (future) | Rust WebSocket server | Server-authoritative, geplant für Sprint K |

**Constraints:**
- Keine externen Physik-Engines (kein Jolt, kein Rapier, kein VehicleBody3D)
- Keine lizenzierten Assets (nur CC0)
- Kein Code-Signing (privates Projekt, "Trotzdem ausführen" akzeptabel)
- Blender muss installiert sein für .blend-Datei-Import (Universal Animation Library, Modular Streets)

## Development Workflow

### Git Workflow
1. AI macht alle Code-Änderungen, committet + pusht
2. Commit-Messages: Englisch, mit "Fix:" / "Add:" / "Update:" Prefix
3. Ein Commit pro logischer Änderung (keine Mega-Commits mit 10 verschiedenen Fixes)
4. `MASTERPLAN.md` wird bei Scope-Änderungen aktualisiert
5. `CHANGELOG.md` wird bei jedem abgeschlossenen Sub-Schritt aktualisiert

### Bug-Fix-Workflow
1. User reports Bug (mit Screenshot wenn möglich)
2. AI analysiert Root Cause (liest Code, evtl. VLM für Screenshot-Analyse)
3. AI implementiert Fix (bevorzugt Ursache, Symptom nur als dokumentierter Trade-off)
4. AI committet + pusht mit Root-Cause-Beschreibung im Commit-Message
5. User testet und gibt Feedback

### Asset-Integration-Workflow
1. Asset wird nach `godot/assets/<pack_name>/` heruntergeladen
2. Godot Editor muss einmal geöffnet werden → FBX/GLB-Import wird getriggert
3. Asset wird im Code via `load("res://assets/...")` referenziert
4. Fallback-Mechanismus: Wenn Asset fehlt, wird Box-Mesh/Capsule verwendet

### Spec-Kit Workflow
- Spec-Kit ist installiert (v0.11.9, Copilot-Integration)
- Slash-Commands (`/speckit.*`) können im Chat verwendet werden
- Constitution, Specs, Plans, Tasks werden in `.specify/memory/` gespeichert
- Spec-Kit wird für komplexe Features genutzt (z.B. Police 2.0, Multiplayer)

## Planned Sprints (Order Subject to Change)

Die Reihenfolge der Sprints kann sich ändern. Die folgende Liste zeigt alle geplanten Sprints tabellarisch — die Priorisierung wird im Laufe der Entwicklung angepasst.

| Sprint | Titel | Status | Beschreibung |
|--------|-------|--------|--------------|
| **A** | City & Atmosphere (Placeholder) | ✅ Done | Box-block Welt mit Districts, NPCs, Wetter, Day/Night |
| **B** | Native .exe (Godot Pivot) | ✅ Done | Godot 4.7 Migration, GDScript Rewrite, GitHub Repo, Auto-Updater |
| **C** | Vehicles & Driving (Basic) | ✅ Done | Custom CharacterBody3D-Physik, Auto enter/exit, NPC überfahrbar |
| **D** | Assets & Map Polish | 🔄 In Progress | CC0 Assets integrieren, NYC-Style Map, Animationen, Buildings, Roads, Props |
| **E** | Sound & Atmosphere | ⬜ Planned | Musik, Ambient-SFX, Vehicle-SFX, UI-SFX, Voice Lines |
| **F** | Police 2.0 | ⬜ Planned | Suspicion-System, Bribery, Insider, Raids, Snitches |
| **G** | Weapons & Robbery Overhaul | ⬜ Planned | Waffenhändler, Fake vs Real, Pickpocketing, Robbery-Minigame |
| **H** | Drug Buff/Debuff System | ⬜ Planned | Konsumierbare Items, Buffs per Scheme, Addiction/Withdrawal |
| **I** | Properties & Businesses | ⬜ Planned | Immobilien, eigene Businesses, Storage, Interiors |
| **J** | Game Mode Selection | ⬜ Planned | Kingpin, Turf War, Survival, Story, Sandbox, Exit |
| **K** | Multiplayer Prototype | ⬜ Planned | Server-authoritative, Proximity Voice, In-Game Phone |
| **L** | Lawyer System (optional) | ⬜ Planned | Anwälte, Verhandlungs-Minigames, Proceedings |
| **M** | Character Creator & Outfits | ⬜ Planned | Body/Face/Hair-Editor, Kleidung, Skill-Tree |

### Sprint D Sub-Steps (Current)

| Step | Titel | Status | Beschreibung |
|------|-------|--------|--------------|
| D.0 | Asset Download | ✅ Done | 8 CC0-Packs heruntergeladen (Kenney, Quaternius, KayKit) |
| D.1 | Project Structure | ✅ Done | `godot/assets/` Verzeichnis, Asset-README |
| D.2 | Vehicle Models | ✅ Done | Quaternius Cars FBX integriert, Wheel-Steering, Body-Roll |
| D.3 | NPC Models | ✅ Done | Quaternius Modular Characters (11 Modelle), Player = Suit |
| D.4 | Map Layout | 🔄 In Progress | NYC-Style Grid, District-Polygone, Sidewalks, Crosswalks, Landmarks |
| D.5 | Animations | ⬜ Planned | Universal Animation Library, Walk/Idle/Run für NPCs + Player, Wheel-Spin |
| D.6 | Building System | ⬜ Planned | Kenney GLB-Gebäude pro District, BuildingGenerator.gd |
| D.7 | Road Network | ⬜ Planned | Modulare Straßen-Tiles, Road-Graph, Traffic Lights |
| D.8 | Street Props | ⬜ Planned | KayKit Props, Parked Cars, District-spezifische Props |
| D.9 | Lighting & Atmosphere | ⬜ Planned | Pro-District-Beleuchtung, Skybox, Fog, Particles |
| D.10 | Water Shader | ⬜ Planned | Animiertes Hafenwasser mit Wellen, Reflexionen |
| D.11 | Acceptance Test | ⬜ Planned | 10-Punkte-Checkliste für Sprint D |

## Governance

- Diese Constitution ist die höchste Autorität für alle Entwicklungsentscheidungen
- Änderungen an der Constitution erfordern: Begründung, Approval, Migration-Plan
- Alle Commits müssen mit den Core Principles übereinstimmen (z.B. kein C#-Code, keine lizenzierten Assets)
- Bei Konflikten zwischen Prinzipien (z.B. "Pragmatic Development" vs. "Fix the Cause"): Root-Cause-Analyse hat Vorrang, aber Spielbarkeit (Principle VII) ist nicht verhandelbar
- `MASTERPLAN.md` definiert was gebaut wird, diese Constitution definiert wie es gebaut wird
- `CHANGELOG.md` dokumentiert was gebaut wurde (Commit-Referenzen, Root-Causes, Trade-offs)

**Version**: 1.0.0 | **Ratified**: 2026-06-27 | **Last Amended**: 2026-06-27
