#!/usr/bin/env python3
"""
Generate Heightmap PNG — proper landscape with geographic features.

Not just noise — hand-crafted geography blended with multi-octave value noise:

Island layout (X=East, Z=South, origin at island center):
  - Portofino (NE)    : Hügel am Hang, Klippen, Halbinsel mit Burg, Mond-Bucht, Strand
  - NYC (Center/SW)   : Flaches Plateau mit sanftem Gefälle zum Hafen
  - Harbor (SE)       : Meeresspiegel, Hafenbecken eingegraben, Pier-Vorsprung
  - Slums/Suburbs (W/NW): Rollende Hügel mit Tälern, Container-Slum in Senke

Geographic features:
  - Peninsula (NE)         : Deutlich ausgeprägte Landzunge mit Castle Hill (60m Peak)
  - Moon Bay (NE coast)    : Halbkreisförmige Bucht, sandiger Strand, flach auslaufend
  - South Cliffs (S coast) : Steiler Abfall 25m → 0m auf 30m Distanz
  - North Beach (N coast)  : Sanfter Sandstrand, 1.5m Gefälle auf 40m
  - Harbor Basin (SE)      : Rechteckige Vertiefung -8m, mit Pier-Vorsprung
  - River Valley (W→E)     : Trockenes Flusstal als Übergangslandschaft
  - Rolling Hills (Suburbs): Sanfte Wellen, 15-30m
  - Forest Ridge (NYC N)   : Leichter Höhenrücken mit Waldbedeckung

Output:
  /home/z/my-project/godot/assets/heightmap.png         (grayscale L, 1024x1024)
  /home/z/my-project/godot/assets/heightmap_preview.png  (colorized RGB)
"""

import math
import numpy as np
from PIL import Image

# ============================================================
# CONFIG
# ============================================================
W, H = 1024, 1024
MAP_SIZE = 2500.0  # world units: -1250 to +1250
MAX_HEIGHT = 120.0
SEA_LEVEL = 0.0
DEEP_SEA = -18.0

# ============================================================
# COORDINATE HELPERS
# ============================================================
def pixel_grid():
    """Return world X, Z arrays for every pixel."""
    xs = (np.arange(W) / W) * MAP_SIZE - MAP_SIZE / 2.0
    zs = (np.arange(H) / H) * MAP_SIZE - MAP_SIZE / 2.0
    X, Z = np.meshgrid(xs, zs)  # shape (H, W)
    return X, Z

# ============================================================
# VALUE NOISE (multi-octave, smooth)
# ============================================================
def _hash2(ix, iz, seed=0.0):
    """Deterministic hash → [0, 1)."""
    h = np.sin(ix * 127.1 + iz * 311.7 + seed * 13.1) * 43758.5453
    return h - np.floor(h)

def value_noise(x, z, scale=0.01, seed=0.0):
    """Smooth value noise via bilinear interpolation of integer lattice."""
    sx = x * scale
    sz = z * scale
    ix = np.floor(sx)
    iz = np.floor(sz)
    fx = sx - ix
    fz = sz - iz
    # Smoothstep
    ux = fx * fx * (3.0 - 2.0 * fx)
    uz = fz * fz * (3.0 - 2.0 * fz)
    v00 = _hash2(ix,     iz,     seed)
    v10 = _hash2(ix + 1, iz,     seed)
    v01 = _hash2(ix,     iz + 1, seed)
    v11 = _hash2(ix + 1, iz + 1, seed)
    a = v00 * (1.0 - ux) + v10 * ux
    b = v01 * (1.0 - ux) + v11 * ux
    return a * (1.0 - uz) + b * uz

def fbm(x, z, octaves=5, base_scale=0.004, persistence=0.5, lacunarity=2.0, seed=0.0):
    """Fractal Brownian Motion — multi-octave value noise."""
    total = np.zeros_like(x, dtype=np.float64)
    amp = 1.0
    freq = 1.0
    max_amp = 0.0
    for o in range(octaves):
        total += value_noise(x, z, base_scale * freq, seed + o * 17.3) * amp
        max_amp += amp
        amp *= persistence
        freq *= lacunarity
    return total / max_amp

