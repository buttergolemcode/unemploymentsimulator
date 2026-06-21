// 3D World Layout — district-based city with scheme buildings + atmospheric zones.
import type { SchemeId } from '../../lib/game/types';

// ============================================================
// Districts
// ============================================================

export type DistrictId = 'downtown' | 'harbor' | 'slums' | 'industrial';

export interface District {
  id: DistrictId;
  name: string;
  // Quadrant bounds on the world plane (square)
  minX: number;
  maxX: number;
  minZ: number;
  maxZ: number;
  // Building palette per district
  palette: string[];
  // Height range for procedural buildings
  heightMin: number;
  heightMax: number;
  // Window lit ratio (0..1)
  windowLitChance: number;
  // Atmospheric modifiers
  fogDensity: number; // 0..1, higher = more local fog
  ambientColor: string;
  groundColor: string;
  // District light tint (subtle color cast)
  lightTint: string;
  // Lamp density multiplier
  lampDensity: number;
  // Display emoji used on minimap / debug
  emoji: string;
}

// Four quadrants of the world, each 60 units wide/tall, centered on origin.
// World spans -60..60 on both axes.
export const DISTRICTS: Record<DistrictId, District> = {
  downtown: {
    id: 'downtown',
    name: 'Downtown',
    minX: -60,
    maxX: 0,
    minZ: -60,
    maxZ: 0,
    palette: ['#475569', '#334155', '#1e293b', '#64748b', '#3f3f46'],
    heightMin: 8,
    heightMax: 28,
    windowLitChance: 0.55,
    fogDensity: 0.15,
    ambientColor: '#1e3a8a',
    groundColor: '#1a1a1a',
    lightTint: '#fef3c7',
    lampDensity: 1.2,
    emoji: '🌆',
  },
  harbor: {
    id: 'harbor',
    name: 'Harbor',
    minX: 0,
    maxX: 60,
    minZ: -60,
    maxZ: 0,
    palette: ['#1c1917', '#292524', '#44403c', '#0f172a', '#1e293b'],
    heightMin: 4,
    heightMax: 14,
    windowLitChance: 0.35,
    fogDensity: 0.55,
    ambientColor: '#0c4a6e',
    groundColor: '#171717',
    lightTint: '#67e8f9',
    lampDensity: 0.8,
    emoji: '⚓',
  },
  slums: {
    id: 'slums',
    name: 'Slums',
    minX: -60,
    maxX: 0,
    minZ: 0,
    maxZ: 60,
    palette: ['#1c1917', '#292524', '#451a03', '#7c2d12', '#3f1d1d'],
    heightMin: 3,
    heightMax: 9,
    windowLitChance: 0.7,
    fogDensity: 0.35,
    ambientColor: '#451a03',
    groundColor: '#1a0f0a',
    lightTint: '#fb923c',
    lampDensity: 1.5,
    emoji: '🏚️',
  },
  industrial: {
    id: 'industrial',
    name: 'Industrial',
    minX: 0,
    maxX: 60,
    minZ: 0,
    maxZ: 60,
    palette: ['#1f2937', '#374151', '#0f172a', '#1c1917', '#525252'],
    heightMin: 5,
    heightMax: 16,
    windowLitChance: 0.25,
    fogDensity: 0.4,
    ambientColor: '#1f2937',
    groundColor: '#161616',
    lightTint: '#a3e635',
    lampDensity: 0.6,
    emoji: '🏭',
  },
};

// Look up the district at a world position.
export function districtAt(x: number, z: number): District {
  if (x < 0 && z < 0) return DISTRICTS.downtown;
  if (x >= 0 && z < 0) return DISTRICTS.harbor;
  if (x < 0 && z >= 0) return DISTRICTS.slums;
  return DISTRICTS.industrial;
}

// ============================================================
// Scheme buildings (interactive)
// ============================================================

export interface BuildingPos {
  id: SchemeId;
  name: string;
  emoji: string;
  x: number;
  z: number;
  width: number;
  depth: number;
  height: number;
  color: string;
  accentColor: string;
  district: DistrictId;
}

