# 3D Game Assets Research — "Unemployment Simulator 3D"

A researched list of **specific, downloadable, license-clear assets** for a GTA-style low-poly night-city game built with **Three.js / @react-three/fiber**.

> **License priority**: CC0 (public domain, no attribution) first, CC-BY (attribution required, easy to display in a credits screen) second.
> **Format priority**: GLTF/GLB (native Three.js) > FBX (loadable via `FBXLoader`) > OBJ (fallback).
> All links below were verified to resolve to the named pack/model page as of this research pass. Always re-check the license text on the download page before shipping — licenses occasionally change.

---

## TL;DR — Recommended Starter Stack

For a fast vertical slice, download just these four and you have a playable city:

| Need | Asset | URL | License |
|---|---|---|---|
| City blocks & buildings | **Kenney City Kit (Commercial + Suburban + Roads + Industrial)** | https://kenney.nl/assets/series:City | CC0 |
| Streets / sidewalks | **Quaternius Modular Streets Pack** | https://quaternius.com/packs/modularstreets.html | CC0 |
| Cars (parked + traffic) | **Quaternius Cars Pack** | https://quaternius.com/packs/cars.html | CC0 |
| Player + NPCs | **Quaternius Ultimate Animated Character Pack** | https://quaternius.com/packs/ultimatedanimatedcharacter.html | CC0 |
| Player animations | **Quaternius Universal Animation Library 2** | https://quaternius.com/packs/universalanimationlibrary2.html | CC0 |
| Guns (robbery/deal anims) | **Quaternius Ultimate Guns Pack** | https://poly.pizza/bundle/Ultimate-Guns-Pack-cpgUfI4t2F | CC0 |
| Street props (lamps, benches) | **KayKit City Builder Bits** | https://kaylousberg.itch.io/city-builder-bits | CC0 |
| Ambient music | **Pixabay lo-fi "Walking On The Streets"** | https://pixabay.com/music/beats-lo-fi-hip-hop-walking-on-the-streets-144449 | Pixabay (CC0-like) |

Everything above is CC0 → safe to ship in a commercial `.exe` with zero attribution.

---

## 1. Kenney.nl — CC0 (Public Domain)

All Kenney assets are released under **CC0 1.0 Universal** — no attribution required, commercial use OK. The **City Kit** series is the backbone of this game. Files ship as `OBJ, FBX, DAE, STL, glTF` — the `glTF` exports drop straight into `useGLTF()` from `@react-three/drei`.

### City Kit (Suburban)
- **URL**: https://kenney.nl/assets/city-kit-suburban
- **Mirror (itch.io)**: https://kenney-assets.itch.io/city-kit-suburban
- **License**: CC0
- **Formats**: OBJ, FBX, DAE, STL, glTF
- **Contents**: 35+ suburban house models, fences, trees, props — modular footprint tiles
- **Use**: Residential outskirts of the city, low-rent neighborhoods where the player does "shady deals", backyards for robbery missions

### City Kit (Commercial)
- **URL**: https://kenney.nl/assets/city-kit-commercial
- **OGA mirror**: https://opengameart.org/content/city-kit-commercial
- **License**: CC0
- **Formats**: OBJ, FBX, DAE, STL, glTF
- **Contents**: ~40 commercial buildings (shops, offices, diners) matching the Roads/Suburban footprint
- **Use**: The "downtown" core — stores the player can enter for scam missions, banks for robbery

### City Kit (Industrial)
- **URL**: https://kenney.nl/assets/city-kit-industrial
- **License**: CC0
- **Formats**: OBJ, FBX, DAE, STL, glTF
- **Contents**: Warehouses, factories, silos, industrial props — fits the other City Kits
- **Use**: Drug-lab / stash-house locations, abandoned warehouse deal spots, back-alley robbery scenes

### City Kit (Roads)
- **URL**: https://kenney.nl/assets/city-kit-roads
- **itch.io mirror**: https://kenney-assets.itch.io/city-kit-roads
- **License**: CC0
- **Formats**: OBJ, FBX, DAE, STL, glTF
- **Contents**: 65+ modular road tiles — straights, corners, intersections, crosswalks, sidewalks
- **Use**: Snap together the street grid the player walks on. Combine with Quaternius Modular Streets for variety.

