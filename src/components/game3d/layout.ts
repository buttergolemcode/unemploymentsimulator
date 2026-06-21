// 3D World Layout — building positions for each scheme + open-world city blocks
import type { SchemeId } from '../../lib/game/types';

export interface BuildingPos {
  id: SchemeId;
  name: string;
  emoji: string;
  // 2D ground position (x, z)
  x: number;
  z: number;
  // Building dimensions
  width: number;
  depth: number;
  height: number;
  // Building color (hex)
  color: string;
  accentColor: string;
}

// 8 scheme buildings arranged around a central plaza, plus the world is now bigger.
// Layout: plaza at origin, scheme buildings in a ring around it.
export const BUILDINGS: BuildingPos[] = [
  {
    id: 'ecom',
    name: 'E-Com Warehouse',
    emoji: '📦',
    x: -14,
    z: -10,
    width: 5,
    depth: 5,
    height: 4,
    color: '#4ade80', // emerald
    accentColor: '#16a34a',
  },
  {
    id: 'trading',
    name: 'Trading Floor',
    emoji: '📈',
    x: 0,
    z: -16,
    width: 6,
    depth: 5,
    height: 7,
    color: '#22d3ee', // cyan
    accentColor: '#0891b2',
  },
  {
    id: 'gambling',
    name: 'Casino',
    emoji: '🎰',
    x: 14,
    z: -10,
    width: 5,
    depth: 5,
    height: 5,
    color: '#f59e0b', // amber
    accentColor: '#d97706',
  },
  {
    id: 'drugs',
    name: 'Trap House',
    emoji: '💊',
    x: -18,
    z: 4,
    width: 4,
    depth: 4,
    height: 3,
    color: '#a855f7', // purple
    accentColor: '#7e22ce',
  },
  {
    id: 'scam',
    name: 'Internet Cafe',
    emoji: '🎣',
    x: -8,
    z: 12,
    width: 5,
    depth: 4,
    height: 4,
    color: '#ec4899', // pink
    accentColor: '#be185d',
  },
  {
    id: 'robbery',
    name: 'Corner Store',
    emoji: '🔫',
    x: 8,
    z: 12,
    width: 4,
    depth: 4,
    height: 3,
    color: '#ef4444', // red
    accentColor: '#b91c1c',
  },
  {
    id: 'taxfraud',
    name: 'Accountant Office',
    emoji: '🧾',
    x: 18,
    z: 4,
    width: 5,
    depth: 4,
    height: 6,
    color: '#eab308', // yellow
    accentColor: '#a16207',
  },
  {
    id: 'wirefraud',
    name: 'Corporate Tower',
    emoji: '💸',
    x: 0,
    z: 18,
    width: 6,
    depth: 6,
    height: 12,
    color: '#64748b', // slate
    accentColor: '#334155',
  },
];

// ----------------- Open-world city blocks -----------------
// Background "filler" buildings placed around the playable plaza to make the world feel bigger.
// These are non-interactive — just visual city atmosphere.

export interface FillerBuilding {
  x: number;
  z: number;
  width: number;
  depth: number;
  height: number;
  color: string;
  hasWindows: boolean;
}

// Procedurally generate a grid of background buildings outside the plaza.
// Two rings of city blocks: inner ring (radius ~28-38) and outer ring (~40-58).
function generateFillerBuildings(): FillerBuilding[] {
  const out: FillerBuilding[] = [];
  // Color palette — moody night-city
  const palette = [
    '#1e293b', '#334155', '#475569', '#1f2937',
    '#374151', '#4b5563', '#1e1b4b', '#312e81',
    '#0f172a', '#1c1917', '#292524',
  ];

  // Grid layout: place buildings on a 12-unit grid, skip the central plaza area.
  const GRID = 11;
  const PLAZA_RADIUS = 26; // keep plaza clear of filler
  for (let gx = -6; gx <= 6; gx++) {
    for (let gz = -6; gz <= 6; gz++) {
      const cx = gx * GRID + (gz % 2 === 0 ? 0 : GRID / 2);
      const cz = gz * GRID;
      const r = Math.sqrt(cx * cx + cz * cz);
      if (r < PLAZA_RADIUS) continue;
      if (r > 58) continue;
      // Deterministic-ish random based on grid coords
      const seed = Math.abs(gx * 73856093 ^ gz * 19349663) % 1000;
      const rng = (n: number) => ((seed * (n + 1) * 9301 + 49297) % 233280) / 233280;
      // Building dimensions
      const w = 3 + rng(1) * 3;
      const d = 3 + rng(2) * 3;
      const h = 4 + rng(3) * 16;
      // Offset within the grid cell
      const ox = (rng(4) - 0.5) * (GRID - w - 2);
      const oz = (rng(5) - 0.5) * (GRID - d - 2);
      out.push({
        x: cx + ox,
        z: cz + oz,
        width: w,
        depth: d,
        height: h,
        color: palette[Math.floor(rng(6) * palette.length)],
        hasWindows: rng(7) > 0.25,
      });
    }
  }
  return out;
}

export const FILLER_BUILDINGS: FillerBuilding[] = generateFillerBuildings();

// Street segments — a grid of roads between the buildings for visual structure.
export interface StreetSegment {
  x: number;
  z: number;
  width: number;
  depth: number;
  horizontal: boolean; // true = runs along X, false = runs along Z
}

function generateStreets(): StreetSegment[] {
  const out: StreetSegment[] = [];
  // Main cross-axes through the plaza
  out.push({ x: 0, z: 0, width: 60, depth: 2.5, horizontal: true });
  out.push({ x: 0, z: 0, width: 2.5, depth: 60, horizontal: false });
  // Surrounding road ring at radius ~26
  // We'll just add 4 road strips forming a square
  out.push({ x: 0, z: 26, width: 60, depth: 2.5, horizontal: true });
  out.push({ x: 0, z: -26, width: 60, depth: 2.5, horizontal: true });
  out.push({ x: 26, z: 0, width: 2.5, depth: 60, horizontal: false });
  out.push({ x: -26, z: 0, width: 2.5, depth: 60, horizontal: false });
  return out;
}

export const STREETS: StreetSegment[] = generateStreets();

// Player spawn point
export const PLAYER_SPAWN: [number, number] = [0, 4];

// World bounds (player can't walk outside this radius) — enlarged for open world
export const WORLD_RADIUS = 60;

// Distance at which a building becomes "interactable"
export const INTERACT_DISTANCE = 5.5;

// Find nearest scheme building to a point
export function nearestBuilding(
  x: number,
  z: number,
): { building: BuildingPos; distance: number } | null {
  let nearest: BuildingPos | null = null;
  let nearestDist = Infinity;
  for (const b of BUILDINGS) {
    const dx = x - b.x;
    const dz = z - b.z;
    const d = Math.sqrt(dx * dx + dz * dz);
    if (d < nearestDist) {
      nearestDist = d;
      nearest = b;
    }
  }
  if (!nearest) return null;
  return { building: nearest, distance: nearestDist };
}
