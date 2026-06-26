# Map Design Spec — (Put the) Fries in the Bag

**Created**: 2026-06-27
**Status**: Locked
**Sprint**: D.4.5a — Layout Finalisierung

---

## Map-Form: Küstenstadt

Wasser im Osten (Hafen/Küste), Berge/Canyon-Wände im Westen/Norden/Süden. Keine Insel — die Stadt liegt an der Küste eines Festlands.

## Map-Größe: 3000×3000m

Spielbare Fläche: -1500 bis +1500 auf beiden Achsen.
- City area (Districts): ca. -1000 bis +1500 (Osten = Küste)
- Rural/Hinterland: ca. -1500 bis -1000 (Westen = Berge)
- Wasser: ab x=+1500 nach Osten (Ozean)

## District-Anordnung: Küstenstreifen (Ost → West)

```
     NORD (Canyon-Wand, -1500)
     ====================================================================
     
     RURAL        SUBURBS       INDUSTRIAL     DOWNTOWN      HARBOR
     (West)       (West-Mitte)  (Mitte)        (Ost-Mitte)   (Küste, Osten)
     -1500..-800  -1000..-400   -600..+200     +100..+800    +600..+1500
                                       
     ↑ Berge      ↑ Cul-de-sac  ↑ Fabriken     ↑ Wolkenkr.    ↑ Piers
     ↑ Wälder     ↑ Gärten      ↑ Silos        ↑ Skyline      ↑ Schiffe
     ↑ Farms      ↑ Zäune       ↑ Highway      ↑ Casino       ↑ Kräne
     
     ====================================================================
     SÜD (Canyon-Wand, +1500)
     
     WASSER (Ozean, ab x=+1500 nach Osten)
```

**District-Größen (X-Ausdehnung, alle ca. 1000m in Z-Richtung):**
- Rural: 700m breit (-1500 bis -800)
- Suburbs: 600m breit (-1000 bis -400)
- Industrial: 800m breit (-600 bis +200)
- Downtown: 700m breit (+100 bis +800)
- Harbor: 900m breit (+600 bis +1500, inkl. Wasserbecken)

## District-Grenzen (Mix)

| Zwischen | Grenz-Typ | Beschreibung |
|----------|-----------|--------------|
| Rural → Suburbs | Höhenunterschied + Wald | Sanfter Anstieg, dichter Wald als Puffer |
| Suburbs → Industrial | Highway | Ring-Highway trennt Wohnen von Industrie |
| Industrial → Downtown | Park/Grünzug | Breiter Grüngürtel mit Bäumen |
| Downtown → Harbor | Fluss + Brücken | Kurzer Fluss mündet ins Hafenbecken, 2-3 Brücken |
| Alle → Außen | Canyon-Wand | Steile Klippen im Norden/Süden/Westen |

## Berge: Canyon/Wand

- Steile Klippen an 3 Seiten (Norden, Süden, Westen), nicht im Osten (Wasser)
- Höhe: 80-120m, sichtbar von überall in der Stadt (Skyline-Blocker)
- Farbe: Dunkler Stein (Grau/Braun), leicht textured
- Collision: Undurchdringlich (BoxShape3D hinter sichtbarer Geometrie)
- Aussehen: Wie ein Tal — Stadt liegt in einem Canyon/Einschnitt

## Highways

### Ring-Highway
- Verläuft im Bogen um die Stadt (Norden, Süden, Westen — nicht Osten, da Wasser)
- 4-spurig, mit Mittelleitplanke
- Verbindet alle Districts von außen
- Ausfahrten zu jedem District

### Ausfallstraßen
- 2-3 Highways die aus der Stadt nach Westen führen (in die Berge)
- Enden an Canyon-Wänden (Sackgasse — "End of the Road")
- Eine Ausfallstraße führt nach Norden (in Wald/Berge)

### Inner-District Highway
- Eine Schnellstraße die Hafen → Downtown → Industrial verbindet
- 2-spurig, erhöhlt (Viadukt) an einigen Stellen
- Schnelle Verbindung zwischen den wichtigsten Districts

