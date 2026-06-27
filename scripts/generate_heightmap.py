#!/usr/bin/env python3
"""
Generate a Heightmap PNG for the Portofino-inspired coastal city.

Map: 3000x3000m, Heightmap: 1024x1024 pixels (1 pixel ≈ 2.93m)
Height range: 0-255 (8-bit grayscale), mapped to 0-100m terrain height

Layout (West → East, land falls toward sea):
- Canyon walls (West/North/South edges): 80-100m
- Rural (far west): 60-80m, rolling hills
- Suburbs: 40-50m, gentle slopes
- Industrial: 25-30m, plateau
- Downtown: 5-15m, slope down to harbor
- Harbor: 0m, sea level
- Sea (far east): -3m (below 0, mapped to 0 in heightmap)

Portofino coastal features:
- Moon-shaped bay at harbor (x≈1200, z≈0)
- Peninsula jutting into sea (x≈1400, z≈200)
- Cliffs south of harbor (steep drop at z>300, x>1000)
- Beach north of harbor (gentle slope at z<-300, x>1000)
- Castle hill above harbor (elevated point at x≈900, z≈0)
"""

from PIL import Image
import math
import os

# Heightmap dimensions
W, H = 1024, 1024

# Map dimensions in meters
MAP_SIZE = 3000.0  # -1500 to +1500

# Height scale: 0-255 in PNG = 0-120m in world
MAX_HEIGHT = 120.0

def world_to_pixel(x, z):
    """Convert world coordinates (-1500..1500) to pixel (0..1023)."""
    px = int((x + 1500) / MAP_SIZE * W)
    pz = int((z + 1500) / MAP_SIZE * H)
    return max(0, min(W-1, px)), max(0, min(H-1, pz))

def pixel_to_world(px, pz):
    """Convert pixel to world coordinates."""
    x = (px / W) * MAP_SIZE - 1500
    z = (pz / H) * MAP_SIZE - 1500
    return x, z

def smooth_noise(x, z, scale=0.01):
    """Simple smooth noise for natural terrain variation."""
    h = math.sin(x * scale * 127.1 + z * scale * 311.7) * 43758.5453
    return h - math.floor(h)

def fractal_noise(x, z, octaves=3, scale=0.003):
    """Fractal noise for natural hills."""
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

def height_to_pixel(height_m):
    """Convert height in meters to 0-255 pixel value."""
    return max(0, min(255, int(height_m / MAX_HEIGHT * 255)))

