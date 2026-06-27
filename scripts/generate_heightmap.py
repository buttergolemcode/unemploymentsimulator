#!/usr/bin/env python3
"""
Generate Heightmap PNG for the island map with 4 regions.
Island is irregular/organic shape, surrounded by sea.

Regions (clockwise from North):
1. Portofino (Northeast) — hilly coast, slopes down to sea, cliffs, bay, peninsula
2. NYC Downtown (Center/Southwest) — flat urban
3. Harbor (Southeast) — flat at sea level, harbor basin
4. Slums/Suburbs (West/Northwest) — slightly hilly, transition zone

Connected by roads through transition zones (forest, hills, coast).
"""

from PIL import Image
import math

# Heightmap dimensions
W, H = 1024, 1024
MAP_SIZE = 2500.0  # -1250 to +1250 (smaller than before)
MAX_HEIGHT = 120.0

def pixel_to_world(px, pz):
    x = (px / W) * MAP_SIZE - MAP_SIZE / 2
    z = (pz / H) * MAP_SIZE - MAP_SIZE / 2
    return x, z

def smooth_noise(x, z, scale=0.01):
    h = math.sin(x * scale * 127.1 + z * scale * 311.7) * 43758.5453
    return h - math.floor(h)

def fractal_noise(x, z, octaves=3, scale=0.003):
    value = 0.0
    amp = 1.0
    freq = 1.0
    max_val = 0.0
    for _ in range(octaves):
        value += smooth_noise(x * freq, z * freq, scale * freq) * amp
        max_val += amp
        amp *= 0.5
        freq *= 2
    return value / max_val if max_val > 0 else 0

def island_radius(angle):
    """Organic island shape — radius varies with angle (noise-modulated)."""
    # Base radius ~900m, modulated by harmonics for organic shape
    base = 900.0
    r = base
    r += math.sin(angle * 1.0) * 120.0   # elongation
    r += math.sin(angle * 2.3 + 0.5) * 80.0   # bump
    r += math.sin(angle * 3.7 + 1.2) * 60.0   # smaller bumps
    r += math.sin(angle * 5.1 + 2.8) * 40.0   # detail
    r += math.cos(angle * 7.0 + 0.3) * 25.0   # fine detail
    # Peninsula bump in northeast direction (Portofino)
    pen_angle = math.radians(45)  # NE
    angle_diff = abs(angle - pen_angle)
    if angle_diff > math.pi:
        angle_diff = 2 * math.pi - angle_diff
    if angle_diff < math.radians(25):
        pen_factor = 1.0 - (angle_diff / math.radians(25))
        r += pen_factor * 200.0  # peninsula extends 200m extra
    # Bay indentation in southeast (Harbor)
    bay_angle = math.radians(135)  # SE
    angle_diff2 = abs(angle - bay_angle)
    if angle_diff2 > math.pi:
        angle_diff2 = 2 * math.pi - angle_diff2
    if angle_diff2 < math.radians(20):
        bay_factor = 1.0 - (angle_diff2 / math.radians(20))
        r -= bay_factor * 150.0  # bay cuts 150m into island
    return max(200.0, r)

def is_on_island(x, z):
    """Check if point is on the island (inside organic shape)."""
    dist = math.sqrt(x * x + z * z)
    if dist < 10:
        return True, 1.0
    angle = math.atan2(z, x)
    r = island_radius(angle)
    if dist <= r:
        return True, 1.0 - (dist / r)  # 1.0 at center, 0.0 at coast
    # Smooth coast edge
    if dist <= r + 30:
        return True, max(0, 1.0 - (dist - r) / 30) * 0.3
    return False, 0.0

def get_region(x, z):
    """Determine which region a point belongs to (rough zones)."""
    angle = math.atan2(z, x)
    dist = math.sqrt(x * x + z * z)

    # Portofino: Northeast (angle 10° to 100°), outer part of island
    if -10 <= math.degrees(angle) <= 100 and dist > 300:
        return "portofino"
    # Harbor: Southeast (angle 100° to 180°), coastal
    if 100 <= math.degrees(angle) <= 180 and dist > 200:
        return "harbor"
    # Slums/Suburbs: West/Northwest (angle 180° to 290°)
    if 180 <= math.degrees(angle) <= 290:
        return "slums_suburbs"
    # NYC Downtown: Center/Southwest (everything else, inner)
    return "nyc"