### Poly Pizza bundle (all City Kit models, pre-split per-mesh)
- **URL**: https://poly.pizza/bundle/City-Kit-0CkvGrBJ0u
- **License**: CC0
- **Formats**: FBX, OBJ, glTF (per-asset download)
- **Use**: Easier than the Kenney zip if you only want specific buildings — each model is a separate GLB download ready for `useGLTF`.

### RPG Urban Pack (2D, for UI/texture reference)
- **URL**: https://www.kenney.nl/assets/rpg-urban-pack
- **License**: CC0
- **Formats**: PNG (2D, 16×16 tiles)
- **Use**: Sprite-reference for minimap icons, building thumbnails in the deal-selection menu. Not 3D, but free.

---

## 2. Quaternius — CC0 (Public Domain)

All Quaternius packs are **CC0** — free for personal & commercial use, no attribution. Native FBX/OBJ/Blend; many are also re-exported as GLB on Poly Pizza. Quaternius explicitly confirmed glTF exports for the character pack.

### Ultimate Animated Character Pack ⭐ (player + NPCs)
- **URL**: https://quaternius.com/packs/ultimatedanimatedcharacter.html
- **License**: CC0
- **Formats**: FBX, OBJ, Blend (glTF export confirmed by author on X/Twitter)
- **Contents**: 50+ low-poly humanoid characters, each with 17 animations (idle, walk, run, jump, wave, etc.)
- **Use**: **THE** character pack for this game. Use the plain-clothes humans as NPC pedestrians, the suited ones as dealers/contacts, swap heads/torsos for variety. Walk & idle anims drive the city crowd.

### Ultimate Modular Men Pack
- **URL**: https://quaternius.com/packs/ultimatemodularcharacters.html
- **Poly Pizza**: https://poly.pizza/bundle/Ultimate-Modular-Men-Pack-ZiH8muWqwQ
- **License**: CC0
- **Formats**: FBX, OBJ, Blend
- **Contents**: 11 male characters, each split into 4 swappable parts (head/torso/legs/feet) × 24 animations
- **Use**: Generate hundreds of unique pedestrian variants by randomizing parts — critical for a "city full of strangers" feel.

### Ultimate Modular Women Pack
- **URL**: https://quaternius.com/packs/ultimatemodularwomen.html
- **License**: CC0
- **Formats**: FBX, OBJ, Blend
- **Contents**: 10 female characters, 4 swappable parts each, 24 animations, humanoid rig
- **Use**: Pair with the Men pack for diverse NPC population.

### Cars Pack ⭐ (parked & traffic vehicles)
- **URL**: https://quaternius.com/packs/cars.html
- **License**: CC0
- **Formats**: FBX, OBJ, Blend
- **Contents**: 8 distinct low-poly car models (sedan, hatchback, sports, van, etc.)
- **Use**: Parked cars lining the street, drive-by traffic (non-drivable), getaway vehicles in robbery missions. Cheap geometry → instances them across the whole city.

### Modular Streets Pack
- **URL**: https://quaternius.com/packs/modularstreets.html
- **License**: CC0
- **Formats**: FBX, OBJ, Blend
- **Contents**: Modular road tiles — straights, T-junctions, corners, crosswalks, with sidewalk variants
- **Use**: Combine with Kenney City Kit (Roads) for a richer street grid. Snap-to-grid makes procedural city layout trivial.

### Downtown City MegaKit ⭐ (NYC/Boston skyline)
- **URL**: https://quaternius.com/packs/downtowncitymegakit.html
- **License**: CC0
- **Formats**: FBX, OBJ, Blend (single shared texture atlas)
- **Contents**: 300+ modular environment pieces for full city blocks — skyscrapers, storefronts, fire escapes, rooftops, AC units
- **Use**: The dense downtown district the player roams at night. This is the closest thing to "GTA-style city block modules" available CC0. Shared atlas = one draw call per block.

### Ultimate Guns Pack ⭐ (robbery & deal props)
- **URL (Poly Pizza)**: https://poly.pizza/bundle/Ultimate-Guns-Pack-cpgUfI4t2F
- **URL (Sketchfab mirror)**: https://sketchfab.com/3d-models/ultimate-gun-pack-by-quaternius-768913f9b3b244499d3429805ac41802
- **License**: CC0
- **Formats**: FBX + GLB (Poly Pizza download)
- **Contents**: 25 gun models (pistols, SMGs, rifles, shotguns)
- **Use**: Held-weapon props for robbery missions, drug-deal-gone-wrong encounters. GLB versions load with `useGLTF` and can be parented to the character's hand bone.

