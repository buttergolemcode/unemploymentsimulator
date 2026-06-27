# Feature Specification: Overall Map Design

**Feature Branch**: `014-overall-map-design`

**Created**: 2026-06-27

**Status**: Draft

**Input**: User description: "Die Map soll in mehrere Gegenden einer Art Insel sein. Gegend 1: Portofino Küstenstadt. Gegend 2: eine NYC-artige Gegend. 3: ein Hafen. 4: Slums/Suburbs. Alle verbunden mit Landstraßen oder Autobahnen."

## User Scenarios & Testing

### User Story 1 - Insel mit mehreren Gegenden (Priority: P1)

Die Spielwelt ist eine **ungleichmäßige, nicht-quadratische Insel** umgeben von Meer. Auf der Insel befinden sich **4 Hauptgegenden** die durch Landstraßen und Autobahnen verbunden sind. Jede Gegend hat ihre eigene visuelle Identität, Topographie und Architektur. Der Spieler kann frei zwischen allen Gegenden fahren/wandern.

**Why this priority**: Die Insel-Form und die multi-Gegenden-Struktur sind das Fundament der gesamten Welt — alles andere baut darauf auf.

**Independent Test**: Spiel starten → mit Noclip (F1) die Insel von oben betrachten → 4 visuell unterschiedliche Gegenden erkennen → Landstraßen/Highways zwischen ihnen sehen → Meer rundherum.

**Acceptance Scenarios**:
1. **Given** Spiel geladen, **When** Spieler von oben auf die Map schaut, **Then** eine unregelmäßige Inselform sichtbar (kein Quadrat, organische Küstenlinie).
2. **Given** Spieler ist in Gegend 1, **When** er einer Landstraße folgt, **Then** erreicht er Gegend 2 über eine befestigte Straßenverbindung.
3. **Given** Spieler fährt zum Inselrand, **When** Küste erreicht, **Then** Meer sichtbar, kein weiteres Land (Inselgrenze).

### User Story 2 - Verbunden durch Straßen (Priority: P1)

Alle 4 Gegenden sind durch **Landstraßen oder Autobahnen** verbunden. Es gibt keine isolierte Gegend die man nur zu Fuß erreichen kann. Die Verbindungsstraßen sind befahrbar und führen durch Übergangslandschaften (Wälder, Hügel, Küstenabschnitte) zwischen den Gegenden.

**Acceptance Scenarios**:
1. **Given** Spieler in Portofino-Küstenstadt, **When** Autobahn genommen, **Then** erreicht NYC-Downtown nach kurzer Fahrt.
2. **Given** Spieler in NYC-Downtown, **When** Landstraße nach Süden, **Then** erreicht Hafen-Gegend.
3. **Given** Spieler am Hafen, **When** Küstenstraße gefolgt, **Then** erreicht Slums/Suburbs.

---

## Gegenden-Übersicht

Die Insel besteht aus 4 Hauptgegenden. Jede Gegend hat eine eigene Spec mit detaillierter Beschreibung.

### Gegend 1: Portofino-Küstenstadt
- **Spec**: [map-design-portofino.md](./map-design-portofino.md)
- **Position auf Insel**: Nordosten
- **Charakter**: Mediterrane Küstenstadt am Hang, pastellfarbene Häuser, Pinien, Klippen die zum Meer abfallen, mondähnliche Bucht, Halbinsel mit Festung
- **Topographie**: Hang der zum Meer hin abfällt (wie Portofino), Klippen an der Küste
- **Architektur**: Pastellfarben, dichte Bebauung am Hang, enge Gassen
- **Vegetation**: Pinien, Oliven, Macchia

### Gegend 2: NYC-artige Downtown
- **Spec**: (noch zu erstellen — `map-design-nyc-downtown.md`)
- **Position auf Insel**: Zentrum / Südwesten
- **Charakter**: Manhattan-style Grid mit Wolkenkratzern, Skyline, breite Avenues, Sidewalks, Crosswalks
- **Topographie**: Relativ flach (Stadtzentrum auf ebenem Grund)
- **Architektur**: Hohe Gebäude (40-150m), Glasfassaden, kommerziell
- **Besonderheit**: 8 Scheme-Gebäude (Trading Floor, Corporate Tower, Accountant Office, Casino)

### Gegend 3: Hafen
- **Spec**: (noch zu erstellen — `map-design-harbor.md`)
- **Position auf Insel**: Südosten / Küste
- **Charakter**: Industrie-Hafen mit Piers, Containerschiffen, Kränen, Lagerhallen
- **Topographie**: Flach auf Meeresspiegel, Hafenbecken als Einschnitt
- **Architektur**: Niedrige Lagerhallen, Kräne, Container-Stapel
- **Besonderheit**: Piers befahrbar, Schiffe docken an