## Slums: Container-Slum

- Kein Grid — irreguläre Anordnung
- Gestapelte Container als "Häuser" (1-3 hoch)
- Wohnwagen/Busse als Behausungen
- Enge Gassen zwischen Containern
- Müllberge, Graffiti, kaputte Autos als Props
- Position: Südrand von Downtown/Industrial (Übergangszone)
- Scheme Buildings: Trap House, Internet Cafe, Corner Store

## Suburbs: Cul-de-sac

- Gebogene Wohnstraßen (kein Grid)
- Sackgassen mit runden Enden (Cul-de-sac)
- Häuser mit Vorgärten, Einfahrten, Zäunen
- Wenig Durchgangsverkehr — ruhige Wohngegend
- Bäume entlang der Straßen
- Position: Westlich von Industrial

## Scheme Building Positionen

| Scheme | District | Position (X, Z) | Beschreibung |
|--------|----------|-----------------|--------------|
| Trading Floor | Downtown | (+300, -100) | Wolkenkratzer im Financial District |
| Corporate Tower | Downtown | (+500, +100) | Größter Wolkenkratzer (Skyline-Dominant) |
| Accountant Office | Downtown | (+200, +200) | Kleineres Bürogebäude an Side Street |
| Casino | Downtown | (+600, -200) | Auffälliges Gebäude an Main Avenue |
| Trap House | Slums | (+100, +500) | Container-Häuser im Slum-Gebiet |
| Internet Cafe | Slums | (+50, +600) | Container mit Sat-Schüsseln |
| Corner Store | Slums | (+150, +550) | Kleiner Kiosk/Laden |
| E-Com Warehouse | Industrial | (-200, -100) | Große Lagerhalle im Industriegebiet |

## Küstenlinie / Hafen

- Küste verläuft vertikal entlang x=+1500 (Osten)
- Hafenbecken: Einschnitt ins Land (200×400m), bei x=+1200 bis +1500
- 4 Piers (je 120m lang, 20m breit) ragen ins Becken
- 4 Containerschiffe an den Piers
- 8 Kräne entlang der Piers
- 80+ Container gestapelt auf Piers
- Strand/Küste nördlich und südlich des Hafens (Sand, nicht bebaubar)

## Rural / Hinterland

- Farms (Scheunen, Felder, Traktoren als Props)
- Dirt Roads (Schotterstraßen, kein Asphalt)
- Dichte Wälder an Grenze zu Suburbs (Übergangszone)
- Bergbach/Fluss der aus den Bergen kommt
- Einsame Landstraße die durchs Rural führt
- Sehr wenige NPCs (3-5), keine Scheme Buildings

## Straßen-Hierarchie

| Straßentyp | Breite | Wo | Aussehen |
|-----------|--------|-----|---------|
| Highway | 16m (4 Spuren) | Ring + Ausfall + Inner-District | Asphalt, Mittelleitplanke, Guardrails |
| Main Avenue | 8m (2 Spuren) | Downtown Grid, Hafenstraße | Asphalt, Sidewalks, Lane Markings |
| Side Street | 6m (1.5 Spuren) | Suburbs, Industrial | Asphalt, schmale Sidewalks |
| Alleyway | 3m | Slums, Downtown Hinterhöfe | Kopfsteinpflaster, keine Sidewalks |
| Dirt Road | 4m | Rural | Schotter/Erde, keine Markierungen |
| Cul-de-sac | 5m | Suburbs | Asphalt, runde Enden, Vorgärten |

## Skalierung

- 1 Godot-Einheit = 1 Meter
- Spieler: 1.7m
- Auto: 4.5m lang, 2.0m breit
- Straßenblock (Downtown): 100m × 100m
- Straßenblock (Suburbs): 50m × 80m (ungerade Formen)
- Slum-Container: 6m × 2.5m × 2.5m (Standard-Container-Maße)
- Hafen-Pier: 120m × 20m
- Bergwand: 100m hoch, 200m tief