def get_terrain_height(x, z):
    """
    Calculate terrain height at world position (x, z).
    Returns height in meters (0 = sea level, negative = underwater).
    """
    noise = fractal_noise(x, z, 3, 0.003)
    noise2 = fractal_noise(x + 500, z + 500, 2, 0.005)
    
    # === CANYON WALLS (West/North/South edges) ===
    canyon_west = -1200
    canyon_north = -1200
    canyon_south = 1200
    
    canyon_dist = 0
    if x < canyon_west:
        canyon_dist = max(canyon_dist, canyon_west - x)
    if z < canyon_north:
        canyon_dist = max(canyon_dist, canyon_north - z)
    if z > canyon_south:
        canyon_dist = max(canyon_dist, z - canyon_south)
    
    if canyon_dist > 0:
        return 100.0 * min(canyon_dist / 300.0, 1.0) + noise * 20
    
    # === SEA (east of coast) ===
    coast_x = 1500
    if x > coast_x:
        return -3.0 - min((x - coast_x) / 200.0, 1.0) * 15
    
    # === HARBOR (x: +600 to +1500) — sea level with coastal features ===
    if x > 600:
        h = 0.0 + noise * 0.5
        
        # Moon-shaped bay: depression at harbor center (x≈1200, z≈0)
        bay_cx, bay_cz = 1200, 0
        bay_dist = math.sqrt((x - bay_cx)**2 + (z - bay_cz)**2)
        bay_radius = 250
        if bay_dist < bay_radius:
            bay_factor = 1.0 - (bay_dist / bay_radius)
            h -= bay_factor * 3.0  # dip below sea level in bay
        
        # Peninsula: elevated land jutting into sea (x≈1400, z≈200)
        pen_cx, pen_cz = 1400, 200
        pen_dist = math.sqrt((x - pen_cx)**2 + (z - pen_cz)**2)
        pen_radius = 150
        if pen_dist < pen_radius:
            pen_factor = 1.0 - (pen_dist / pen_radius)
            h += pen_factor * 25.0  # elevated peninsula
        
        # Castle hill: elevated point above harbor (x≈900, z≈0)
        castle_cx, castle_cz = 900, 0
        castle_dist = math.sqrt((x - castle_cx)**2 + (z - castle_cz)**2)
        castle_radius = 100
        if castle_dist < castle_radius:
            castle_factor = 1.0 - (castle_dist / castle_radius)
            h += castle_factor * 15.0  # castle hill
        
        # Cliffs south of harbor (z > 300, x > 1000): steep drop
        if z > 300 and x > 1000:
            cliff_factor = min((z - 300) / 100.0, 1.0)
            h -= cliff_factor * 5.0  # drop off at cliffs
        
        # Beach north of harbor (z < -300, x > 1000): gentle slope to water
        if z < -300 and x > 1000:
            beach_factor = min((-z - 300) / 200.0, 1.0)
            h -= beach_factor * 2.0  # gentle beach slope
        
        return h
    
    # === DOWNTOWN (x: +100 to +600) — gentle slope 5-15m down to harbor ===
    if x > 100:
        dt_blend = (600 - x) / 500.0  # 0 at harbor edge, 1 at inland
        return dt_blend * 15.0 + noise * 2.0
    
    # === INDUSTRIAL (x: -600 to +100) — plateau at 25m ===
    if x > -600:
        return 25.0 + noise * 3.0
    
    # === SUBURBS (x: -1000 to -400) — rolling hills 40-50m ===
    if x > -1000:
        return 45.0 + noise * 8.0
    
    # === RURAL (x: -1200 to -800) — higher hills 60-80m ===
    if x > -1200:
        r_blend = (-800 - x) / 400.0
        return 60.0 + r_blend * 20.0 + noise * 10.0
    
    return 0.0

def generate_heightmap():
    """Generate the heightmap PNG."""
    print("Generating heightmap...")
    img = Image.new('L', (W, H))  # 8-bit grayscale
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
    print(f"Size: {W}x{H} pixels, {MAP_SIZE}x{MAP_SIZE}m world")
    print(f"Height range: 0-{MAX_HEIGHT}m (0-255 in PNG)")
    
    # Also save a colorized version for visual reference
    img_color = Image.new('RGB', (W, H))
    color_pixels = img_color.load()
    for py in range(H):
        for px in range(W):
            val = pixels[px, py]
            x, z = pixel_to_world(px, py)
            h = val / 255.0 * MAX_HEIGHT
            
            if h < 0:
                # Deep water
                color_pixels[px, py] = (10, 40, 80)
            elif h < 1:
                # Shallow water / beach
                color_pixels[px, py] = (180, 160, 100)
            elif h < 5:
                # Harbor/coast
                color_pixels[px, py] = (80, 80, 80)
            elif h < 20:
                # Downtown
                color_pixels[px, py] = (60, 60, 70)
            elif h < 35:
                # Industrial
                color_pixels[px, py] = (70, 70, 75)
            elif h < 55:
                # Suburbs
                color_pixels[px, py] = (80, 120, 60)
            elif h < 85:
                # Rural
                color_pixels[px, py] = (100, 90, 50)
            else:
                # Canyon/mountain
                color_pixels[px, py] = (120, 110, 100)
    
    color_path = '/home/z/my-project/godot/assets/heightmap_preview.png'
    img_color.save(color_path)
    print(f"Colorized preview saved to {color_path}")

if __name__ == '__main__':
    generate_heightmap()
