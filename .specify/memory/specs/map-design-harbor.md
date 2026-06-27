# Map Design Spec: Hafen

**Created**: 2026-06-27
**Status**: Draft
**Sprint**: D.4.5a — Layout Finalisierung
**Übergeordnete Spec**: [014-overall-map-design.md](./014-overall-map-design.md)

---

## Beschreibung

Ein Industrie-Hafen an der Südostküste der Insel. Containerschiffe docken an Piers an, Kräne laden und entladen Container, Lagerhallen säumen die Hafenstraße. Die Gegend ist funktional und rustikal — kein Tourismus, sondern harte Arbeit. Das Hafenbecken ist ein künstlicher Einschnitt in die Küstenlinie.

## Position auf der Insel

Südosten, direkt an der Küste. Angrenzend an:
- Nordwesten → NYC-Downtown (verbunden durch Hauptstraße)
- Südwesten → Slums/Suburbs (verbunden durch Küstenstraße)
- Norden → Portofino-Küstenstadt (verbunden durch Klippenweg/Küstenstraße)

## Topographie

- **Flach auf Meeresspiegel** (0m) — Hafen ist die tiefste besiedelbare Gegend
- Hafenbecken: künstlicher Einschnitt ins Land (200×400m), Wasserstand 0m
- Küstenlinie: hart und befestigt (Kaimauern, Beton), keine natürlichen Strände im Hafen selbst
- Nördlich des Hafens: Übergang zu Klippen (Portofino-Bereich)
- Südlich des Hafens: Übergang zu Brachland (Richtung Slums)

## Hafen-Infrastruktur

### Hafenbecken
- 200×400m großes Wasserbecken, Einschnitt in die Küste
- Geschützt durch Molen/Wellenbrecher an der Meeresseite
- Wasser: dunkleres Türkis als offenes Meer (#155f7a)

### Piers
- 4 Piers (je 120m lang, 20m breit), ragen ins Hafenbecken
- Beton-Oberfläche, befahrbar (Collision)
- Schiffe docken rechts und links der Piers an

### Schiffe
- 4 Containerschiffe (80m lang, 8m hoch, 15m breit)
- Dunkelblaue/navy Rümpfe, weiße Brücken-Aufbauten
- Fest an den Piers vertäut (nicht fahrbar)

### Kräne
- 8 Containerkräne auf den Piers
- Orange/rote Farbgebung (#d9531e)
- Turm + horizontaler Arm (visuell, nicht funktional)

### Container
- 80+ ISO-Container gestapelt auf Piers und am Kai
- 7 Farben: Rot, Blau, Grün, Gelb, Orange, Lila, Cyan
- 1-3 hoch gestapelt
- Container-Maße: 12m × 2.5m × 2.5m (40ft Standard)

## Architektur

- **Lagerhallen**: 10-25m hoch, flache Dächer, dunkle Farben (#1c1917, #292524, #44403c)
- **Hafengebäude**: 2-3 stöckig, funktionell (Büros, Zoll, Verwaltung)
- **Kaimauern**: Beton, grau, mit Pollern und Festmachtaugen
- **Farbpalette**: Dunkle Braun-/Grautöne, rostig, industiell
- **Material**: StandardMaterial3D, roughness 0.9-1.0, kein Glanz

## Scheme-Gebäude in dieser Gegend

Keine Scheme-Gebäude direkt im Hafen. Der Hafen ist eine Übergangs- und Atmosphäre-Gegend. Die nächsten Scheme-Gebäude sind im benachbarten Industrial-Bereich oder Downtown.

## Landmarks

- **Containerkräne**: Weithin sichtbar (bis 25m hoch), Orientierungspunkt vom Meer aus
- **Leuchtturm**: Am Ende der nördlichen Mole (Übergang zu Portofino-Klippen)
- **Fischmarkt**: Kleiner offener Bereich am Kai mit Kisten und Netzen (visuell)

## Straßen

- **Hafenstraße**: 8m breit, verläuft entlang des Kais, Asphalt mit Lkw-Spuren
- **Kai-Wege**: 4m breit, Beton, auf den Piers
- **Verbindung zu NYC**: Hauptstraße (2-spurig, 6m) die vom Hafen ins Stadtzentrum führt
- **Verbindung zu Slums**: Küstenstraße (2-spurig, 6m) nach Südwesten

## Übergang zu anderen Gegenden

| Richtung | Übergang |
|----------|----------|
| → NYC-Downtown (Nordwest) | Hauptstraße, Lagerhallen wechseln zu Bürogebäuden |
| → Slums/Suburbs (Südwest) | Küstenstraße, Brachland mit verlassenen Containern → Slum-Container |
| → Portofino (Nord) | Klippenweg, befestigte Küste wird zu natürlichen Klippen mit Pinien |

## NPCs

- Mittlere Dichte (15 NPCs), hafen-typisch: Hafenarbeiter, Lkw-Fahrer
- Farben: Dunkle Arbeitskleidung (#1c1917, #292524, #44403c)