// 8 scheme buildings — each placed in a district that fits its vibe.
// Downtown = corporate/trading/finance; Harbor = smuggling/drugs;
// Slums = scam/robbery/drugs; Industrial = e-com/warehouse/labs.
export const BUILDINGS: BuildingPos[] = [
  // Downtown (NW)
  {
    id: 'trading',
    name: 'Trading Floor',
    emoji: '📈',
    x: -10,
    z: -40,
    width: 6,
    depth: 5,
    height: 8,
    color: '#22d3ee',
    accentColor: '#0891b2',
    district: 'downtown',
  },
  {
    id: 'wirefraud',
    name: 'Corporate Tower',
    emoji: '💸',
    x: -35,
    z: -25,
    width: 7,
    depth: 7,
    height: 18,
    color: '#64748b',
    accentColor: '#334155',
    district: 'downtown',
  },
  {
    id: 'taxfraud',
    name: 'Accountant Office',
    emoji: '🧾',
    x: -15,
    z: -15,
    width: 5,
    depth: 4,
    height: 6,
    color: '#eab308',
    accentColor: '#a16207',
    district: 'downtown',
  },
  // Harbor (NE) — smuggling, drug imports
  {
    id: 'drugs',
    name: 'Trap House',
    emoji: '💊',
    x: 30,
    z: -35,
    width: 5,
    depth: 5,
    height: 4,
    color: '#a855f7',
    accentColor: '#7e22ce',
    district: 'harbor',
  },
  // Slums (SW) — scam, robbery, drugs
  {
    id: 'scam',
    name: 'Internet Cafe',
    emoji: '🎣',
    x: -30,
    z: 25,
    width: 5,
    depth: 4,
    height: 4,
    color: '#ec4899',
    accentColor: '#be185d',
    district: 'slums',
  },
  {
    id: 'robbery',
    name: 'Corner Store',
    emoji: '🔫',
    x: -15,
    z: 35,
    width: 4,
    depth: 4,
    height: 3,
    color: '#ef4444',
    accentColor: '#b91c1c',
    district: 'slums',
  },
  // Industrial (SE) — warehouses, e-com, gambling (backroom casino)
  {
    id: 'ecom',
    name: 'E-Com Warehouse',
    emoji: '📦',
    x: 20,
    z: 30,
    width: 6,
    depth: 6,
    height: 5,
    color: '#4ade80',
    accentColor: '#16a34a',
    district: 'industrial',
  },
  {
    id: 'gambling',
    name: 'Casino',
    emoji: '🎰',
    x: 40,
    z: 15,
    width: 6,
    depth: 6,
    height: 6,
    color: '#f59e0b',
    accentColor: '#d97706',
    district: 'industrial',
  },
];

// ============================================================
// Filler buildings — generated per-district
// ============================================================

export interface FillerBuilding {
  x: number;
  z: number;
  width: number;
  depth: number;
  height: number;
  color: string;
  hasWindows: boolean;
  windowLitChance: number;
  district: DistrictId;
}

// Deterministic RNG per (gx, gz, salt) — so layout is stable across reloads.
function hashRand(gx: number, gz: number, salt: number): number {
  const v = Math.abs((gx * 73856093) ^ (gz * 19349663) ^ (salt * 83492791)) % 99991;
  return v / 99991;
}