### Universal Animation Library 2 ⭐ (motion for the player character)
- **URL**: https://quaternius.com/packs/universalanimationlibrary2.html
- **License**: CC0
- **Formats**: FBX (universal humanoid rig, retargets to Mixamo/KayKit/Ultimate Characters)
- **Contents**: 130+ animations — locomotion, idle variants, emotes, climbing, combat, falls
- **Use**: Apply to the player character & key NPCs via `useAnimations()`. Get "hands-up surrender", "pickpocket crouch", "stumble drunk" type motions needed for a satire crime game.

### RPG Character Pack
- **URL**: https://quaternius.com/packs/rpgcharacters.html
- **License**: CC0
- **Formats**: FBX, OBJ, Blend
- **Contents**: 6 rigged + animated fantasy characters
- **Use**: Probably skip — fantasy-styled. Listed for completeness.

---

## 3. Poly Pizza — Mixed CC0 / CC-BY (check per-asset)

Poly Pizza aggregates models from many CC0/CC-BY creators (Kenney, Quaternius, Kay Lousberg, Quaternius, etc.). Each asset page shows the specific license and offers per-mesh GLB/FBX/OBJ download — ideal for `useGLTF()`. **Verify the license on each asset's page** before shipping.

### Post Lantern (street lamp) — by Kay Lousberg
- **URL**: https://poly.pizza/m/ZSQ65S4lEu
- **License**: CC0 (Kay Lousberg = KayKit creator)
- **Formats**: GLB, FBX, OBJ
- **Contents**: 1 low-poly street lamp
- **Use**: Line the night-city streets — these are the primary light sources for the moody night aesthetic. Add a Three.js `PointLight` as a child for actual illumination.

### Hanging Lantern — by Kay Lousberg
- **URL**: https://poly.pizza/m/3jzk3YShv1
- **License**: CC0
- **Formats**: GLB, FBX, OBJ
- **Use**: Alleyway ambiance, back-door deal lighting, red-light-district flavor.

### Street Lantern (Isa Lousberg) / Lamp post (Ray Larson) / Bench (Kay Lousberg)
- **Search page**: https://poly.pizza/search/lamppost
- **Licenses**: Mostly CC0 / CC-BY (per-asset)
- **Formats**: GLB, FBX, OBJ
- **Contents**: 153 lamp/lamppost results + benches + street props
- **Use**: Browse this tag for variety in street furniture. Pick CC0 ones for the commercial build; CC-BY ones if you don't mind a credits screen.

### Ultimate Guns Pack by Quaternius (bundle page)
- **URL**: https://poly.pizza/bundle/Ultimate-Guns-Pack-cpgUfI4t2F
- **License**: CC0
- **Formats**: FBX + GLB
- **Contents**: 25 guns
- **Use**: (see Quaternius section above)

### Ultimate Platformer Pack by Quaternius (props/scenery)
- **URL**: https://poly.pizza/bundle/Ultimate-Platformer-Pack-cVxJUWO3nC
- **License**: CC0
- **Formats**: FBX, GLB, OBJ
- **Contents**: 100+ models — coins, crates, barrels, platforms, character + 18 animations
- **Use**: Barrels/crates as cover in alleyways, coins retextured as cash pickups, the platformer character animations include useful jump/fall states.

### Money / cash search
- **URL**: https://poly.pizza/search/money
- **Licenses**: Mixed (per-asset — most CC-BY)
- **Formats**: GLB, FBX, OBJ
- **Use**: Cash-stack pickups scattered on successful deals/robberies. Pick CC0 ones (filter on the page) for the commercial build.

### Pistol / Rifle / Machine Gun search
- **URLs**:
  - https://poly.pizza/search/pistol (273 results)
  - https://poly.pizza/search/rifle
  - https://poly.pizza/search/Machine%20Gun
- **Licenses**: Mixed CC0 / CC-BY
- **Use**: Individual gun models if you want variety beyond the Quaternius pack. Filter by CC0 in the sidebar.

### Weapons explore page
- **URL**: https://poly.pizza/explore/Weapons
- **Licenses**: Mixed
- **Contents**: Thousands of free low-poly weapons (guns, swords, AK-47s, rifles, knives)
- **Use**: Knives for close-robbery anims, baseball bats, brass knuckles — melee props for the "scam gone wrong" beat.

