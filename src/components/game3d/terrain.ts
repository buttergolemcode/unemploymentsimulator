// Procedural terrain system — heightmap function + mesh generation.
// The terrain is flat in the city core, gently rolling in suburbs,
// hilly in rural areas, mountainous at the northern border, and
// below sea level at the southern ocean.

// ============================================================
// Height function
// ============================================================
// Deterministic value-noise based on integer hashing.
// Returns terrain height in meters at world position (x, z).

function hash2(x: number, z: number): number {
  const h = Math.sin(x * 127.1 + z * 311.7) * 43758.5453;
  return h - Math.floor(h); // 0..1
}

function smoothNoise(x: number, z: number): number {
  const ix = Math.floor(x);
  const iz = Math.floor(z);
  const fx = x - ix;
  const fz = z - iz;
  // Smoothstep interpolation
  const sx = fx * fx * (3 - 2 * fx);
  const sz = fz * fz * (3 - 2 * fz);
  const n00 = hash2(ix, iz);
  const n10 = hash2(ix + 1, iz);
  const n01 = hash2(ix, iz + 1);
  const n11 = hash2(ix + 1, iz + 1);
  return n00 * (1 - sx) * (1 - sz) + n10 * sx * (1 - sz) + n01 * (1 - sx) * sz + n11 * sx * sz;
}

function octave(x: number, z: number, freq: number, amp: number): number {
  return smoothNoise(x * freq, z * freq) * amp;
}

// Multi-octave fractal noise (0..1 range)
function fractalNoise(x: number, z: number, octaves: number): number {
  let value = 0;
  let amp = 1;
  let freq = 1;
  let max = 0;
  for (let i = 0; i < octaves; i++) {
    value += smoothNoise(x * freq * 0.01, z * freq * 0.01) * amp;
    max += amp;
    amp *= 0.5;
    freq *= 2;
  }
  return value / max;
}

// Main terrain height function. Returns Y in meters.
// City core (r < 75): flat at 0
// Suburbs (75 < r < 140): gentle rolling 0-3m
// Rural (140 < r < 200): hills 5-20m
// Mountains north (r > 200, z < -100): steep 25-50m
// Ocean south (r > 200, z > 100): below sea level -2 to -8m
// Forest edges: moderate hills
export function terrainHeight(x: number, z: number): number {
  const r = Math.sqrt(x * x + z * z);

  // City core — perfectly flat
  if (r < 80) return 0;

  // Smooth transition zone (80-100): blend from flat to terrain
  const cityBlend = Math.max(0, Math.min(1, (r - 80) / 20));

  // Base terrain noise
  let h = 0;

  if (r < 150) {
    // Suburbs: gentle rolling hills (0-4m)
    h = fractalNoise(x, z, 1) * 4;
  } else if (r < 220) {
    // Rural: hills (5-20m)
    h = 5 + fractalNoise(x, z, 2) * 15;
  } else {
    // Outer regions — depends on direction
    if (z < -120) {
      // North: mountains (25-55m)
      const mountainFactor = Math.max(0, (r - 220) / 30);
      h = 25 + fractalNoise(x, z, 3) * 30 * Math.min(1, mountainFactor);
    } else if (z > 120) {
      // South: ocean (below sea level)
      h = -2 - Math.max(0, (r - 220) / 20) * 8;
    } else {
      // East/West: moderate hills + forest
      h = 10 + fractalNoise(x, z, 2) * 15;
    }
  }

  // Blend with flat city
  return h * cityBlend;
}

// ============================================================
// Terrain mesh generation
// ============================================================
// Creates a large plane with vertices displaced by terrainHeight().
// Resolution is higher near the city and lower far out (for perf).

export interface TerrainMeshData {
  geometry: THREE.PlaneGeometry;
}

import * as THREE from 'three';

export function createTerrainGeometry(size: number, segments: number): THREE.PlaneGeometry {
  const geo = new THREE.PlaneGeometry(size, size, segments, segments);
  geo.rotateX(-Math.PI / 2);

  const pos = geo.attributes.position as THREE.BufferAttribute;
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i);
    const z = pos.getZ(i);
    const y = terrainHeight(x, z);
    pos.setY(i, y);
  }
  geo.computeVertexNormals();
  return geo;
}

// ============================================================
// Terrain vertex colors — green for grass, gray for rock, sand near water
// ============================================================
export function applyTerrainColors(geo: THREE.PlaneGeometry): void {
  const pos = geo.attributes.position as THREE.BufferAttribute;
  const colors = new Float32Array(pos.count * 3);
  const grassColor = new THREE.Color('#3a5a2a');
  const grassDark = new THREE.Color('#2a4a1a');
  const rockColor = new THREE.Color('#6b5b4a');
  const sandColor = new THREE.Color('#8a7a5a');
  const dirtColor = new THREE.Color('#4a3a2a');
  const cityColor = new THREE.Color('#1a1a1a');

  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i);
    const z = pos.getZ(i);
    const y = pos.getY(i);
    const r = Math.sqrt(x * x + z * z);

    const c = new THREE.Color();
    if (r < 70) {
      // City — dark gray
      c.copy(cityColor);
    } else if (y < 0) {
      // Underwater — sand
      c.copy(sandColor);
    } else if (y < 1) {
      // Near water — sand
      c.lerpColors(sandColor, grassColor, y);
    } else if (y < 8) {
      // Low grass
      c.lerpColors(grassColor, grassDark, Math.random() * 0.3);
    } else if (y < 20) {
      // Hills — darker grass + dirt
      c.lerpColors(grassDark, dirtColor, (y - 8) / 12);
    } else {
      // Mountains — rock
      c.lerpColors(dirtColor, rockColor, Math.min(1, (y - 20) / 15));
    }

    colors[i * 3] = c.r;
    colors[i * 3 + 1] = c.g;
    colors[i * 3 + 2] = c.b;
  }
  geo.setAttribute('color', new THREE.BufferAttribute(colors, 3));
}

// ============================================================
// Water surface
// ============================================================
// Simple animated water plane at y = WATER_LEVEL.
export const WATER_LEVEL = -0.8;

export function createWaterGeometry(size: number, segments: number): THREE.PlaneGeometry {
  const geo = new THREE.PlaneGeometry(size, size, segments, segments);
  geo.rotateX(-Math.PI / 2);
  return geo;
}
