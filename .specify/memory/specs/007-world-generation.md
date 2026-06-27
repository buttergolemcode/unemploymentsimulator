# Feature Specification: World Generation & City Layout

**Feature Branch**: `007-world-generation`

**Created**: 2026-06-27

**Status**: Implemented (retroactive spec)

## User Scenarios & Testing

### User Story 1 - NYC-Style Grid City (Priority: P1)

The world is a 1200×1200m playable area with a Manhattan-style street grid. 7 streets per axis (at -300, -200, -100, 0, 100, 200, 300) create 6×6 = 36 city blocks. Each block contains 2×2 to 3×3 buildings depending on district.

**Acceptance Scenarios**:
1. **Given** game loads, **When** WorldBuilder.build_world() runs, **Then** streets form a clean grid with 100m block spacing.
2. **Given** player stands at intersection (0, 0), **Then** 4 streets are visible (N/S/E/W) with sidewalks and crosswalks.

### User Story 2 - District System (Priority: P1)

6 districts with polygon-based boundaries: downtown (center), harbor (east), slums (SW), industrial (NW), suburbs (west), rural (outside city). Each district has distinct building styles, colors, and height ranges.

**Acceptance Scenarios**:
1. **Given** player is at (0, 0), **When** get_district_at(0, 0) is called, **Then** returns "downtown".
2. **Given** player is at (-300, 300), **When** get_district_at is called, **Then** returns "slums".
3. **Given** player is at (500, 0), **When** get_district_at is called, **Then** returns "harbor".

### User Story 3 - Sidewalks with Collision (Priority: P1)

Every street segment has raised sidewalks (visual 15cm, collision 5cm) on both sides. Sidewalks are broken at intersections and connected with corner pieces. Crosswalks (zebra stripes) span intersections.

**Acceptance Scenarios**:
1. **Given** car drives toward a sidewalk, **When** car reaches sidewalk edge, **Then** car drives up onto sidewalk (floor_snap handles 5cm step).
2. **Given** player walks toward intersection, **Then** sidewalk corners are visible (no gaps) and crosswalk stripes span the road.

### User Story 4 - Terrain & Mountain Walls (Priority: P2)

Terrain is flat in the city (y=0), rises gently in rural zone (fractal noise hills), and has impassable mountain walls at map edges. Water is on the east side (harbor).

**Acceptance Scenarios**:
1. **Given** player drives to map edge (x > 600), **Then** mountain wall blocks further movement.
2. **Given** player is in rural zone (r > 580), **Then** terrain has gentle hills with collision (50m grid of BoxShape3D).

### User Story 5 - Landmarks (Priority: P3)

8 landmarks provide orientation: Central Park, 3-tower skyline row, suspension bridge, stone fortress, oval stadium, church tower (removed), bus station, 2 gas stations.

**Acceptance Scenarios**:
1. **Given** player is in downtown south, **Then** Central Park is visible with trees and "PARK" label.
2. **Given** player looks east in downtown, **Then** 3 tall skyscrapers (110/140/120m) form a skyline row.

## Requirements

### Functional Requirements

- **FR-001**: Map size: 1200×1200m playable, water at x>600, mountains at x<-600, z<-600, z>600
- **FR-002**: Street grid: 7 positions per axis [-300, -200, -100, 0, 100, 200, 300], 100m blocks
- **FR-003**: Road: 8m wide (ROAD_HALF_WIDTH=4.0), dark asphalt BoxMesh at y=0.03
- **FR-004**: Sidewalk: 2.5m wide, 15cm visual height, 5cm collision height, light gray
- **FR-005**: Sidewalk collision: BoxShape3D at 5cm height (floor_snap compatible)
- **FR-006**: Sidewalk segments: broken at intersections (gap = ROAD_HALF_WIDTH + SIDEWALK_WIDTH)
- **FR-007**: Sidewalk corners: square pieces at each intersection corner (4 per intersection)
- **FR-008**: Crosswalks: 6 white stripes (0.6m wide, 7.5m long) per intersection leg, 4 legs per intersection
- **FR-009**: Lane markings: dashed yellow center line, broken at intersections
- **FR-010**: 6 districts with PackedVector2Array polygons, lookup via Geometry2D.is_point_in_polygon()
- **FR-011**: District building styles: downtown (glass skyscrapers 40-150m), harbor (warehouses 10-25m), slums (brick houses 4-10m), industrial (factories 10-30m), suburbs (light houses 5-10m)
- **FR-012**: Block-based building placement: 2×2 = 4 buildings per block (3×3 = 9 in slums)
- **FR-013**: Terrain: flat city (y=0), rural hills (fractal noise), mountain walls (impassable BoxShape3D)
- **FR-014**: Rural collision: 50m grid of BoxShape3D matching terrain_height()
- **FR-015**: City ground collision: BoxShape3D 1200×1×1200 at y=-0.5
- **FR-016**: Water plane: 2400×2400 at y=-3.0, east side
- **FR-017**: Harbor: basin (200×300m), 3 piers (120×20m with collision), 3 ships (80×8×15m), 60 containers, 6 cranes
- **FR-018**: 8 landmarks: park (with curb border + trees + label), skyline (3 towers), bridge, fortress, stadium, bus station, 2 gas stations
- **FR-019**: Terrain mesh: 1400×1400, 120 subdivisions, vertex-colored by district
- **FR-020**: DISTRICTS dict built at runtime via _init_districts() (PackedVector2Array can't be in const)

## Success Criteria

- **SC-001**: City has clean NYC-style grid with 36 blocks
- **SC-002**: Each district visually distinct (colors, heights, building styles)
- **SC-003**: Sidewalks have collision — cars and player can walk/drive on them
- **SC-004**: Crosswalks visible at all 49 intersections
- **SC-005**: Rural area has collision everywhere (no falling through)
- **SC-006**: Mountain walls block vehicle passage at map edges
- **SC-007**: Harbor has visible ships, piers, cranes, containers

## Assumptions

- WorldBuilder is a static class (class_name WorldBuilder, extends RefCounted) — no instance needed
- build_world() is called once by GameScene._ready()
- All geometry is procedural (no pre-built .tscn for world objects)
- District polygons use Vector2(x, z) coordinates (not x, y)
