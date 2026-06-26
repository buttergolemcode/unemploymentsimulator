# Map Design Inspiration: Portofino-Küstenstadt

**Created**: 2026-06-27
**Status**: Concept
**Sprint**: D.4.5a — Layout Finalisierung

---

## Portofino Referenz (aus Web-Recherche)

**Portofino** ist ein Fischerdorf an der italienischen Riviera, südöstlich von Genua. Schlüsselmerkmale:

### Geographie
- **Halbinsel/Promontory**: Ein quadratischer Kalkstein-Höhenrücken ragt ins Meer hinaus (~5km × 5km)
- **Monte di Portofino**: 610m hoher Berg im Zentrum der Halbinsel
- **Dichte Vegetation**: Pinien, Olivenbäume, Macchia — grüne Hügel über dem Meer
- **Kalkstein-Klippen**: Steile Küstenklippen, die ins türkise Meer abfallen
- **Mondförmiger Hafen**: Eine kleine, geschützte Bucht (Cove) die von der Halbinsel umschlossen wird
- **Terrassenlandschaft**: Angelegte Terrassen an den Hängen (historische Landwirtschaft)

### Architektur
- **Pastellfarbene Häuser**: Gelb, Rosa, Ocker, Terrakotta — leuchtende Farben
- **Dichte Bebauung**: Häuser stehen dicht an dicht, steigen den Hügel hinauf
- **Wasserfront**: Gebäude direkt am Wasser, mit kleinen Docks
- **Castello Brown**: Eine Burg/Festung auf dem Hügel über dem Hafen
- **Enge Gassen**: Schmale Straßen und Treppen zwischen den Häusern

### Atmosphäre
- Mittelmeerisches Licht — warm, gold
- Türkises Wasser
- Grüne Hügel im Hintergrund
- Luxuriös aber verwinkelt

---

## Unsere Stadt: "Portofino-Inspired Coastal City"

Unsere Stadt liegt **auf dem Hügel der Küste, etwas weiter landeinwärts** von der "Portofino"-Stadt. Das heißt:

### Topographie (Terrain)
- **Küstenlinie im Osten**: Das Meer ist im Osten, mit einer Halbinsel/Promontory die ins Meer ragt
- **Hügelige Küste**: Das Land steigt vom Hafen (Meeresspiegel) nach Westen an — Downtown liegt auf einem Hügel, Industrial/Suburbs noch höher, Rural in den Bergen
- **Canyon-Wände im Westen/Norden/Süden**: Steile Klippen als undurchdringliche Grenze (wie Portofinos Kalkstein)
- **Terrassen**: Sanfte Terrassen an den Hängen (visible terrain height variation)
- **Kleine Bucht (Hafen)**: Wie Portofinos mondförmiger Hafen — eine geschützte Bucht im Osten

### Höhenprofil (West → Ost)
```
    WEST (Berge/Canyon)                    OST (Meer)
    100m ─── Canyon-Wand ────────────────────────────
     80m ─── Rural (Hügel, Wälder) ──────────────────
     60m ─── Suburbs (sanfte Hänge) ─────────────────
     40m ─── Industrial (Plateau) ───────────────────
     20m ─── Downtown (Hügel mit Aussicht) ──────────
      0m ─── Harbor (Meeresspiegel) ──── Meer ──────
```

### Districts mit Höhen
| District | Höhe (Y) | Beschreibung |
|----------|----------|--------------|
| Harbor | 0m | Meeresspiegel, Hafenbecken, Piers, Schiffe |
| Downtown | 10-20m | Auf Hügel über dem Hafen, Aussicht aufs Meer, Skyline |
| Slums | 5-15m | Zwischen Downtown und Harbor, Container am Hang |
| Industrial | 30-40m | Plateau hinter Downtown, Fabriken, Silos |
| Suburbs | 50-60m | Sanfte Hänge, Wohnstraßen, Gärten, Bäume |
| Rural | 70-90m | Bergregion, Wälder, Farms, dirt roads |
| Canyon | 100m+ | Undurchdringliche Klippen |