### Gegend 4: Slums / Suburbs
- **Spec**: (noch zu erstellen — `map-design-slums-suburbs.md`)
- **Position auf Insel**: Westen / Nordwesten
- **Charakter**: Zwei verschmolzene Gegenden — Container-Slums (eng, provisorisch) und Vororte (Cul-de-sac, Gärten, ruhig)
- **Topographie**: Leicht hügelig, Übergangslandschaft
- **Architektur**: Slums = gestapelte Container, Wohnwagen; Suburbs = kleine Häuser mit Vorgärten
- **Besonderheit**: Scheme Buildings (Trap House, Internet Cafe, Corner Store im Slum-Bereich)

---

## Insel-Form

Die Insel ist **nicht quadratisch** — sie hat eine organische, unregelmäßige Form mit:
- Buchten und Vorsprüngen an der Küste
- Unterschiedliche Küstentypen (Klippen, Strände, Hafenbecken)
- Die Insel ist grob **oval/bohnenförmig** mit Ausbuchtungen
- Geschätzt **2000-2500m Durchmesser** (kleiner als bisherige 3000m)

## Straßenverbindungen

| Verbindung | Straßentyp | Beschreibung |
|-----------|-----------|--------------|
| Portofino → NYC | Autobahn (4-spurig) | Küstenautobahn die von Nordosten nach Südwesten führt |
| NYC → Hafen | Hauptstraße (2-spurig) | Direkte Verbindung vom Zentrum zur Küste |
| Hafen → Slums/Suburbs | Landstraße (2-spurig) | Küstenstraße entlang der Südküste |
| Slums/Suburbs → Portofino | Landstraße (2-spurig) | Inlandstraße durch Hügel/Wald |
| Alle Gegenden | Ringstraße | Optional: Küstenringstraße die alle Gegenden verbindet |

## Übergangslandschaften

Zwischen den Gegenden gibt es **Übergangszonen** die nicht bebaut sind:
- **Waldstücke** zwischen NYC und Portofino
- **Hügel/Wiesen** zwischen Slums und NYC
- **Küstenufer** zwischen Hafen und Portofino (Klippenweg)
- **Brachland/Industrie-Rand** zwischen Hafen und Slums

Diese Zonen sind begehbar/befahrbar aber nicht dicht bebaut — sie geben der Welt Raum zum Atmen.

## Offene Fragen

- [ ] Exakte Inselform definieren (Heightmap-PNG mit organischer Küstenlinie)
- [ ] Spec für NYC-Downtown erstellen (`map-design-nyc-downtown.md`)
- [ ] Spec für Hafen erstellen (`map-design-harbor.md`)
- [ ] Spec für Slums/Suburbs erstellen (`map-design-slums-suburbs.md`)
- [ ] Höhenprofil pro Gegend definieren
- [ ] Heightmap-PNG für gesamte Insel generieren

## Requirements

### Functional Requirements

- **FR-001**: Die Map MUSS eine unregelmäßige Inselform haben (kein Quadrat, organische Küstenlinie)
- **FR-002**: Die Insel MUSS von Meer umgeben sein (Wasser an allen Seiten)
- **FR-003**: Die Insel MUSS mindestens 4 visuell unterschiedliche Gegenden enthalten
- **FR-004**: Alle Gegenden MÜSSEN durch befahrbare Straßen verbunden sein
- **FR-005**: Jede Gegend MUSS eine eigene Spec mit detaillierter Beschreibung haben
- **FR-006**: Übergangszonen zwischen Gegenden MÜSSEN nicht dicht bebaut sein
- **FR-007**: Die Küstenlinie MUSS unterschiedliche Typen haben (Klippen, Strände, Hafenbecken)

### Key Entities

- **Insel**: Die gesamte Spielwelt — unregelmäßige Form, Meer umgeben
- **Gegend**: Ein abgegrenzter Bereich der Insel mit eigener Identität (Portofino, NYC, Hafen, Slums/Suburbs)
- **Verbindungsstraße**: Befahrbare Straße zwischen zwei Gegenden (Autobahn oder Landstraße)
- **Übergangszone**: Nicht bebaute Landschaft zwischen Gegenden

## Success Criteria

- **SC-001**: Insel hat organische Form (kein Quadrat erkennbar)
- **SC-002**: 4 Gegenden sind visuell klar unterscheidbar
- **SC-003**: Alle Gegenden durch Straßen erreichbar
- **SC-004**: Meer an allen Inselrändern sichtbar
- **SC-005**: Jede Gegend hat verlinkte Spec

## Assumptions

- Inselgröße ca. 2000-2500m Durchmesser (kompakter als bisherige 3000m)
- Heightmap-PNG wird per Python generiert (wie bisher, aber mit Inselform)
- Jede Gegend kann auf der Heightmap als abgegrenzter Bereich identifiziert werden
- Die Portofino-Spec existiert bereits und wird verlinkt