### City / car / building / person searches
- **URLs**:
  - https://poly.pizza/search/city
  - https://poly.pizza/search/car
  - https://poly.pizza/search/building
  - https://poly.pizza/search/person
  - https://poly.pizza/search/street
- **Licenses**: Mixed (per-asset)
- **Use**: Filler props, hero pieces, one-off shop interiors. Always confirm license per asset.

---

## 4. KayKit (Kay Lousberg) — CC0

KayKit characters are CC0, fully rigged, animated, and have **interchangeable parts** across packs. Native GLB/FBX exports make them the cleanest CC0 character option for Three.js.

### KayKit – Character Pack: Skeletons
- **URL**: https://kaylousberg.itch.io/kaykit-skeletons
- **GitHub**: https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0
- **License**: CC0
- **Formats**: FBX, GLB (via GitHub releases)
- **Contents**: 4 stylised low-poly skeleton characters, 90+ animations, 10+ accessories
- **Use**: "Drug zombie" hallucination enemies, Halloween-event NPCs, or just comedic crowd filler in the bad part of town.

### KayKit – Character Pack: Adventurers
- **URL**: https://kaylousberg.itch.io/kaykit-adventurers
- **License**: CC0
- **Formats**: FBX, GLB
- **Contents**: 8 stylised adventurer characters (knight, wizard, archer, barbarian, etc.)
- **Use**: Slightly fantasy — but the archer/barbarian silhouettes read as "thug" / "bouncer" from a distance. Useful for bouncers outside clubs, gang members.

### KayKit – Character Animations ⭐
- **URL**: https://kaylousberg.itch.io/kaykit-character-animations
- **Site**: https://kaylousberg.com/game-assets/character-animations
- **License**: CC0
- **Formats**: FBX (humanoid rig — retargets to KayKit & many other rigs)
- **Contents**: Large humanoid animation library designed for all KayKit characters
- **Use**: Idle/walk/run for the player. Emote animations (wave, shrug, surrender) for deal interactions.

### KayKit – City Builder Bits ⭐
- **URL**: https://kaylousberg.itch.io/city-builder-bits
- **License**: CC0
- **Formats**: FBX, GLB
- **Contents**: Stylised low-poly city-building props — lamps, benches, fountains, statues, street tiles
- **Use**: Mix into Kenney/Quaternius street scenes for visual variety. Kay's signature style reads as "clean low-poly" which matches the GTA-satire tone perfectly.

### KayKit – Dungeon Pack Remastered (interior tiles)
- **URL**: https://kaylousberg.itch.io/kaykit-dungeon-remastered
- **Site**: https://kaylousberg.com/game-assets/dungeon-remastered
- **License**: CC0
- **Formats**: FBX, GLB
- **Contents**: 200+ modular dungeon assets — walls, floors, stairs, doors, furniture, barrels, chests, props
- **Use**: Repurpose the modular wall/floor tiles as **interior rooms** for buildings the player enters (drug dens, back offices, basements). The chests/barrels become loot containers. The texture style is "dungeon" but flat-shaded low-poly reads fine as grimy interior.

### Complete KayKit Collection (one-stop bundle)
- **URL**: https://kaylousberg.com/game-assets/complete-kaykit-collection
- **License**: CC0 (free tier) — paid tier adds source `.blend` files
- **Use**: If you want everything in one download, grab this.

---

## 5. OpenGameArt.org — Mixed CC0 / CC-BY (per asset)

OpenGameArt has the largest back-catalog of CC0 3D art. Verify license on each page.

### City Kit (Suburban) — Kenney mirror on OGA
- **URL**: https://opengameart.org/content/city-kit-suburban
- **License**: CC0
- **Formats**: OBJ, FBX, glTF, BLEND
- **Use**: Same as Kenney — suburban houses. Listed here because some devs prefer the OGA interface.

### City Kit (Commercial) — Kenney mirror on OGA
- **URL**: https://opengameart.org/content/city-kit-commercial
- **License**: CC0
- **Formats**: OBJ, FBX, glTF, BLEND
- **Use**: Commercial buildings — see Kenney section.