def ridge_noise(x, z, octaves=4, base_scale=0.005, seed=100.0):
    """Ridged multifractal — produces sharp ridges like mountain crests."""
    total = np.zeros_like(x, dtype=np.float64)
    amp = 1.0
    max_amp = 0.0
    for o in range(octaves):
        n = value_noise(x, z, base_scale * (2 ** o), seed + o * 23.7)
        # 1 - |2n-1| → peaks at n=0.5
        ridge = 1.0 - np.abs(2.0 * n - 1.0)
        total += (ridge ** 2) * amp
        max_amp += amp
        amp *= 0.5
    return total / max_amp

# ============================================================
# ISLAND SHAPE — organic, non-circular
# ============================================================
# Coordinate convention (Godot):
#   +X = East, +Z = South, -Z = North
#   atan2(Z, X) → 0°=East, 90°=South, 180°=West, -90°=North (i.e., 270°)
# So:
#   NE quadrant = -90° to 0° (or 270° to 360°)
#   SE quadrant = 0° to 90°
#   SW quadrant = 90° to 180°
#   NW quadrant = -180° to -90° (or 180° to 270°)
def island_radius_field(angle):
    """Per-angle radius of the organic island coastline. Angle in radians.
    Base radius with mild organic variation, plus prominent explicit features:
    - NE peninsula (juts out 350m)
    - NNE moon bay (carves in 220m)
    - SE harbor basin (carves in 240m)
    - W slums notch (carves in 80m)
    """
    base = 980.0
    r = np.full_like(angle, base, dtype=np.float64)
    # Mild organic variation (small amplitudes so explicit features dominate)
    r += np.sin(angle * 1.0) * 60.0
    r += np.sin(angle * 2.0 + 0.8) * 40.0
    r += np.sin(angle * 3.5 + 1.5) * 25.0
    r += np.cos(angle * 5.0 + 0.3) * 18.0

    # --- Peninsula in NE direction (-45° in Godot) ---
    # Wide, prominent bulge that overrides the noise
    pen_angle = math.radians(-45)
    angle_diff = np.abs(angle - pen_angle)
    angle_diff = np.minimum(angle_diff, 2 * math.pi - angle_diff)
    pen_mask = np.clip(1.0 - angle_diff / math.radians(35), 0, 1) ** 1.2
    r += pen_mask * 380.0  # big bulge

    # --- Moon bay in NNE (-75°) — just north of peninsula ---
    # Wide carved indentation
    bay_angle = math.radians(-75)
    bay_diff = np.abs(angle - bay_angle)
    bay_diff = np.minimum(bay_diff, 2 * math.pi - bay_diff)
    bay_mask = np.clip(1.0 - bay_diff / math.radians(22), 0, 1) ** 1.1
    r -= bay_mask * 240.0

    # --- Harbor basin in SE (45°) — major coastal indent ---
    hb_angle = math.radians(45)
    hb_diff = np.abs(angle - hb_angle)
    hb_diff = np.minimum(hb_diff, 2 * math.pi - hb_diff)
    hb_mask = np.clip(1.0 - hb_diff / math.radians(25), 0, 1) ** 1.2
    r -= hb_mask * 260.0

    # --- Slight inward notch on W (slums, 180°) ---
    w_angle = math.radians(180)
    w_diff = np.abs(angle - w_angle)
    w_diff = np.minimum(w_diff, 2 * math.pi - w_diff)
    w_mask = np.clip(1.0 - w_diff / math.radians(15), 0, 1) ** 1.5
    r -= w_mask * 80.0

    return np.maximum(280.0, r)

def island_field(X, Z):
    """
    Returns:
      inside_mask : bool, True where on island
      coast_dist  : float, distance from coast in meters (positive=land, negative=sea)
      coast_factor: float, 1.0 at center → 0.0 at coast → negative in sea
    """
    dist = np.sqrt(X * X + Z * Z)
    angle = np.arctan2(Z, X)
    r = island_radius_field(angle)
    # Distance from coast: positive on land, negative in sea
    coast_dist = r - dist  # >0 = land, <0 = sea
    inside_mask = coast_dist > -20.0  # include 20m of shallow water for beach slope
    # coast_factor: 1 at center, 0 at coastline, smoothly decreasing
    coast_factor = np.clip(coast_dist / 400.0, -0.5, 1.0)
    return inside_mask, coast_dist, coast_factor, dist, angle