def get_terrain_height(x, z):
    """Calculate terrain height at world position."""
    on_island, coast_factor = is_on_island(x, z)

    if not on_island:
        # Sea — deeper further from island
        angle = math.atan2(z, x)
        r = island_radius(angle)
        dist = math.sqrt(x * x + z * z)
        depth = (dist - r) / 100.0
        return -3.0 - min(depth * 2.0, 15.0)

    noise = fractal_noise(x, z, 3, 0.003)
    noise2 = fractal_noise(x + 500, z + 500, 2, 0.005)
    region = get_region(x, z)
    dist = math.sqrt(x * x + z * z)

    # === PORTOFINO (Northeast) — hilly coast sloping down to sea ===
    if region == "portofino":
        # Base height: higher inland, lower toward coast
        h = 35.0 + noise * 15.0  # 20-50m inland

        # Slope down toward sea (coast_factor: 1.0 center → 0.0 coast)
        h *= 0.3 + coast_factor * 0.7  # flatten near coast

        # Castle hill: elevated point above harbor (NE coast, ~600m out)
        castle_x, castle_z = 600, -300
        castle_dist = math.sqrt((x - castle_x)**2 + (z - castle_z)**2)
        if castle_dist < 120:
            h += (1.0 - castle_dist / 120) * 30.0  # +30m peak

        # Peninsula: elevated land jutting into sea (NE, ~800m out)
        pen_x, pen_z = 800, -500
        pen_dist = math.sqrt((x - pen_x)**2 + (z - pen_z)**2)
        if pen_dist < 200:
            h += (1.0 - pen_dist / 200) * 25.0  # elevated peninsula

        # Moon-shaped bay: depression at coast (NE, ~700m out)
        bay_x, bay_z = 700, -100
        bay_dist = math.sqrt((x - bay_x)**2 + (z - bay_z)**2)
        if bay_dist < 150 and coast_factor < 0.3:
            h -= (1.0 - bay_dist / 150) * 10.0  # dip below sea level

        # Cliffs on south side of portofino coast (steep drop)
        if coast_factor < 0.15 and z > 0:
            h -= 5.0  # sharp drop at southern cliffs

        return max(-2.0, h)

    # === HARBOR (Southeast) — flat at sea level ===
    if region == "harbor":
        h = 0.0 + noise * 0.5  # almost flat

        # Harbor basin: depression (SE coast)
        basin_x, basin_z = 300, 600
        basin_dist = math.sqrt((x - basin_x)**2 + (z - basin_z)**2)
        if basin_dist < 200 and coast_factor < 0.4:
            h -= (1.0 - basin_dist / 200) * 5.0  # harbor basin dip

        # Beach on north side (gentle slope to water)
        if coast_factor < 0.2 and z < 400:
            h -= 2.0  # gentle beach slope

        # Container storage area: slightly raised (flat plateau)
        if 100 < x < 400 and 300 < z < 600:
            h += 1.0  # raised loading area

        return max(-3.0, h)

    # === SLUMS/SUBURBS (West/Northwest) — slightly hilly ===
    if region == "slums_suburbs":
        # Gentle hills 10-30m
        h = 15.0 + noise * 12.0  # 3-27m rolling hills

        # Slums area: lower, flatter (closer to harbor, south part)
        if z > -100:
            h = 8.0 + noise * 5.0  # 3-13m, flatter (slums)

        # Suburbs: slightly higher (north part)
        if z < -200:
            h = 20.0 + noise * 10.0  # 10-30m, rolling (suburbs)

        # Coast: cliffs on west side
        if coast_factor < 0.15:
            h -= 3.0  # slight coastal drop

        return max(-2.0, h)

    # === NYC DOWNTOWN (Center/Southwest) — relatively flat ===
    # Flat urban center 0-10m with slight slope toward harbor
    h = 5.0 + noise * 2.0  # 3-7m, very flat

    # Slight slope toward SE (harbor direction)
    angle = math.atan2(z, x)
    if 90 < math.degrees(angle) < 180:
        h -= 2.0  # slope down toward harbor

    return max(-1.0, h)

def height_to_pixel(height_m):
    return max(0, min(255, int((height_m + 20) / (MAX_HEIGHT + 20) * 255)))

def generate_heightmap():
    print("Generating island heightmap...")
    img = Image.new('L', (W, H))
    pixels = img.load()

    for py in range(H):
        for px in range(W):
            x, z = pixel_to_world(px, py)
            h = get_terrain_height(x, z)
            pixels[px, py] = height_to_pixel(h)
        if py % 100 == 0:
            print(f"  Row {py}/{H}...")

    output_path = '/home/z/my-project/godot/assets/heightmap.png'
    img.save(output_path)
    print(f"Heightmap saved to {output_path}")

    # Colorized preview
    img_color = Image.new('RGB', (W, H))
    cp = img_color.load()
    for py in range(H):
        for px in range(W):
            val = pixels[px, py]
            h = (val / 255.0) * (MAX_HEIGHT + 20) - 20
            x, z = pixel_to_world(px, py)
            region = get_region(x, z)

            if h < -1:
                cp[px, py] = (10, 50, 90)  # deep water
            elif h < 0:
                cp[px, py] = (30, 100, 140)  # shallow water
            elif h < 1:
                cp[px, py] = (200, 180, 120)  # beach/sand
            elif region == "portofino":
                if h > 30:
                    cp[px, py] = (90, 80, 60)  # rock/cliff
                elif h > 15:
                    cp[px, py] = (120, 110, 70)  # hills
                else:
                    cp[px, py] = (180, 160, 100)  # coastal town
            elif region == "nyc":
                cp[px, py] = (50, 50, 60)  # urban gray
            elif region == "harbor":
                cp[px, py] = (60, 55, 50)  # harbor brown-gray
            elif region == "slums_suburbs":
                if h > 15:
                    cp[px, py] = (100, 130, 70)  # suburb green
                else:
                    cp[px, py] = (100, 70, 50)  # slum brown
            else:
                cp[px, py] = (80, 80, 80)

    color_path = '/home/z/my-project/godot/assets/heightmap_preview.png'
    img_color.save(color_path)
    print(f"Colorized preview saved to {color_path}")

if __name__ == '__main__':
    generate_heightmap()
