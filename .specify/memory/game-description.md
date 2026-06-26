# (Put the) Fries in the Bag — Game Description

> Working title: **(Put the) Fries in the Bag**
> Projektname: **Unemployment Simulator**
> Genre: Open-World Sandbox / Satirical Crime Sim
> Engine: Godot 4.7 (GDScript)
> Status: Vertical Slice (Sprint D in progress)
> Release: TBD (private project, GitHub Releases)

---

## Steam-Style Description

### About the Game

You're broke. You've got $500, no job, and 60 days to make a million dollars. Welcome to **(Put the) Fries in the Bag** — a satirical open-world crime sim where you hustle your way from penniless to kingpin using every shady scheme in the book.

Will you flip thrift finds on eBay and play it safe? Or arm-rob a corner store and risk the feds kicking down your door? Maybe you'll run a pig-butchering crypto scam from an internet café in the slums, or file fraudulent tax returns by the dozen. Eight schemes. Twenty-two actions. One million dollars. Don't get arrested. Don't go broke. And whatever you do — don't end up at McDonald's.

### Key Features

- **8 Distinct Crime Schemes**: Day trading, e-commerce, gambling, drug dealing, scamming, robbery, tax fraud, and wire fraud — each with unique risk/reward profiles and skill progression
- **Open-World 3D City**: A 1200×1200m NYC-inspired grid with 6 districts (Downtown, Harbor, Slums, Industrial, Suburbs, Rural), each with distinct architecture, NPCs, and atmosphere
- **Drivable Vehicles**: Enter, drive, and crash cars with arcade-style physics. Run over pedestrians (they get back up). Free-look chase camera. 7 vehicle types from taxis to sports cars
- **Living World**: Dynamic day/night cycle (12-min real-time), random rain weather with particle effects, ~121 NPCs walking the streets, merchants at fixed locations
- **Random Events**: Police raids, uncle Louie's envelopes, mom needs cash, muggings, hot stock tips, crew offers — branching choices that can make or break your run
- **Skill Progression**: 8 skills (one per scheme) that level up with XP, scaling your rewards. Level 10 trading = 10× profit on meme stock pumps
- **Heat System**: Every crime adds heat. Reach 100 and you're arrested. Lay low to let it cool — or bribe your way out
- **Multiple Win/Lose Conditions**: Win at $1M. Lose by arrest, bankruptcy, or the ultimate shame — a McDonald's job

### Vibe

GTA meets Breaking Bad meets Scarface, with the humor of Saints Row and Yakuza. Low-poly stylized aesthetic. Satirical, not serious. You're not building a criminal empire — you're just trying not to flip burgers.

### Technical

- **Engine**: Godot 4.7 with GDScript
- **Platform**: Windows .exe (native export)
- **Assets**: 100% CC0 (Kenney, Quaternius, KayKit) — no licensed content
- **Physics**: Custom CharacterBody3D arcade physics (no external engine)
- **Distribution**: GitHub Releases with auto-update check
- **Multiplayer**: Planned (server-authoritative, proximity voice, in-game phone)

### Current State (Sprint D — Assets & Map Polish)

The vertical slice is playable: walk, drive, interact with 8 scheme buildings, perform 22 actions, trigger random events, win/lose. The world uses CC0 assets (Quaternius cars + characters, Kenney buildings) with NYC-style street grid, sidewalks, crosswalks, harbor with ships and cranes, and 8 landmarks. Active work: map polish, animations, building system, lighting.

---

## One-Sentence Pitch

> Make a million dollars in 60 days using eight illegal schemes — without getting arrested, going broke, or ending up at McDonald's.