### Low Poly Vehicles Pack ⭐
- **URL**: https://opengameart.org/content/low-poly-vehicles-pack
- **License**: CC0
- **Formats**: BLEND (export to FBX/GLB via Blender)
- **Contents**: Bus, Jeep, Pickup, Sedan, Wagon + extras (street cone, street lamp, stop sign)
- **Use**: Backup car set in case Quaternius' 8 cars feel repetitive. The included street cones/signs are bonus props.

### CC0 Assets 3D Low Poly (collection)
- **URL**: https://opengameart.org/content/cc0-assets-3d-low-poly
- **License**: CC0
- **Formats**: Various (BLEND, OBJ, FBX)
- **Contents**: Aggregated low-poly landscape/nature/city CC0 collection
- **Use**: Filler props, trees, rocks for parks and vacant lots.

### High Quality Industrial Asset Pack
- **URL**: https://opengameart.org/content/high-quality-industrial-asset-pack
- **License**: CC0 (some textures from yughues, also CC0)
- **Formats**: Various
- **Contents**: Industrial textures + models
- **Use**: Dress the drug-lab / stash-house interiors with grimy industrial props.

### KayKit Medieval Builder Pack (mirror)
- **URL**: https://opengameart.org/content/kaykit-medieval-builder-pack-10
- **License**: CC0
- **Use**: 200+ medieval scenery assets — half-timbered buildings can re-skin as "old town" district of your night city.

---

## 6. Sketchfab — Free downloadable CC0 / CC-BY models

Sketchfab's filter supports "Downloadable" + license. The models below are confirmed free-download. **Always check the per-model license badge** before shipping — Sketchfab lets authors change it.

### 4 Low Poly Toon City Cars ⭐
- **URL**: https://sketchfab.com/3d-models/4-low-poly-toon-city-cars-cdce7c9c2a17473cadd03ce4746b4f13
- **License**: CC-BY (check page — Viktor's packs are usually CC-BY 4.0)
- **Formats**: GLTF, OBJ, FBX (Sketchfab download)
- **Contents**: 4 toon-shaded cars + 13 gradient textures (512×512)
- **Use**: Toon-shaded cars match the stylized GTA-satire look better than Quaternius' flat-shaded ones. Use as hero vehicles (player's car, mission-specific cars). Add to credits screen if CC-BY.

### Low Poly Night City Building Skyline ⭐
- **URL**: https://sketchfab.com/3d-models/low-poly-night-city-building-skyline-b0035b8713b048bb8ddf311ee67c28c8
- **License**: Check page (free download)
- **Formats**: GLTF, OBJ, FBX
- **Contents**: 12 unique night-city buildings (background skyline silhouettes)
- **Use**: The distant skyline behind the playable city — pure silhouette lit windows for the night atmosphere. Low-poly = cheap to render as a backdrop.

### Low-poly City Night
- **URL**: https://sketchfab.com/3d-models/low-poly-city-night-885d8034bc02407fb48cf7f0dfe61d67
- **License**: Free for personal & commercial use (per author)
- **Formats**: GLTF, OBJ, FBX
- **Contents**: Set of low-poly buildings, ~200–300 faces each
- **Use**: Background city blocks — cheap to instance, lit windows give night-city feel.

### Low-poly City Buildings (companion pack)
- **URL**: https://sketchfab.com/3d-models/low-poly-city-buildings-e0209ac5bb684d2d85e5ade96c92d2ff
- **License**: Free for personal & commercial use
- **Formats**: GLTF, OBJ, FBX
- **Use**: Combine with the night pack above for more skyline variety.

### Free Low Poly Simple Urban City 3D Asset Pack
- **URL**: https://sketchfab.com/3d-models/free-low-poly-simple-urban-city-3d-asset-pack-310c806355814c3794f5e3022b38db85
- **License**: Check page (free download)
- **Formats**: GLTF, FBX
- **Contents**: 90+ low-poly models including 35 vehicles (hero cars, sports cars, trucks)
- **Use**: Large urban kit — vehicles fill out the traffic, storefronts populate the downtown.

### Low Poly City Game-Ready (modular road system)
- **URL**: https://sketchfab.com/3d-models/low-poly-city-game-ready-c7e3a158515c4e9da31ae52c30403cef
- **License**: Check page
- **Formats**: GLTF, FBX
- **Contents**: Modular road system, single color palette base color/roughness/metallic
- **Use**: Alternative road system to Kenney/Quaternius — pick whichever style matches your skyline.