### Küstenmerkmale
- **Halbinsel/Promontory**: Ein Landzunge ragt ins Meer (wie Portofino) — auf der Halbinsel steht ein Leuchtturm oder Festung
- **Strand**: Sandstrand nördlich des Hafens
- **Klippen**: Steile Abstürze südlich des Hafens (kein Strand, nur Fels)
- **Bucht**: Hafenbecken ist eine geschützte Bucht (wie Portofinos mondförmiger Hafen)

### Vegetation
- **Pinien und Olivenbäume** an den Hängen (Suburbs/Rural)
- **Macchia/Gebüsch** an Küstenklippen
- **Wälder** im Rural-Bereich (dichter Baumbestand)
- **Palmen** im Harbor/Downtown (Mediterranes Flair)

### Farbschema (Portofino-inspiriert)
| Element | Farbe | Hex |
|---------|-------|-----|
| Meer | Türkis | #1a8ca8 |
| Hafenbecken | Dunkleres Türkis | #155f7a |
| Downtown Gebäude | Pastell: Ocker/Gelb/Rosa/Terrakotta | #d4a574, #e8c89a, #d49a9a, #c97b50 |
| Harbor Gebäude | Dunkles Holz/Stein | #3a3530, #4a4035 |
| Slums | Rostbraun, grau | #5a4030, #404040 |
| Industrial | Dunkelgrau, Metall | #2a2a2e, #3a3a3e |
| Suburbs | Warme Cremefarben | #e8dcc8, #d4c8b0 |
| Rural | Grünbraun | #4a5a2a, #6b5b3a |
| Canyon | Kalkstein-Grau | #6a6560 |
| Vegetation | Mittelmeer-Grün | #3a5a2a, #4a6a3a |
| Straßen | Dunkelasphalt | #1a1a1a |

---

## Implementierungs-Plan für Terrain

### terrain_height() Funktion (neu)
```gdscript
static func terrain_height(x: float, z: float) -> float:
    # Harbor (x > 1000): sea level (0m)
    if x > 1200:
        return 0.0
    # Downtown (x: 100-800): gentle hill rising from harbor (0→20m)
    if x > 100 and x < 800:
        var dt_blend = (800 - x) / 700.0  # 0 at harbor edge, 1 at inland
        return dt_blend * 20.0 + _fractal_noise(x, z, 1) * 2
    # Industrial (x: -600 to 200): plateau at 35m
    if x > -600 and x < 200:
        return 35.0 + _fractal_noise(x, z, 1) * 3
    # Suburbs (x: -1000 to -400): rolling hills 50-60m
    if x > -1000 and x < -400:
        return 55.0 + _fractal_noise(x, z, 2) * 8
    # Rural (x: -1200 to -800): mountains 70-90m
    if x > -1200 and x < -800:
        var r_blend = (-800 - x) / 400.0
        return 70.0 + r_blend * 20.0 + _fractal_noise(x, z, 3) * 10
    # Canyon walls (x < -1200, z < -1200, z > 1200)
    ...steep rise to 100m+
    # Water (x > 1500)
    return -3.0
```

### Collision
- HeightmapShape3D oder dichte Grid-Collision die terrain_height folgt
- Jeder District hat seine eigene Höhenstufe
- Autos fahren bergauf/bergab (sichtbares Terrain mit Collision)

### Sichtbare Terrain-Features
1. **Hügel**: Downtown liegt auf einem Hügel — von Harbor aus sieht man Gebäude oben
2. **Klippen**: Canyon-Wände sind sichtbares Terrain (nicht nur Collision-Boxen)
3. **Küste**: Land fällt zum Meer ab — Strand/Klippen-Übergang
4. **Halbinsel**: Landzunge im Osten mit Festung/Leuchtturm
5. **Terrassen**: Sanfte Stufen im Terrain an Übergängen zwischen Districts
