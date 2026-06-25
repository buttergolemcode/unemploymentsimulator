# Asset Inventory

All assets are CC0 (Public Domain). No attribution required, but credit appreciated.

## Inventory

### Kenney City Kit — Commercial (`kenney_city_commercial/`)
- **Source**: https://kenney.nl/assets/city-kit-commercial
- **License**: CC0
- **Format**: GLB (preferred), FBX, OBJ + Textures
- **Contents**: 42 commercial building models (shops, offices, diners)
- **Use**: Downtown core, scheme buildings for trading/wirefraud/taxfraud/casino

### Kenney City Kit — Suburban (`kenney_city_suburban/`)
- **Source**: https://kenney.nl/assets/city-kit-suburban
- **License**: CC0
- **Format**: GLB (preferred), FBX, OBJ + Textures
- **Contents**: 35+ suburban house models, fences, trees, props
- **Use**: Suburbs district, residential outskirts, slums (rundown variations)

### Kenney City Kit — Industrial (`kenney_city_industrial/`)
- **Source**: https://kenney.nl/assets/city-kit-industrial
- **License**: CC0
- **Format**: GLB (preferred), FBX, OBJ + Textures
- **Contents**: Warehouses, factories, silos, industrial props
- **Use**: Industrial district, drug lab / stash house locations, e-com warehouse

### Kenney City Kit — Roads (`kenney_city_roads/`)
- **Source**: https://kenney.nl/assets/city-kit-roads
- **License**: CC0
- **Format**: GLB (preferred), FBX, OBJ + Textures
- **Contents**: 65+ modular road tiles (straights, corners, intersections, crosswalks, sidewalks)
- **Use**: Build the street grid

### Quaternius Cars Pack (`quaternius_cars/`)
- **Source**: https://quaternius.com/packs/cars.html
- **License**: CC0
- **Format**: FBX (preferred), OBJ, Blend
- **Contents**: 7 low-poly car models (NormalCar1, NormalCar2, SportsCar, SportsCar2, SUV, Taxi, Cop)
- **Use**: Drivable vehicles (replace box-mesh cars). Cop car for Sprint D police

### Quaternius Ultimate Animated Character Pack (`quaternius_chars/`)
- **Source**: https://quaternius.com/packs/ultimatedanimatedcharacter.html
- **License**: CC0
- **Format**: Blend (only — needs Blender installed to convert to GLB)
- **Contents**: 50+ humanoid characters × 17 animations (idle, walk, run, jump, wave)
- **Use**: NPC pedestrians, merchants, player character model
- **NOTE**: `characters.blend` needs Blender installed for Godot import.
  Either install Blender OR download GLB versions from poly.pizza per-character.

### Quaternius Modular Streets Pack (`quaternius_streets/`)
- **Source**: https://quaternius.com/packs/modularstreets.html
- **License**: CC0
- **Format**: Blend (only — needs Blender installed to convert to GLB)
- **Contents**: Modular road tiles — straights, T-junctions, corners, crosswalks
- **Use**: Combine with Kenney City Kit (Roads) for richer street grid
- **NOTE**: `streets.blend` needs Blender for Godot import.

### KayKit City Builder Bits (`kaykit_city_bits/`)
- **Source**: https://kaylousberg.itch.io/city-builder-bits
- **License**: CC0
- **Format**: GLTF (preferred), FBX, OBJ + Textures
- **Contents**: Street props — lamps, benches, hydrants, planters, traffic lights, cars, buildings
- **Use**: Distribute street props, parking lot cars, traffic lights

## Status by Sprint D Sub-Step

| Sub-step | Asset Pack | Status |
|----------|-----------|--------|
| D.2 — Vehicle models | quaternius_cars | ✅ Ready (7 FBX cars) |
| D.3 — NPC models | quaternius_chars | ⚠️ Needs Blender or poly.pizza GLB fetch |
| D.4 — Buildings | kenney_city_* (4 packs) | ✅ Ready (GLB buildings) |
| D.5 — Roads | kenney_city_roads, quaternius_streets | ✅ Ready (Kenney GLB), ⚠️ Quaternius needs Blender |
| D.7 — Street props | kaykit_city_bits | ✅ Ready (GLTF props) |

## TODO

- [ ] Install Blender on user's machine OR fetch GLB versions of Quaternius chars/streets from poly.pizza
- [ ] Configure Godot import defaults for FBX/GLB (compression, textures)
- [ ] Build MeshLibrary from Kenney modular parts