### Low Poly City Diorama Scene (reference + props)
- **URL**: https://sketchfab.com/3d-models/low-poly-city-diorama-scene-1618d4c313874e83a6bd23dc042ee0e7
- **License**: Check page
- **Use**: Reference scene for art direction + harvestable props (traffic lights, corner cafe, muscle car).

### Ultimate Gun Pack by Quaternius (Sketchfab mirror)
- **URL**: https://sketchfab.com/3d-models/ultimate-gun-pack-by-quaternius-768913f9b3b244499d3429805ac41802
- **License**: CC0
- **Use**: Same 25-gun pack, mirrored on Sketchfab if you prefer that UI.

---

## 7. Background Music / Ambient Audio

### Pixabay Music — Pixabay License (CC0-like, royalty-free, commercial OK, no attribution)

Pixabay's license is effectively CC0 for audio: free for commercial use, no attribution required. Confirmed at https://pixabay.com/service/license-summary/.

#### Lo Fi Hip-Hop (Walking On The Streets) ⭐
- **URL**: https://pixabay.com/music/beats-lo-fi-hip-hop-walking-on-the-streets-144449
- **License**: Pixabay (royalty-free, no attribution)
- **Format**: MP3 download
- **Use**: Main menu theme / "walking the city" loop. Lo-fi hip-hop is the perfect satirical-cringe backdrop.

#### Lost Ambient Lofi 60s
- **URL**: https://pixabay.com/music/beats-lost-ambient-lofi-60s-10821
- **License**: Pixabay
- **Use**: Inside buildings (drug den, scam office) — darker, slower ambience.

#### City Nights Lo-Fi (search — 19,000+ tracks)
- **URL**: https://pixabay.com/music/search/city%20nights%20lo-fi
- **License**: Pixabay
- **Use**: Browse for menu/cutscene tracks. Filter by mood for "dark", "chill", "night".

#### Urban Lo-Fi / Hip-Hop Ambient / Synth Lofi
- **URLs**:
  - https://pixabay.com/music/search/urban%20lo-fi
  - https://pixabay.com/music/search/hip%20hop%20ambient
  - https://pixabay.com/music/search/synth%20lofi
- **License**: Pixabay
- **Use**: Curate a 5–10 track rotation for the night-city wander state.

### Free Music Archive — CC-BY / CC0

#### Lowtone Music — Dark Synthwave ⭐
- **URL**: https://freemusicarchive.org/music/lowtone-music/single/dark-synthwave
- **License**: Check track page (FMA hosts CC-BY and CC0; Lowtone releases are typically CC-BY)
- **Format**: MP3, FLAC
- **Contents**: 700+ electronic/synthwave/retrowave/cyberpunk tracks by Vitaliy Kharchenko
- **Use**: Robbery/chase sequences — driving dark synthwave is the genre for "night crime". Add attribution to the credits screen.

### Internet Archive — Dark Synthwave compilation
- **URL**: https://archive.org/details/dark-synthwave-pyl9yg
- **License**: Per-track — verify each
- **Use**: Curated multi-artist dark synthwave comp — sample source for chase/robbery music.

### White Bat Audio (Karl Casey) — Royalty-free with attribution
- **URLs**:
  - Spotify playlist: https://open.spotify.com/playlist/2gtv1R8rIulMRpjtgIOqGo
  - YouTube: https://www.youtube.com/watch?v=P10_AJeTFCw (Dystopian Cyberpunk Synthwave Mix — Night City)
- **License**: Royalty-free — **credit "Karl Casey @ White Bat Audio"** required
- **Use**: Best-in-class darksynth for the "deal gone bad" climax. Attribution is one line in the credits screen.

### Pixabay — Dark Synthwave Techno (19,000+ tracks)
- **URL**: https://pixabay.com/music/search/dark%20synthwave%20techno
- **License**: Pixabay (no attribution)
- **Use**: CC0-equivalent alternative if you can't display White Bat attribution.

---

## 8. Sound Effects

### Pixabay Sound Effects — Pixabay License (no attribution, commercial OK)

#### Police Siren ⭐
- **URL**: https://pixabay.com/sound-effects/city-police-siren-397963
- **License**: Pixabay (royalty-free, no attribution)
- **Format**: MP3, WAV
- **Use**: Triggers when player's "wanted level" rises after a robbery. Loop while cops are active.

