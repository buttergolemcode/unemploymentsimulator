---
Task ID: terrain-v2
Agent: main
Task: User feedback: "besser aber immernoch nicht gut genug. man kann leider noch nicht wirklich von terrain design reden, aktuell ist es einfach nur rauer boden mit verschiedenen höhen und keine wirklichen schönen landschaften."

Work Log:
- Diagnosed: previous heightmap used sin-hash noise + a few local bumps; no real geographic features
- Completely rewrote /home/z/my-project/scripts/generate_heightmap.py:
  - numpy-vectorized for performance
  - real value-noise with bilinear interpolation + 5-octave fbm
  - 10 explicit geographic features blended on top of region-based base heights
  - Features: Castle Hill (+60m), Portofino inland ridge, Moon Bay (-5m bowl), South Coast Cliffs, North Beach (sand ramp), Harbor Basin (-7m), Harbor Pier (+1.5m), River Valley (dry riverbed +1m), Forest Ridge (+8m), Suburb rolling hills
  - Fixed critical bug: angle convention was wrong (used math convention instead of Godot's +Z=South). NE was placed in SE.
  - Fixed slums_suburbs region weight: didn't handle the 90°-270° wrap-around in signed degrees
  - Fixed river valley cutting through harbor basin (river now ends at x=+250)
- Updated /home/z/my-project/godot/scripts/WorldBuilder.gd:
  - _build_terrain: mesh resolution 150 → 250 segments
  - Added slope-aware vertex coloring (sand/grass/rock/cliff/snow based on height + slope)
  - 13 new color constants (COL_DEEP_SEA, COL_SAND, COL_CLIFF, etc.)
  - New helper: _terrain_color_at(x, z, h, slope) for layered coloring
  - Recompute normals via fresh SurfaceTool (smoother lighting)
  - Finer collision grid (60m → 35m cells) for cliffs/bays
  - _build_sea: larger plane (4000 → 4500), better material (per-pixel shading, more metallic)
  - Updated district polygons to match new organic island geography (NE/SE/W/center quadrants)
- Fixed critical indentation bug: WorldBuilder.gd was using 8-space indent (causes parser errors in Godot). Wrote scripts/fix_worldbuilder_indent.py to convert all leading 8-space groups → tabs. Now 881 tabs, 0 spaces.

Stage Summary:
- Heightmap statistics: Min -17.94m, Max 100.15m (castle peak), Land 50.6%, Sea 49.4%
- Verified feature placement:
  - Castle peak: 98.59m at (505, -505) in NE peninsula ✓
  - Harbor basin: -7.37m at (450, 450) ✓
  - Moon bay: -1.33m at (180, -676) (creates visible bay)
  - NYC center: 6.35m (flat plateau) ✓
  - North beach: 2.51m (sand slope) ✓
  - Suburbs: 34.90m (rolling hills) ✓
  - Slums: 15.14m (lower than suburbs) ✓
  - River valley: 1.41m (dry riverbed) ✓
- ASCII overview shows clear island with peninsula+peak (MM) in east, hills (^^, AA) in NE, flat NYC center, slums in west
- All WorldBuilder.gd functions intact (32 functions), all tabs (no parser errors expected)
- Files modified:
  - /home/z/my-project/scripts/generate_heightmap.py (complete rewrite)
  - /home/z/my-project/godot/assets/heightmap.png (regenerated, 1024x1024)
  - /home/z/my-project/godot/assets/heightmap_preview.png (regenerated)
  - /home/z/my-project/godot/scripts/WorldBuilder.gd (terrain renderer + districts)
  - /home/z/my-project/scripts/fix_worldbuilder_indent.py (new utility)
