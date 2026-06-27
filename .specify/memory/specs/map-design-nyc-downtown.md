# Map Design Spec: NYC-artige Downtown

**Created**: 2026-06-27
**Status**: Draft
**Sprint**: D.4.5a — Layout Finalisierung
**Übergeordnete Spec**: [014-overall-map-design.md](./014-overall-map-design.md)

---

## Beschreibung

Eine Manhattan-inspirierte Downtown-Gegend im Zentrum/Südwesten der Insel. Das städtische Herzstück mit Wolkenkratzern, breiten Avenues, Sidewalks und dem Großteil der Scheme-Gebäude. Die Gegend ist relativ flach (Stadtzentrum auf ebenem Grund) und dicht bebaut.

## Position auf der Insel

Zentrum bis Südwesten. Die Gegend ist von den anderen drei Gegenden umgeben:
- Nordosten → Portofino-Küstenstadt (verbunden durch Küstenautobahn)
- Südosten → Hafen (verbunden durch Hauptstraße)
- Westen → Slums/Suburbs (verbunden durch Landstraße durch Hügel/Wald)

## Topographie

- **Relativ flach** (0-10m Höhe) — Stadtzentrum auf ebenem Grund
- Leichte Hangneigung Richtung Hafen (Südosten), so dass Wolkenkratzer vom Hafen aus sichtbar sind
- Keine natürlichen Hügel innerhalb der Gegend — komplett urban

## Straßen-Layout

- **NYC-Style Grid**: 100m Block-Abstand, 7 Avenues pro Achse
- **Hauptavenues**: 8m breit (2 Spuren), mit Sidewalks (2.5m), Crosswalks an Kreuzungen
- **Side Streets**: 6m breit, schmale Sidewalks
- **Alleyways**: 3m, Kopfsteinpflaster, keine Sidewalks (Hinterhöfe)
- Klare Zonen-Hierarchie: STREET → SIDEWALK → BUILDING

## Architektur

- **Wolkenkratzer**: 40-150m hoch, Glasfassaden (dunkelblau/schwarze Metalle), emissive Fenster bei Nacht
- **Mittlere Bürogebäude**: 20-40m, grau/anthrazit
- **Kleinere Gebäude**: 10-20m, an Side Streets
- **Farbpalette**: Dunkelblau (#1e293b), Anthrazit (#334155), Schwarz (#0f172a), Stahlblau (#1e3a5f)
- **Material**: StandardMaterial3D mit metalness 0.6-0.7, roughness 0.2-0.3 (Glas-Look)
- **Beleuchtung bei Nacht**: Emissive Fenster (cyan/blue glow)

## Scheme-Gebäude in dieser Gegend

| Scheme | Position (relativ) | Beschreibung |
|--------|-------------------|--------------|
| Trading Floor | Zentrum-Nord | Mittelgroßer Wolkenkratzer (70m) |
| Corporate Tower | Zentrum-Ost | Größter Wolkenkratzer (120m), skyline-dominant |
| Accountant Office | Side Street Süd | Kleineres Bürogebäude (35m) |
| Casino | Hauptavenue Ost | Auffälliges Gebäude (28m), neon beleuchtet |

## Landmarks

- **Skyline-Reihe**: 3 besonders hohe Wolkenkratzer (110/140/120m) die als Orientierungspunkt dienen
- **Central Park**: Grüne Fläche mit Bäumen im Stadtzentrum (bereits implementiert)
- **Bus Station**: Nahverkehrsknotenpunkt
- **Gas Station**: An der Autobahn-Einfahrt

## Übergang zu anderen Gegenden

| Richtung | Übergang |
|----------|----------|
| → Portofino (Nordost) | Küstenautobahn durch Waldstück, Gebäude werden niedriger, dann pastellfarben |
| → Hafen (Südost) | Hauptstraße, Gebäude wechseln von Glas zu Industrie-Lagerhallen |
| → Slums/Suburbs (Westen) | Landstraße durch Hügel, Gebäude werden kleiner und wohnlicher |

## NPCs

- Hohe Dichte (35+ NPCs), hauptsächlich Geschäfts-Leute/Gehende
- Farben: Dunkle Anzug-Farben (#1e293b, #0f172a, #374151, #4b5563)
