# Map Design Spec: Slums / Suburbs

**Created**: 2026-06-27
**Status**: Draft
**Sprint**: D.4.5a — Layout Finalisierung
**Übergeordnete Spec**: [014-overall-map-design.md](./014-overall-map-design.md)

---

## Beschreibung

Zwei verschmolzene Gegenden im Westen/Nordwesten der Insel: **Container-Slums** (provisorisch, dicht, verwahrlost) und **Suburbs** (ruhige Vororte mit Cul-de-sac, Gärten, Zäunen). Die beiden Bereiche gehen direkt ineinander über — die Slums sind der ärmere Rand der Vororte, die Vororte der wohlhabendere Teil. Zusammen bilden sie den westlichen Teil der Insel.

## Position auf der Insel

Westen bis Nordwesten. Angrenzend an:
- Osten → NYC-Downtown (verbunden durch Landstraße durch Hügel/Wald)
- Süden → Hafen (verbunden durch Küstenstraße)
- Norden → Portofino-Küstenstadt (verbunden durch Inlandstraße)

## Topographie

- **Leicht hügelig** (10-30m Höhe) — sanfte Wellen, keine steilen Hänge
- Slums-Bereich: flacher, am Übergang zum Hafen (niedriger)
- Suburb-Bereich: sanft ansteigend Richtung Inselinneres (höher)
- Übergangszone zwischen Slums und Suburbs: allmählicher Höhenanstieg

## Slums: Container-Slum

### Layout
- **Kein Grid** — irreguläre, organische Anordnung
- **Enge Gassen** zwischen Containern (2-3m breit, Labyrinth-Feeling)
- Keine echten Straßen, nur Fußwege und schmale Durchgänge
- Eine Hauptgasse die durch den Slum führt (4m breit, Schotter)

### Behausungen
- **Gestapelte ISO-Container** als Häuser (1-3 hoch, 12m × 2.5m × 2.5m)
- **Wohnwagen/Busse** als alternative Behausungen
- **Provisorische Anbauten**: Planen, Bretter, Wellblech zwischen Containern

### Props
- Müllberge und Mülltonnen
- Graffiti an Containern (decals, visuell)
- Kaputte/verlassene Autos
- Campfire/Fässer mit Feuer (visuell, OmniLight bei Nacht)
- Wäscheleinen zwischen Containern

### Farben
- Rostbraun (#5a4030), Grau (#404040), Schmutziges Beige (#6b5b3a)
- Container: gedämpfte Versionen der Hafen-Container-Farben (verblasst, rostig)
- Material: roughness 1.0, kein Glanz, matt

### Scheme-Gebäude im Slum

| Scheme | Position (relativ) | Beschreibung |
|--------|-------------------|--------------|
| Trap House | Zentrum des Slums | Container-Haus, erhöht, mit "Apotheke"-Markierung |
| Internet Cafe | Rand des Slums (Richtung Hafen) | Container mit Sat-Schüsseln, Kabeln außen |
| Corner Store | Hauptgasse | Kleiner Kiosk/Laden aus Holz und Wellblech |

---

## Suburbs: Cul-de-sac

### Layout
- **Kein Grid** — gebogene Wohnstraßen die sich schlängeln
- **Cul-de-sac**: Sackgassen mit runden Enden (T-förmig oder kreisförmig)
- Wenig Durchgangsverkehr — ruhige Wohngegend
- Häuser stehen an den Sackgassen, nicht an Durchgangsstraßen

### Häuser
- **Kleine Einfamilienhäuser** (5-10m hoch, 8-12m breit)
- Mit **Vorgärten** (2-4m tief, Gras, Blumen, kleine Bäume)
- **Einfahrten** (Parkerplätze vor dem Haus, 5m × 3m)
- **Zäune** zwischen Grundstücken (1.5m hoch, Holz oder Metall)
- **Garagen** an einigen Häusern (6m × 4m, Rolltor)

### Props
- Straßenbäume (alle 20m, Laubbäume)
- Briefkästen an Grundstücksgrenzen
- Mülltonnen am Straßenrand
- Spielplatz in einer Sackgase (Wippe, Schaukel, Sandkasten — visuell)

### Farben
- Warme Cremefarben (#e8dcc8), Hellbeige (#d4c8b0), Sanftes Weiß (#f5f5f5)
- Dächer: Ziegelrot (#9a5040) oder Dunkelgrau (#404040)
- Zäune: Naturholz (#8a6a3a) oder Weiß (#e0e0e0)
- Material: roughness 0.9, leicht glänzend (gut gepflegt)

### Scheme-Gebäude
Keine Scheme-Gebäude in den Suburbs. Die Suburbs sind eine reine Wohn-/Atmosphäre-Gegend.

---

## Übergang: Slums → Suburbs

Der Übergang ist **fließend**, keine harte Grenze:
1. Container werden weniger, dafür mehr provisorische Holzhütten
2. Holzhütten werden zu kleinen Häusern mit Vorgärten
3. Gassen werden zu Wohnstraßen
4. Müll verschwindet, Zäune erscheinen
5. Schotterwege werden zu Asphalt

## Übergang zu anderen Gegenden

| Richtung | Übergang |
|----------|----------|
| → NYC-Downtown (Ost) | Landstraße durch Hügel/Wald, Häuser werden größer → Bürogebäude |
| → Hafen (Süd) | Küstenstraße, Slum-Container → Hafen-Container (visuell ähnlich, aber Hafen ist ordentlicher) |
| → Portofino (Nord) | Inlandstraße, Suburb-Häuser → Pinien/Hügel → Portofino-Bebauung |

## NPCs

- **Slums**: Hohe Dichte (30 NPCs), verwahrlost aussehend, Farben: Brauntöne (#7c2d12, #9a3412, #451a03)
- **Suburbs**: Mittlere Dichte (15 NPCs), gepflegt, Farben: Grau/Hellblau (#525252, #737373, #404040)