# ============================================================
# REGION MASKS — soft blending zones (Godot convention)
# ============================================================
def region_weights(X, Z, dist, angle):
    """
    Return dict of region name → weight array (0..1), summing to ~1 over land.
    Coordinate convention (Godot): +X=East, +Z=South, -Z=North.
    So atan2(Z, X): 0°=E, 90°=S, 180°=W, -90°=N.
    Regions:
      portofino      : NE  (angle -90° to 0°,  outer half)
      harbor         : SE  (angle 0° to 90°)
      slums_suburbs  : W/NW (angle 90° to 270°, i.e., S→W→N)
      nyc            : Center / SW (fill, stronger at center)
    """
    # Use signed degrees in [-180, 180]
    deg = np.degrees(angle)
    # Portofino: NE quadrant = -90° to 0°
    # strength peaks at -45° (NE), fades at edges
    p_ang = np.clip((deg + 90) / 45, 0, 1) * np.clip((-deg) / 45, 0, 1)
    p_ang = np.where((deg >= -90) & (deg <= 0), p_ang, 0.0)
    p_outer = np.clip((dist - 350) / 250, 0, 1)
    portofino = p_ang * (0.4 + 0.6 * p_outer)
    # Harbor: SE quadrant = 0° to 90°
    h_ang = np.clip(deg / 45, 0, 1) * np.clip((90 - deg) / 45, 0, 1)
    h_ang = np.where((deg >= 0) & (deg <= 90), h_ang, 0.0)
    harbor = h_ang * (0.4 + 0.6 * np.clip((dist - 300) / 250, 0, 1))
    # Slums/Suburbs: W and NW = 90° to 270° in 0-360 form
    # In signed degrees that's [90, 180] ∪ [-180, -90]
    # Use 0-360 form to avoid wrap-around issues
    deg_pos = (deg + 360.0) % 360.0
    s_ang = np.clip((deg_pos - 90) / 60, 0, 1) * np.clip((270 - deg_pos) / 60, 0, 1)
    s_ang = np.where((deg_pos >= 90) & (deg_pos <= 270), s_ang, 0.0)
    slums_suburbs = s_ang * (0.5 + 0.5 * np.clip((dist - 250) / 300, 0, 1))
    # NYC: fill the rest
    others = portofino + harbor + slums_suburbs
    nyc = np.clip(1.0 - others, 0, 1)
    nyc_inner = np.clip(1.0 - dist / 500, 0, 1)
    nyc = np.maximum(nyc, nyc_inner * 0.8)
    # Normalize
    total = portofino + harbor + slums_suburbs + nyc + 1e-6
    return {
        "portofino": portofino / total,
        "harbor": harbor / total,
        "slums_suburbs": slums_suburbs / total,
        "nyc": nyc / total,
    }

# ============================================================
# FEATURE BUILDERS — each returns (height_delta, weight) for the field
# ============================================================
def smoothstep(x):
    return x * x * (3.0 - 2.0 * x)

def smootherstep(x):
    """6t^5 - 15t^4 + 10t^3 — C2 continuous."""
    return x * x * x * (x * (x * 6.0 - 15.0) + 10.0)

def radial_feature(X, Z, cx, cz, radius, falloff=1.0):
    """Return weight 1.0 at center, 0.0 beyond radius, smooth in between."""
    d = np.sqrt((X - cx) ** 2 + (Z - cz) ** 2)
    t = np.clip(1.0 - d / radius, 0, 1)
    return smootherstep(t) ** max(0.1, falloff)

def directed_radial(X, Z, cx, cz, radius, direction_deg, spread_deg, falloff=1.0):
    """Radial feature but stronger in `direction_deg` direction."""
    d = np.sqrt((X - cx) ** 2 + (Z - cz) ** 2)
    t = np.clip(1.0 - d / radius, 0, 1)
    angle_to = np.degrees(np.arctan2(Z - cz, X - cx))
    ang_diff = (angle_to - direction_deg + 540) % 360 - 180
    ang_factor = np.clip(1.0 - np.abs(ang_diff) / spread_deg, 0, 1)
    return smootherstep(t) * ang_factor ** max(0.1, falloff)