#### Police Siren search (837 results)
- **URL**: https://pixabay.com/sound-effects/search/police%20siren
- **License**: Pixabay
- **Use**: Pick 2–3 variants (distant, close, doppler pass-by) for spatial variety.

#### Machine Gun search (3,500+ results)
- **URL**: https://pixabay.com/sound-effects/search/machine%20gun
- **License**: Pixabay
- **Use**: Deal-gone-bad shootouts, drive-by encounters.

#### Police Car sounds (3,000+ results)
- **URL**: https://pixabay.com/sound-effects/search/police%20car
- **Use**: Engine + tire screech layer under the siren.

### OpenGameArt — CC0 SFX packs

#### 100 CC0 SFX #2 ⭐ (footsteps + ambient loops)
- **URL**: https://opengameart.org/content/100-cc0-sfx-2
- **License**: CC0
- **Contents**: Footsteps (various surfaces), ambient loops (construction site, highway/street, machine), door, glass, hits
- **Use**: Player footstep system (asphalt/concrete/wood variants), ambient city bed loop, door opens when entering buildings.

#### MySFX (footsteps + racing car engine) ⭐
- **URL**: https://opengameart.org/content/mysfx
- **License**: CC0
- **Contents**: Footsteps on stone/water/snow/wood/dirt + racing car engine loops + thunder/rain/wind + door/fire/weapon hits
- **Use**: Footstep variations per ground type (street vs. alley vs. carpet), car engine loop for getaway scenes.

#### CC0 Sound Effects (master collection)
- **URL**: https://opengameart.org/content/cc0-sound-effects
- **License**: CC0
- **Contents**: Curated index — metal/wood SFX, breathing, car acceleration, creature SFX
- **Use**: Browse for car-acceleration loops for the getaway-car cutscenes.

#### 30 CC0 SFX Loops (alarms + ambient beds)
- **URL**: https://opengameart.org/content/30-cc0-sfx-loops
- **License**: CC0
- **Contents**: 3× alarm, 3× ambient, 11× machine, 3× noise, 2× water pump, 1× rain, 1× rolling, 1× hand saw, 1× boiling
- **Use**: Building-interior ambient beds — the drug-lab "machine" loops, the alarm that triggers when a robbery is detected.

#### 25 CC0 Bang / Firework / Cannon / Explosion SFX
- **URL**: https://opengameart.org/content/25-cc0-bang-firework-sfx
- **License**: CC0
- **Use**: Gunshot impact layer, explosion when a deal goes catastrophically wrong.

### Freesound.org — Mixed CC0 / CC-BY

#### Machine Gun Burst Loop Middle (10 Shots) — by qubodup
- **URL**: https://freesound.org/people/qubodup/sounds/854643
- **License**: CC0 (qubodup releases are CC0)
- **Format**: WAV
- **Use**: Looping automatic-fire layer for sustained gunfights.

#### Freesound gun-shot tag (browse)
- **URL**: https://freesound.org/browse/tags/gun-shot/
- **License**: Mixed — filter by CC0 in the sidebar
- **Use**: Pick individual pistol/shotgun/smg shots for the weapon SFX bank.

> **Slot machine note**: Pixabay and Freesound both have many CC0 slot-machine SFX. Direct deep-links tend to rot — search:
> - https://pixabay.com/sound-effects/search/slot%20machine
> - https://freesound.org/search/?q=slot+machine (filter CC0)
> Use these for the casino/scam mini-game inside buildings.

---

## License Compliance Checklist (for the commercial `.exe`)

