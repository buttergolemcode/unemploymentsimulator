// Procedural terrain heightmap — determines ground height at any (x, z) position.
// The world has 4 zones with different terrain:
//   - City Core (r < 80): flat (y=0)
//   - Suburbs (80-150): gentle rolling hills (0-3m)
//   - Rural (150-220): hills and valleys (5-20m)
//   - Borders (220-250): mountains, ocean, forest barriers
//
// Uses layered sine/noise functions for natural-looking terrain.
// All functions are pure (deterministic) — same input always gives same output.

// ============================================================
// Height functions
// ============================================================

// Simple deterministic pseudo-noise (no Perlin needed — sine combinations look good enough)
function noise2D(x: number, z: number, freq: number, seed: number): number {
  const v = Math.sin(x * freq + seed * 1.7) * Math.cos(z * freq + seed * 2.3) +
            Math.sin(x * freq * 2.1 + seed * 3.1) * Math.cos(z * freq * 1.7 + seed * 4.7) * 0.5;
  return v / 1.5; // normalize to ~-1..1
}

// Get terrain height at world position (x, z)
export function getTerrainHeight(x: number, z: number): number {
  const r = Math.sqrt(x * x + z * z);

  // City core: completely flat
  if (r < 75) return 0;

  // Transition zone: smooth blend from flat to terrain
  // 75-85: blend from 0 to suburb terrain
  if (r < 85) {
    const t = (r - 75) / 10; // 0..1
    const suburbH = getSuburbHeight(x, z);
    return suburbH * t;
  }

  // Suburbs: gentle rolling hills (0-3m)
  if (r < 150) {
    return getSuburbHeight(x, z);
  }

  // Rural: hills and valleys (5-20m)
  if (r < 220) {
    return getRuralHeight(x, z);
  }

  // Borders: depends on direction
  return getBorderHeight(x, z, r);
}

function getSuburbHeight(x: number, z: number): number {
  // Very gentle hills — 0 to 3 meters
  const h1 = noise2D(x, z, 0.01, 1) * 1.5;
  const h2 = noise2D(x, z, 0.03, 2) * 0.5;
  return Math.max(0, h1 + h2);
}

function getRuralHeight(x: number, z: number): number {
  // Rolling hills — 5 to 20 meters
  const h1 = noise2D(x, z, 0.005, 3) * 8;     // large hills
  const h2 = noise2D(x, z, 0.015, 4) * 3;     // medium bumps
  const h3 = noise2D(x, z, 0.05, 5) * 0.8;    // small detail
  return Math.max(0, h1 + h2 + h3 + 5); // offset so valleys are at ~5m, peaks at ~20m
}

function getBorderHeight(x: number, z: number, r: number): number {
  // Angle from center (0 = north/+Z, π/2 = east/+X, π = south/-Z, -π/2 = west/-X)
  const angle = Math.atan2(x, z);

  // NORTH (angle near 0): Mountains — steep climb starting at r=220
  if (Math.abs(angle) < 0.7) {
    const mountainStart = 220;
    if (r < mountainStart) return getRuralHeight(x, z);
    const t = (r - mountainStart) / 30;
    const mountainH = t * t * 50; // quadratic rise
    return getRuralHeight(x, z) + mountainH;
  }

  // SOUTH (angle near π): Ocean — ground drops below sea level
  if (Math.abs(angle - Math.PI) < 0.7 || Math.abs(angle + Math.PI) < 0.7) {
    const oceanStart = 215;
    if (r < oceanStart) return getRuralHeight(x, z);
    const t = (r - oceanStart) / 35;
    return getRuralHeight(x, z) - t * 8; // descend into water
  }

  // EAST (angle near π/2): Highway barrier — gentle rise then wall
  if (Math.abs(angle - Math.PI / 2) < 0.6) {
    const wallStart = 225;
    if (r < wallStart) return getRuralHeight(x, z);
    const t = (r - wallStart) / 20;
    return getRuralHeight(x, z) + t * 15; // ramp up to highway barrier
  }

  // WEST (angle near -π/2): Military zone — flat fenced area
  if (Math.abs(angle + Math.PI / 2) < 0.6) {
    return getRuralHeight(x, z); // same as rural, fence is visual
  }

  // Everything else (corners): forest/dense terrain
  return getRuralHeight(x, z);
}

// ============================================================
// Zone classification
// ============================================================

export type TerrainZone = 'city' | 'suburbs' | 'rural' | 'mountain' | 'ocean' | 'highway_barrier' | 'military' | 'forest';

export function getZone(x: number, z: number): TerrainZone {
  const r = Math.sqrt(x * x + z * z);
  if (r < 75) return 'city';
  if (r < 150) return 'suburbs';
  if (r < 220) return 'rural';

  const angle = Math.atan2(x, z);
  if (Math.abs(angle) < 0.7) return 'mountain';
  if (Math.abs(angle - Math.PI) < 0.7 || Math.abs(angle + Math.PI) < 0.7) return 'ocean';
  if (Math.abs(angle - Math.PI / 2) < 0.6) return 'highway_barrier';
  if (Math.abs(angle + Math.PI / 2) < 0.6) return 'military';
  return 'forest';
}

// ============================================================
// Water level
// ============================================================

export const SEA_LEVEL = -3; // ocean surface at y=-3

export function isUnderwater(x: number, z: number): boolean {
  return getTerrainHeight(x, z) < SEA_LEVEL;
}

export function isOcean(x: number, z: number): boolean {
  return getZone(x, z) === 'ocean';
}

// ============================================================
// Terrain mesh generation helper — returns height at grid point
// Used by the TerrainMesh component in Scene.tsx
// ============================================================

export function terrainHeightAt(x: number, z: number): number {
  return getTerrainHeight(x, z);
}