# ============================================================
# TERRAIN HEIGHT FIELD — the main attraction
# ============================================================
def build_height_field(X, Z):
    """Compute elevation for every pixel."""
    inside_mask, coast_dist, coast_factor, dist, angle = island_field(X, Z)
    regions = region_weights(X, Z, dist, angle)

    # --- Base noise (gentle, landscape-scale) ---
    n_large = fbm(X, Z, octaves=4, base_scale=0.0018, persistence=0.55, seed=3.7)
    n_med = fbm(X, Z, octaves=4, base_scale=0.006, persistence=0.5, seed=11.1)
    n_fine = fbm(X, Z, octaves=3, base_scale=0.02, persistence=0.4, seed=23.5)

    # ============================================================
    # REGION-BASED BASE HEIGHT
    # ============================================================
    base = np.zeros_like(X, dtype=np.float64)

    # --- NYC Downtown: flat plateau, slight slope toward SE (harbor) ---
    # Range: 4-9m, basically flat with subtle tilt
    nyc_slope = np.clip((X * 0.005 + Z * 0.008), -1, 1) * 1.5  # ±1.5m tilt
    nyc_base = 6.0 + nyc_slope + n_fine * 0.8  # 4-9m

    # --- Harbor: sea level, very flat ---
    # Range: 0-2m, with harbor basin carved separately
    harbor_base = 1.5 + n_fine * 0.5  # 1-2m

    # --- Portofino: hills sloping down to sea, peaks inland ---
    # Range: 0m (coast) → 50m (inner hills), with castle hill +60m
    # Use coast_factor: 1 at center (high) → 0 at coast (sea level)
    p_hills = 18.0 + n_med * 12.0  # base rolling hills 6-30m
    p_hills += n_large * 20.0  # large landscape variation
    # Slope down to coast
    portofino_base = p_hills * (0.15 + coast_factor * 0.85)
    portofino_base = np.clip(portofino_base, 0.0, 70.0)

    # --- Slums/Suburbs: rolling hills 10-35m, slums in southern dip ---
    s_hills = 18.0 + n_med * 14.0  # 4-32m rolling
    s_hills += n_large * 10.0
    # Suburbs: northern part higher (20-35m), slums: southern part lower (5-15m)
    slum_factor = np.clip((Z + 200) / 400, 0, 1)  # 0 at Z=-200 (suburbs), 1 at Z=200 (slums)
    slums_suburbs_base = s_hills * (0.5 + 0.7 * (1.0 - slum_factor))
    slums_suburbs_base = np.clip(slums_suburbs_base, 3.0, 40.0)

    # Blend region base heights
    base = (regions["nyc"] * nyc_base
            + regions["harbor"] * harbor_base
            + regions["portofino"] * portofino_base
            + regions["slums_suburbs"] * slums_suburbs_base)

    # Signed degrees in [-180, 180] for feature masks below
    deg = np.degrees(angle)

    # ============================================================
    # GEOGRAPHIC FEATURES (added on top)
    # All coordinates use Godot convention: +X=East, +Z=South, -Z=North.
    # Portofino is in NE (+X, -Z). Harbor is in SE (+X, +Z). Slums are in W/SW.
    # ============================================================

    # --- 1. CASTLE HILL on Portofino Peninsula ---
    # Peninsula tip in NE direction (-45° = NE in Godot). Base island radius
    # there = 950 + 280 (pen ext) = ~1230m. Place castle 70% of the way out.
    pen_tip_x = 950.0 * math.cos(math.radians(-45))
    pen_tip_z = 950.0 * math.sin(math.radians(-45))  # negative (north)
    # Place the peak well inside the peninsula, not at the tip
    castle_x = pen_tip_x * 0.75   # ~ +505
    castle_z = pen_tip_z * 0.75   # ~ -505
    castle_w = radial_feature(X, Z, castle_x, castle_z, 240.0, falloff=1.4)
    base += castle_w * 60.0  # +60m peak above surrounding hills

    # --- 2. PORTOFINO INLAND HILL RIDGE ---
    # A ridge running NW-SE through the inland part of Portofino (NE region)
    # Direction 135° in Godot = SE, so ridge direction vector (cos135°, sin135°) = (-0.71, 0.71)
    ridge_cx, ridge_cz = 350, -350  # center of ridge, in NE
    ridge_dir = np.array([math.cos(math.radians(135)), math.sin(math.radians(135))])
    ridge_normal = np.array([-ridge_dir[1], ridge_dir[0]])
    ridge_d = np.abs((X - ridge_cx) * ridge_normal[0] + (Z - ridge_cz) * ridge_normal[1])
    ridge_w = np.clip(1.0 - ridge_d / 180.0, 0, 1) ** 1.5
    ridge_length_factor = np.clip(1.0 - np.abs(dist - 500) / 400, 0, 1)
    base += ridge_w * ridge_length_factor * 22.0

    # --- 3. MOON BAY (NE coast, just north of peninsula tip) ---
    # Crescent-shaped indentation at angle -75° (NNE), ~700m out
    # Carve a deeper bowl that creates a visible bay below sea level
    bay_cx = 700 * math.cos(math.radians(-75))
    bay_cz = 700 * math.sin(math.radians(-75))
    bay_d = np.sqrt((X - bay_cx) ** 2 + (Z - bay_cz) ** 2)
    # Wider carve radius, deeper target
    bay_w = np.clip(1.0 - bay_d / 250.0, 0, 1) ** 1.2
    # Target: -5m (clearly below sea level, but not as deep as open ocean)
    bay_target = -5.0
    base = np.where(bay_w > 0.05,
                    base * (1.0 - bay_w) + bay_target * bay_w,
                    base)

    # --- 4. SOUTH COAST CLIFFS (harbor south + portofino south coast) ---
    # Sharp drop where land meets sea on south side (angle 30°-150° in Godot = SE to SW)
    south_mask = np.clip((deg - 30) / 30, 0, 1) * np.clip((150 - deg) / 30, 0, 1)
    cliff_zone = np.clip((0.25 - coast_factor) / 0.25, 0, 1)  # only near coast
    base -= south_mask * cliff_zone * 20.0

    # --- 5. NORTH BEACH (gentle sand slope on N coast, -150° to -30°) ---
    n_deg = deg  # signed degrees; north is -90°
    north_mask = np.clip((-30 - n_deg) / 30, 0, 1) * np.clip((n_deg + 150) / 30, 0, 1)
    north_mask = np.where((n_deg >= -150) & (n_deg <= -30), north_mask, 0.0)
    beach_zone = np.clip((0.3 - coast_factor) / 0.3, 0, 1)
    base = np.where(north_mask * beach_zone > 0.2,
                    base * (1.0 - north_mask * beach_zone * 0.7) + 0.5 * north_mask * beach_zone,
                    base)

    # --- 6. HARBOR BASIN (rectangular carved area in SE) ---
    # The SE coast is already indented by island_radius_field (harbor bay carve).
    # This basin sits inside that bay to deepen it for ships.
    # Place at (450, 450) which is inside the SE coast indent (~750m radius at 45°).
    # 300×220m, depth -7m
    hb_cx, hb_cz = 450, 450
    hb_w, hb_d = 300, 220
    hb_mask_x = np.clip(1.0 - np.abs(X - hb_cx) / (hb_w / 2), 0, 1)
    hb_mask_z = np.clip(1.0 - np.abs(Z - hb_cz) / (hb_d / 2), 0, 1)
    hb_mask = (hb_mask_x * hb_mask_z) ** 1.5
    # Blend toward -7m target
    hb_target = -7.0
    base = np.where(hb_mask > 0.05,
                    base * (1.0 - hb_mask) + hb_target * hb_mask,
                    base)

    # --- 7. HARBOR PIER (raised jetty extending SE from basin into bay) ---
    pier_cx, pier_cz = 580, 580
    pier_mask_x = np.clip(1.0 - np.abs(X - pier_cx) / 90, 0, 1)
    pier_mask_z = np.clip(1.0 - np.abs(Z - pier_cz) / 35, 0, 1)
    pier_mask = pier_mask_x * pier_mask_z
    base = np.where(pier_mask > 0.05,
                    np.maximum(base, 1.5 * pier_mask),
                    base)

    # --- 8. RIVER VALLEY (transition zone W → E, dry riverbed) ---
    # Carves a gentle valley from slums (W) through NYC toward harbor (E).
    # River ENDS at harbor edge (x ≈ 250) so it doesn't overwrite the basin.
    # Valley floor is at +1m (just above sea level, like a real riverbed).
    t_river = np.clip((X + 800) / 1050, 0, 1)  # 0 at W edge, 1 at x=+250
    # S-curve path through mid-latitudes (south of NYC center)
    river_z_center = 250 + 300 * t_river + 50 * np.sin(t_river * np.pi * 2.0)
    river_d = np.abs(Z - river_z_center)
    river_w = np.clip(1.0 - river_d / 130.0, 0, 1) ** 1.5  # wider valley
    # Carve intensity: peak in middle of river, fade at both ends
    river_intensity = np.sin(t_river * np.pi)
    # Carve toward +1m (riverbed floor), don't go below sea level
    river_target = 1.0
    river_full = river_w * river_intensity
    base = np.where(river_full > 0.05,
                    base * (1.0 - river_full) + river_target * river_full,
                    base)

    # --- 9. FOREST RIDGE between NYC and Portofino ---
    fr_cx, fr_cz = 250, -150
    fr_d = np.sqrt((X - fr_cx) ** 2 + (Z - fr_cz) ** 2)
    fr_w = np.clip(1.0 - fr_d / 350.0, 0, 1) ** 2.0
    base += fr_w * 8.0

    # --- 10. SUBURBS ROLLING HILLS (extra amplitude in N part of slums_suburbs) ---
    suburb_mask = np.clip(((-Z) - 100) / 400, 0, 1)
    suburb_mask *= regions["slums_suburbs"]
    base += suburb_mask * n_med * 8.0

    # ============================================================
    # SEA — below sea level outside island
    # ============================================================
    # Smooth coast transition: blend from land to sea
    sea_blend = np.clip(-coast_dist / 60.0, 0, 1)  # 0 on land, 1 at 60m into sea
    # Sea depth: gets deeper further out
    sea_depth = -3.0 - np.clip((-coast_dist - 30) / 80.0, 0, 1) * 15.0  # -3 to -18
    # Where sea_blend is 1, use sea_depth
    base = np.where(sea_blend > 0,
                    base * (1.0 - sea_blend) + sea_depth * sea_blend,
                    base)

    # Add slight wave-like variation to sea floor
    sea_floor_noise = n_fine * 1.5
    base = np.where(sea_blend > 0.5, base + sea_floor_noise * sea_blend, base)

    # Clip final values
    base = np.clip(base, DEEP_SEA, MAX_HEIGHT)
    return base, regions, coast_factor, inside_mask

