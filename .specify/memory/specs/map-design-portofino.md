# Map Design Inspiration: Portofino-Küstenstadt

**Created**: 2026-06-27
**Status**: Concept (revised)
**Sprint**: D.4.5a — Layout Finalisierung

---

## Portofino Referenz

Portofino ist ein Fischerdorf an der italienischen Riviera. Die Stadt liegt an einem **Hang der zum Meer hin abfällt** — wie eine nicht-steile Klippe. Das Terrain steigt vom Meer landeinwärts an, und die Stadt kaskadiert den Hang hinunter zur Küste.

### Schlüsselmerkmale
- **Hanglage**: Stadt liegt an einem Abhang, der vom Hinterland (höher) zum Meer (tiefer) abfällt
- **Kalkstein-Promontory**: Eine Halbinsel ragt ins Meer, mit Klippen die ins Wasser stürzen
- **Mondförmige Bucht**: Geschützter kleiner Hafen in einer Cove
- **Dichte Bebauung am Hang**: Häuser steigen den Hügel hinauf, stehen dicht an dicht
- **Pastellfarben**: Gelb, Rosa, Ocker, Terrakotta
- **Vegetation**: Pinien, Oliven, Macchia — grüne Hügel über der Stadt
- **Castello Brown**: Burg auf dem Hügel über dem Hafen
- **Klippen**: Steile Abstürze an der Küste (nicht überall — mancherorts sanfter Abfall)

### Topographie-Prinzip
Das Land fällt **von Westen (hoch) nach Osten (Meer, tief) ab** — wie eine geneigte Ebene mit Variationen. Nicht steil wie eine Klippe, sondern ein sanfter Hang mit lokalen Steigungen und Klippen an der Küste selbst.

---

## Unsere Stadt: Gesamt-Map mit Portofino-Küstenbereich

Die GESAMTE Map ist 3000×3000m. Portofino ist die Inspiration für den **Küsten/Hafen-Bereich** im Osten. Die anderen Districts haben ihre eigene Topographie.

### Höhenprofil (West → Ost — Land fällt zum Meer ab)

```
    WEST (hoch)                                    OST (Meer, tief)
    ═══════════════════════════════════════════════════════
    Canyon     Rural      Suburbs    Industrial  Downtown  Harbor   Meer
    100m+      60-80m     40-50m     20-30m      5-15m     0m       -3m
    Klippen    Hügel      Hänge      Plateau     Hang       Bucht
    ═══════════════════════════════════════════════════════
```

**Prinzip:** Das Land fällt sanft von Westen (Canyon, hoch) nach Osten (Meer, tief) ab. Jeder District liegt auf einer anderen Höhenstufe. Der Übergang ist nicht steil — es ist ein sanfter Hang, wie in Portofino.

### Districts mit Höhen und Terrain-Charakter

| District | Höhe (Y) | Terrain-Charakter | Portofino-Element |
|----------|----------|-------------------|-------------------|
| **Canyon** | 80-100m+ | Steile Klippen im Westen/Norden/Süden — undurchdringlich | Wie Portofinos Kalkstein-Berge |
| **Rural** | 60-80m | Sanfte Hügel, Wälder, Farms, dirt roads — höchste besiedelbare Ebene | Wie das Hinterland hinter Portofino |
| **Suburbs** | 40-50m | Rolgende Hänge, Cul-de-sac, Gärten, Pinien — mittlere Höhe | Wie Portofinos obere Wohnviertel |
| **Industrial** | 20-30m | Plateau (relativ flach), Fabriken, Silos — Übergang zum Stadtgebiet | — |
| **Downtown** | 5-15m | Sanfter Hang zum Hafen hin — Gebäude mit Meerblick, Skyline | Wie Portofinos Stadtkern am Hang |
| **Harbor** | 0m | Meeresspiegel, Bucht, Piers, Küstenklippen | Wie Portofinos Hafen |
| **Slums** | 5-15m | Zwischen Downtown und Harbor — Container am Hang | — |

### Küstenbereich (Portofino-inspiriert)

Der Osten der Map (Harbor + Küste) ist Portofino-inspiriert:

1. **Halbinsel/Promontory**: Eine Landzunge ragt ins Meer (im Harbor-Bereich). Auf der Halbinsel steht eine Festung/Leuchtturm (wie Castello Brown). Die Halbinsel hat steile Klippen zum Meer.

2. **Mondförmige Bucht**: Das Hafenbecken ist eine geschützte Cove (wie Portofinos Hafen). Piers und Schiffe liegen in der Bucht.

3. **Küstenklippen**: Südlich des Hafens — steile Abstürze ins Meer (wie Portofinos Kalksteinklippen). Autos können hier nicht runterfahren.

4. **Strand**: Nördlich des Hafens — sanfter Übergang vom Land zum Meer. Sand.

5. **Hang-Bebauung**: Downtown-Gebäude steigen den Hang vom Hafen hinauf. Höhere Gebäude haben Meerblick. Wie in Portofino, wo Häuser den Hügel hinaufkaskadieren.

6. **Küstenstraße**: Eine Straße verläuft entlang der Küste (wie Portofinos Lungomare).

### Farbschema

| Element | Farbe | Hex |
|---------|-------|-----|
| Meer | Türkis | #1a8ca8 |
| Hafenbecken | Dunkleres Türkis | #155f7a |
| Strand | Sand | #c4a875 |
| Klippen | Kalkstein | #7a7570 |
| Canyon-Wände | Dunkler Kalkstein | #5a5550 |
| Downtown Gebäude | Pastell: Ocker/Gelb/Rosa | #d4a574, #e8c89a, #d49a9a |
| Harbor Gebäude | Dunkles Holz/Stein | #3a3530 |
| Slums | Rostbraun, grau | #5a4030, #404040 |
| Industrial | Dunkelgrau, Metall | #2a2a2e |
| Suburbs | Warme Cremefarben | #e8dcc8 |
| Rural | Grünbraun | #4a5a2a |
| Vegetation | Mittelmeer-Grün | #3a5a2a |
| Straßen | Dunklasphalt | #1a1a1a |

---

## Implementierungs-Plan für Terrain

### terrain_height() Funktion

Das Land fällt von West (hoch) nach Ost (Meer, tief) ab. Die Höhe hängt primär von der X-Position ab:

- x < -1200: Canyon-Wände (steiler Anstieg auf 100m+)
- x -1200 bis -800: Rural (60-80m, sanfte Hügel mit fractal noise)
- x -1000 bis -400: Suburbs (40-50m, rollende Hänge)
- x -600 bis +200: Industrial (20-30m, relativ flaches Plateau)
- x +100 bis +800: Downtown (5-15m, sanfter Abfall zum Hafen)
- x +600 bis +1500: Harbor (0m, Meeresspiegel)
- x > +1500: Meer (-3m, unter Meeresspiegel)

Zusätzliche Variation durch fractal noise für natürliches Aussehen.

### Sichtbare Terrain-Features
1. **Sanfter Gesamthang**: Westen hoch → Osten tief (wie Portofino-Prinzip)
2. **Klippen an der Küste**: Steiler Abfall am Meer ( Harbor-Südküste)
3. **Halbinsel**: Landzunge mit Festung im Hafenbereich
4. **Canyon-Wände**: Sichtbares Terrain im Westen/Norden/Süden (nicht nur Collision)
5. **Hügel im Rural**: Fractal-noise Hügel, sichtbar und befahrbar
6. **Rollende Suburb-Hänge**: Sanfte Wellen im Terrain
7. **Downtown-Hang**: Gebäude stehen auf leichtem Gefälle zum Hafen