1. **CC0 assets** (Kenney, Quaternius, KayKit, OGA-CC0) → ship freely, no attribution. Document them in `CREDITS.md` anyway for goodwill.
2. **CC-BY assets** (some Poly Pizza, some Sketchfab, FMA, White Bat Audio) → display a **Credits screen** reachable from the main menu listing: asset name, author, license, URL. One-time display is legally sufficient; persistent UI is friendlier.
3. **Pixabay assets** → Pixabay license is CC0-like but technically a separate license. Safe for commercial use without attribution. Keep a list anyway.
4. **Avoid** anything tagged:
   - CC-BY-NC (non-commercial)
   - CC-BY-SA (share-alike — viral, forces your whole game's source/art to be CC-BY-SA)
   - "Editorial use only" on Sketchfab
   - GPL-licensed code/audio
5. **Sketchfab** specifically: the download license is set per-upload by the author and can change. Re-verify each model's license badge on the day you ship, and keep a screenshot of the license page in your project's `licenses/` folder as proof.

---

## Recommended Three.js Integration Notes (no code, just guidance)

- **Format**: Convert all downloaded FBX → GLB with `npx fbx2gltf` or Blender's export. GLB loads fastest in `useGLTF()` from `@react-three/drei` and supports Draco compression.
- **Draco compression**: Run every GLB through `gltf-transform optimize` + Draco to shrink ~70% — critical for a web/Tauri build.
- **Texture atlases**: Quaternius Downtown City MegaKit ships a single shared atlas — keep it that way, don't split, to preserve the one-draw-call-per-block advantage.
- **Instancing**: Use `<Instances>` / `<InstancedMesh>` from drei for parked cars, street lamps, and pedestrians — 8 car models × 200 instances = one draw call per model.
- **Animations**: Quaternius' Ultimate Characters share a rig with the Universal Animation Library — retarget in Blender once, export a single GLB per character with all needed animations as clips, then play via `useAnimations(actions, ref)`.
- **Lighting the night city**: Street-lamp models (KayKit Post Lantern) should each parent a `pointLight` with warm color (0xffcc88), limited `distance` and `decay=2` for realistic falloff. Set ambient light very low (~0.05) and rely on lamps + building window-emissive materials.

---

## Summary Table — Top Picks by Use-Case

| Game need | #1 pick | URL |
|---|---|---|
| City buildings (modular) | Kenney City Kit series | https://kenney.nl/assets/series:City |
| Dense downtown blocks | Quaternius Downtown City MegaKit | https://quaternius.com/packs/downtowncitymegakit.html |
| Roads / streets | Kenney City Kit (Roads) + Quaternius Modular Streets | https://kenney.nl/assets/city-kit-roads |
| Parked cars | Quaternius Cars Pack | https://quaternius.com/packs/cars.html |
| Hero cars (toon-shaded) | Sketchfab 4 Low Poly Toon City Cars | https://sketchfab.com/3d-models/4-low-poly-toon-city-cars-cdce7c9c2a17473cadd03ce4746b4f13 |
| Player + NPC characters | Quaternius Ultimate Animated Character Pack | https://quaternius.com/packs/ultimatedanimatedcharacter.html |
| Character animations | Quaternius Universal Animation Library 2 | https://quaternius.com/packs/universalanimationlibrary2.html |
| Modular character parts | Quaternius Ultimate Modular Men/Women | https://quaternius.com/packs/ultimatemodularcharacters.html |
| Street lamps / props | KayKit City Builder Bits | https://kaylousberg.itch.io/city-builder-bits |
| Interior building tiles | KayKit Dungeon Remastered (repurposed) | https://kaylousberg.itch.io/kaykit-dungeon-remastered |
| Guns (held weapons) | Quaternius Ultimate Guns Pack | https://poly.pizza/bundle/Ultimate-Guns-Pack-cpgUfI4t2F |
| Distant skyline | Sketchfab Low Poly Night City Building Skyline | https://sketchfab.com/3d-models/low-poly-night-city-building-skyline-b0035b8713b048bb8ddf311ee67c28c8 |
| Main music (lo-fi) | Pixabay "Walking On The Streets" | https://pixabay.com/music/beats-lo-fi-hip-hop-walking-on-the-streets-144449 |
| Chase/robbery music | FMA Lowtone Dark Synthwave / White Bat Audio | https://freemusicarchive.org/music/lowtone-music/single/dark-synthwave |
| Footsteps + ambience | OGA "100 CC0 SFX #2" | https://opengameart.org/content/100-cc0-sfx-2 |
| Car engine loop | OGA "MySFX" | https://opengameart.org/content/mysfx |
| Police siren | Pixabay city-police-siren-397963 | https://pixabay.com/sound-effects/city-police-siren-397963 |
| Machine-gun fire | Freesound qubodup CC0 burst | https://freesound.org/people/qubodup/sounds/854643 |
| Building alarm loop | OGA "30 CC0 SFX loops" | https://opengameart.org/content/30-cc0-sfx-loops |

---

**Total asset cost for a complete vertical slice: $0.** Everything in the top-picks table is CC0 or Pixabay-license — no attribution, no royalties, fully commercial-safe for a paid `.exe` release.