# ============================================================
# COLORIZE — for preview PNG (Godot does its own coloring at runtime)
# ============================================================
def colorize(heights, regions, coast_factor):
    """Return RGB image array (H, W, 3)."""
    H_, W_ = heights.shape
    rgb = np.zeros((H_, W_, 3), dtype=np.uint8)

    # Compute slope (gradient magnitude) for cliff detection
    gy, gx = np.gradient(heights)
    slope = np.sqrt(gx * gx + gy * gy) * 10.0  # exaggerate for visibility

    # Per-region colors
    portofino_col = np.array([180, 160, 100])  # warm coastal
    nyc_col = np.array([55, 55, 60])            # urban gray
    harbor_col = np.array([65, 60, 55])         # harbor brown-gray
    slums_col = np.array([100, 70, 50])         # slum brown
    suburbs_col = np.array([100, 130, 70])      # suburb green

    # Blend slums vs suburbs by Z (slums=south, suburbs=north)
    slum_blend = np.clip((0 - 0) / 1, 0, 1)  # placeholder
    slums_suburbs_col = np.zeros((H_, W_, 3), dtype=np.float64)
    # South (Z>0) = slums brown, North (Z<0) = suburbs green
    suburb_factor = np.clip((-heights + 30) / 60, 0, 1)  # rough
    for c in range(3):
        slums_suburbs_col[..., c] = slums_col[c] * (1.0 - suburb_factor) + suburbs_col[c] * suburb_factor

    # Blend all regions
    region_col = np.zeros((H_, W_, 3), dtype=np.float64)
    for c in range(3):
        region_col[..., c] = (regions["portofino"] * portofino_col[c]
                              + regions["nyc"] * nyc_col[c]
                              + regions["harbor"] * harbor_col[c]
                              + regions["slums_suburbs"] * slums_suburbs_col[..., c])

    # Height-based tweaks: water, sand, rock, snow
    water_mask = heights < -0.5
    shallow_mask = (heights >= -0.5) & (heights < 0.5)
    sand_mask = (heights >= 0.5) & (heights < 2.5) & (coast_factor < 0.2)
    cliff_mask = (slope > 1.5) & (heights > 1.0)
    peak_mask = heights > 50.0

    # Apply region colors as base
    for c in range(3):
        rgb[..., c] = region_col[..., c].astype(np.uint8)

    # Water: blue
    rgb[water_mask] = [20, 70, 110]
    # Shallow water: lighter blue
    rgb[shallow_mask] = [60, 130, 160]
    # Sand: tan
    rgb[sand_mask] = [200, 180, 130]
    # Cliffs: darker rock
    cliff_col = np.array([100, 90, 75])
    for c in range(3):
        rgb[..., c] = np.where(cliff_mask, cliff_col[c].astype(np.uint8), rgb[..., c])
    # Peaks: rock gray
    peak_col = np.array([120, 115, 110])
    for c in range(3):
        rgb[..., c] = np.where(peak_mask, peak_col[c].astype(np.uint8), rgb[..., c])

    return rgb