function generateFillerBuildings(): FillerBuilding[] {
  const out: FillerBuilding[] = [];
  const GRID = 9; // tighter grid → denser city
  const HALF_RANGE = 60;

  for (let gx = -HALF_RANGE; gx <= HALF_RANGE; gx += GRID) {
    for (let gz = -HALF_RANGE; gz <= HALF_RANGE; gz += GRID) {
      // Each cell: maybe place a building here
      // Cell center
      const cx = gx + GRID / 2;
      const cz = gz + GRID / 2;
      const r = Math.sqrt(cx * cx + cz * cz);

      // Skip if too close to spawn plaza (origin)
      if (r < 14) continue;

      // Skip if too close to a scheme building
      let tooClose = false;
      for (const b of BUILDINGS) {
        if (Math.sqrt((cx - b.x) ** 2 + (cz - b.z) ** 2) < 7) {
          tooClose = true;
          break;
        }
      }
      if (tooClose) continue;

      // Skip if outside world bounds
      if (r > 58) continue;

      // Sometimes leave a gap (street / empty lot)
      if (hashRand(gx, gz, 99) < 0.18) continue;

      // District for this cell
      const d = districtAt(cx, cz);

      // Building dimensions
      const w = 3 + hashRand(gx, gz, 1) * 3;
      const dep = 3 + hashRand(gx, gz, 2) * 3;
      const h = d.heightMin + hashRand(gx, gz, 3) * (d.heightMax - d.heightMin);

      // Offset within cell
      const ox = (hashRand(gx, gz, 4) - 0.5) * (GRID - w - 1.5);
      const oz = (hashRand(gx, gz, 5) - 0.5) * (GRID - dep - 1.5);

      out.push({
        x: cx + ox,
        z: cz + oz,
        width: w,
        depth: dep,
        height: h,
        color: d.palette[Math.floor(hashRand(gx, gz, 6) * d.palette.length)],
        hasWindows: hashRand(gx, gz, 7) > 0.15,
        windowLitChance: d.windowLitChance,
        district: d.id,
      });
    }
  }
  return out;
}

export const FILLER_BUILDINGS: FillerBuilding[] = generateFillerBuildings();

// ============================================================
// Streets — major roads between districts
// ============================================================

export interface StreetSegment {
  x: number;
  z: number;
  width: number;
  depth: number;
  horizontal: boolean;
}

function generateStreets(): StreetSegment[] {
  const out: StreetSegment[] = [];
  // Main cross-axes through origin (district boundaries)
  out.push({ x: 0, z: 0, width: 120, depth: 3, horizontal: true });
  out.push({ x: 0, z: 0, width: 3, depth: 120, horizontal: false });
  // District ring roads (perimeter streets)
  out.push({ x: 0, z: 55, width: 120, depth: 2, horizontal: true });
  out.push({ x: 0, z: -55, width: 120, depth: 2, horizontal: true });
  out.push({ x: 55, z: 0, width: 2, depth: 120, horizontal: false });
  out.push({ x: -55, z: 0, width: 2, depth: 120, horizontal: false });
  // Internal district streets (a few per district)
  // Downtown (NW)
  out.push({ x: -30, z: -30, width: 60, depth: 1.5, horizontal: true });
  out.push({ x: -30, z: 0, width: 60, depth: 1.5, horizontal: true });
  out.push({ x: -45, z: -30, width: 1.5, depth: 60, horizontal: false });
  out.push({ x: -15, z: -30, width: 1.5, depth: 60, horizontal: false });
  // Harbor (NE)
  out.push({ x: 30, z: -30, width: 60, depth: 1.5, horizontal: true });
  out.push({ x: 15, z: -30, width: 1.5, depth: 60, horizontal: false });
  out.push({ x: 45, z: -30, width: 1.5, depth: 60, horizontal: false });
  // Slums (SW)
  out.push({ x: -30, z: 30, width: 60, depth: 1.5, horizontal: true });
  out.push({ x: -45, z: 30, width: 1.5, depth: 60, horizontal: false });
  out.push({ x: -15, z: 30, width: 1.5, depth: 60, horizontal: false });
  // Industrial (SE)
  out.push({ x: 30, z: 30, width: 60, depth: 1.5, horizontal: true });
  out.push({ x: 15, z: 30, width: 1.5, depth: 60, horizontal: false });
  out.push({ x: 45, z: 30, width: 1.5, depth: 60, horizontal: false });
  return out;
}

export const STREETS: StreetSegment[] = generateStreets();

// ============================================================
// Spawn / world bounds
// ============================================================

export const PLAYER_SPAWN: [number, number] = [0, 4]; // central plaza
export const WORLD_RADIUS = 60;
export const INTERACT_DISTANCE = 6;

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