# ============================================================
# HEIGHTMAP ENCODING (grayscale L)
# ============================================================
def height_to_pixel(heights):
    """Map height (m) to 0..255 grayscale. Range: [-20, MAX_HEIGHT]."""
    rng = MAX_HEIGHT + 20.0
    arr = (heights + 20.0) / rng * 255.0
    arr = np.clip(arr, 0, 255).astype(np.uint8)
    return arr

# ============================================================
# MAIN
# ============================================================
def main():
    print("Generating heightmap (1024x1024)...")
    X, Z = pixel_grid()
    print("  Computing terrain field...")
    heights, regions, coast_factor, inside_mask = build_height_field(X, Z)

    print("  Encoding grayscale PNG...")
    gray = height_to_pixel(heights)
    img = Image.fromarray(gray)
    out_gray = '/home/z/my-project/godot/assets/heightmap.png'
    img.save(out_gray)
    print(f"  Saved: {out_gray}")

    print("  Colorizing preview PNG...")
    rgb = colorize(heights, regions, coast_factor)
    img_c = Image.fromarray(rgb)
    out_color = '/home/z/my-project/godot/assets/heightmap_preview.png'
    img_c.save(out_color)
    print(f"  Saved: {out_color}")

    # Print summary statistics
    print("\n=== TERRAIN STATISTICS ===")
    print(f"  Min elevation: {heights.min():.2f} m")
    print(f"  Max elevation: {heights.max():.2f} m")
    print(f"  Mean elevation: {heights.mean():.2f} m")
    land = heights[inside_mask]
    sea = heights[~inside_mask]
    print(f"  Land area: {len(land.ravel()) / heights.size * 100:.1f}%  (mean h = {land.mean():.2f} m)")
    print(f"  Sea area:  {len(sea.ravel()) / heights.size * 100:.1f}%  (mean h = {sea.mean():.2f} m)")
    # Per-region stats
    for name, w in regions.items():
        region_h = heights[w > 0.5]
        if len(region_h) > 0:
            print(f"  {name:15s}: pixels={len(region_h):6d}  mean={region_h.mean():6.2f}  min={region_h.min():6.2f}  max={region_h.max():6.2f}")

if __name__ == '__main__':
    main()
