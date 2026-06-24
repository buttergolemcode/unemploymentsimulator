// 3D World Layout — city + suburbs with clear street/sidewalk/building separation.
// 1 unit = 1 meter. Realistic proportions.
import type { SchemeId } from '../../lib/game/types';

// ============================================================
// World dimensions
// ============================================================
// City core: -60..60 (120×120m)
// Suburbs ring: 60..100 (extends outward)
// Total world radius: 110

export const CITY_RADIUS = 60;
export const SUBURB_RADIUS = 100;
export const WORLD_RADIUS = 110;
export const PLAYER_SPAWN: [number, number] = [0, 6];
export const INTERACT_DISTANCE = 6;

// ============================================================
// Districts
// ============================================================

export type DistrictId = 'downtown' | 'harbor' | 'slums' | 'industrial' | 'suburbs';

export interface District {
  id: DistrictId;
  name: string;
  emoji: string;
  palette: string[];
  heightMin: number;
  heightMax: number;
  windowLitChance: number;
  groundColor: string;
  lightTint: string;
  lampDensity: number;
}

export const DISTRICTS: Record<DistrictId, District> = {
  downtown: {
    id: 'downtown', name: 'Downtown', emoji: '🌆',
    palette: ['#475569', '#334155', '#1e293b', '#64748b'],
    heightMin: 24, heightMax: 80,
    windowLitChance: 0.55, groundColor: '#1a1a1a',
    lightTint: '#fef3c7', lampDensity: 1.2,
  },
  harbor: {
    id: 'harbor', name: 'Harbor', emoji: '⚓',
    palette: ['#1c1917', '#292524', '#44403c', '#0f172a'],
    heightMin: 8, heightMax: 22,
    windowLitChance: 0.35, groundColor: '#171717',
    lightTint: '#67e8f9', lampDensity: 0.8,
  },
  slums: {
    id: 'slums', name: 'Slums', emoji: '🏚️',
    palette: ['#1c1917', '#292524', '#451a03', '#7c2d12'],
    heightMin: 5, heightMax: 14,
    windowLitChance: 0.7, groundColor: '#1a0f0a',
    lightTint: '#fb923c', lampDensity: 1.5,
  },
  industrial: {
    id: 'industrial', name: 'Industrial', emoji: '🏭',
    palette: ['#1f2937', '#374151', '#0f172a', '#1c1917'],
    heightMin: 9, heightMax: 24,
    windowLitChance: 0.25, groundColor: '#161616',
    lightTint: '#a3e635', lampDensity: 0.6,
  },
  suburbs: {
    id: 'suburbs', name: 'Suburbs', emoji: '🏠',
    palette: ['#525252', '#737373', '#404040', '#525252'],
    heightMin: 4, heightMax: 9,
    windowLitChance: 0.4, groundColor: '#1a2a1a',
    lightTint: '#a3e635', lampDensity: 0.4,
  },
};

// District lookup: 4 city quadrants + suburbs ring outside city radius
export function districtAt(x: number, z: number): District {
  const r = Math.sqrt(x * x + z * z);
  if (r > CITY_RADIUS) return DISTRICTS.suburbs;
  if (x < 0 && z < 0) return DISTRICTS.downtown;
  if (x >= 0 && z < 0) return DISTRICTS.harbor;
  if (x < 0 && z >= 0) return DISTRICTS.slums;
  return DISTRICTS.industrial;
}

// ============================================================
// Road network — defines where streets + sidewalks are
// ============================================================
// A road has: center line (X or Z axis), asphalt half-width, sidewalk width.
// Buildings are FORBIDDEN within (asphalt + sidewalk) distance from any road center.
// NPCs walk ONLY on sidewalk areas.

export interface Road {
  // Road runs along X (horizontal) or Z (vertical)
  axis: 'x' | 'z';
  // Position on the perpendicular axis (e.g. for axis='x', this is the Z coord)
  pos: number;
  // Half-width of asphalt (meters). Road width = 2 * asphaltHalf.
  asphaltHalf: number;
  // Sidewalk width on each side (meters)
  sidewalkWidth: number;
  // Length of the road (meters, centered on origin)
  length: number;
  // Is this a main road? (wider, has yellow lines)
  isMain: boolean;
}

// Total clearance from road center to building edge = asphaltHalf + sidewalkWidth
export function roadClearance(road: Road): number {
  return road.asphaltHalf + road.sidewalkWidth;
}

function generateRoads(): Road[] {
  const roads: Road[] = [];
  const MAIN_HALF = 8;       // 16m wide main roads (2 lanes each direction + parking)
  const SIDE_HALF = 5.5;     // 11m wide side roads (1 lane each direction)
  const SW = 3;              // 3m sidewalks on each side

  // === City core roads (within ±60) ===
  // Main cross axes (district boundaries)
  roads.push({ axis: 'x', pos: 0, asphaltHalf: MAIN_HALF, sidewalkWidth: SW, length: 220, isMain: true });
  roads.push({ axis: 'z', pos: 0, asphaltHalf: MAIN_HALF, sidewalkWidth: SW, length: 220, isMain: true });

  // City ring road at radius ~58
  roads.push({ axis: 'x', pos: 58, asphaltHalf: MAIN_HALF, sidewalkWidth: SW, length: 130, isMain: true });
  roads.push({ axis: 'x', pos: -58, asphaltHalf: MAIN_HALF, sidewalkWidth: SW, length: 130, isMain: true });
  roads.push({ axis: 'z', pos: 58, asphaltHalf: MAIN_HALF, sidewalkWidth: SW, length: 130, isMain: true });
  roads.push({ axis: 'z', pos: -58, asphaltHalf: MAIN_HALF, sidewalkWidth: SW, length: 130, isMain: true });

  // Internal district streets — every 20m
  for (let p = -40; p <= 40; p += 20) {
    if (p === 0) continue; // skip main axis
    roads.push({ axis: 'x', pos: p, asphaltHalf: SIDE_HALF, sidewalkWidth: SW, length: 120, isMain: false });
    roads.push({ axis: 'z', pos: p, asphaltHalf: SIDE_HALF, sidewalkWidth: SW, length: 120, isMain: false });
  }

  // === Suburb roads (60..100 ring) ===
  // Grid of smaller roads in the suburbs
  for (let p = -100; p <= 100; p += 25) {
    if (Math.abs(p) <= 58) continue; // skip city core (already has roads there)
    roads.push({ axis: 'x', pos: p, asphaltHalf: SIDE_HALF, sidewalkWidth: 2.5, length: 220, isMain: false });
    roads.push({ axis: 'z', pos: p, asphaltHalf: SIDE_HALF, sidewalkWidth: 2.5, length: 220, isMain: false });
  }

  // Highway connecting city to suburbs (4 cardinal directions)
  roads.push({ axis: 'x', pos: 0, asphaltHalf: MAIN_HALF, sidewalkWidth: 1, length: 220, isMain: true });

  return roads;
}

export const ROADS: Road[] = generateRoads();

// Check if a point (x, z) is on a road (asphalt or sidewalk)
export function isOnRoad(x: number, z: number): boolean {
  for (const r of ROADS) {
    if (r.axis === 'x') {
      // Road runs along X, at Z = r.pos
      if (Math.abs(z - r.pos) < r.asphaltHalf + r.sidewalkWidth && Math.abs(x) < r.length / 2) return true;
    } else {
      // Road runs along Z, at X = r.pos
      if (Math.abs(x - r.pos) < r.asphaltHalf + r.sidewalkWidth && Math.abs(z) < r.length / 2) return true;
    }
  }
  return false;
}

// Check if a point is on asphalt only (for vehicle driving + NPC avoidance)
export function isOnAsphalt(x: number, z: number): boolean {
  for (const r of ROADS) {
    if (r.axis === 'x') {
      if (Math.abs(z - r.pos) < r.asphaltHalf && Math.abs(x) < r.length / 2) return true;
    } else {
      if (Math.abs(x - r.pos) < r.asphaltHalf && Math.abs(z) < r.length / 2) return true;
    }
  }
  return false;
}

// Check if a point is on a sidewalk (between asphalt edge and building zone)
export function isOnSidewalk(x: number, z: number): boolean {
  for (const r of ROADS) {
    const dist = r.axis === 'x' ? Math.abs(z - r.pos) : Math.abs(x - r.pos);
    const along = r.axis === 'x' ? Math.abs(x) : Math.abs(z);
    if (dist >= r.asphaltHalf && dist < r.asphaltHalf + r.sidewalkWidth && along < r.length / 2) return true;
  }
  return false;
}

// Check if a point is in a building zone (not on road, not on sidewalk)
export function isBuildable(x: number, z: number): boolean {
  return !isOnRoad(x, z);
}

// ============================================================
// Scheme buildings (interactive) — placed NEXT to roads, not on them
// ============================================================

export interface BuildingPos {
  id: SchemeId;
  name: string;
  emoji: string;
  x: number; z: number;
  width: number; depth: number; height: number;
  color: string; accentColor: string;
  district: DistrictId;
}

export const BUILDINGS: BuildingPos[] = [
  // Downtown (NW) — tall corporate
  { id: 'trading', name: 'Trading Floor', emoji: '📈', x: -12, z: -42, width: 12, depth: 10, height: 36, color: '#22d3ee', accentColor: '#0891b2', district: 'downtown' },
  { id: 'wirefraud', name: 'Corporate Tower', emoji: '💸', x: -38, z: -22, width: 16, depth: 14, height: 72, color: '#64748b', accentColor: '#334155', district: 'downtown' },
  { id: 'taxfraud', name: 'Accountant Office', emoji: '🧾', x: -22, z: -12, width: 10, depth: 9, height: 21, color: '#eab308', accentColor: '#a16207', district: 'downtown' },
  // Harbor (NE)
  { id: 'drugs', name: 'Trap House', emoji: '💊', x: 28, z: -38, width: 9, depth: 8, height: 9, color: '#a855f7', accentColor: '#7e22ce', district: 'harbor' },
  // Slums (SW)
  { id: 'scam', name: 'Internet Cafe', emoji: '🎣', x: -28, z: 22, width: 8, depth: 7, height: 7, color: '#ec4899', accentColor: '#be185d', district: 'slums' },
  { id: 'robbery', name: 'Corner Store', emoji: '🔫', x: -18, z: 38, width: 7, depth: 7, height: 5, color: '#ef4444', accentColor: '#b91c1c', district: 'slums' },
  // Industrial (SE)
  { id: 'ecom', name: 'E-Com Warehouse', emoji: '📦', x: 22, z: 28, width: 14, depth: 12, height: 11, color: '#4ade80', accentColor: '#16a34a', district: 'industrial' },
  { id: 'gambling', name: 'Casino', emoji: '🎰', x: 42, z: 18, width: 14, depth: 12, height: 14, color: '#f59e0b', accentColor: '#d97706', district: 'industrial' },
];

// ============================================================
// Filler buildings — placed ONLY in buildable zones (not on roads)
// ============================================================

export interface FillerBuilding {
  x: number; z: number;
  width: number; depth: number; height: number;
  color: string;
  hasWindows: boolean;
  windowLitChance: number;
  district: DistrictId;
}

function hashRand(gx: number, gz: number, salt: number): number {
  const v = Math.abs((gx * 73856093) ^ (gz * 19349663) ^ (salt * 83492791)) % 99991;
  return v / 99991;
}

function generateFillerBuildings(): FillerBuilding[] {
  const out: FillerBuilding[] = [];
  const GRID = 20;     // 20m grid cells
  const HALF = 100;    // extend into suburbs

  for (let gx = -HALF; gx <= HALF; gx += GRID) {
    for (let gz = -HALF; gz <= HALF; gz += GRID) {
      const cx = gx + GRID / 2;
      const cz = gz + GRID / 2;
      const r = Math.sqrt(cx * cx + cz * cz);

      // Skip spawn plaza
      if (r < 18) continue;
      // Skip if outside world
      if (r > 105) continue;

      // Skip if on a road (building zone check)
      if (isOnRoad(cx, cz)) continue;

      // Skip if too close to a scheme building
      let tooClose = false;
      for (const b of BUILDINGS) {
        if (Math.sqrt((cx - b.x) ** 2 + (cz - b.z) ** 2) < Math.max(b.width, b.depth) / 2 + 6) {
          tooClose = true; break;
        }
      }
      if (tooClose) continue;

      // Leave gaps (parks, parking lots)
      if (hashRand(gx, gz, 99) < 0.25) continue;

      const d = districtAt(cx, cz);
      const w = 8 + hashRand(gx, gz, 1) * 6;
      const dep = 7 + hashRand(gx, gz, 2) * 5;
      const h = d.heightMin + hashRand(gx, gz, 3) * (d.heightMax - d.heightMin);

      // Offset within cell — but verify the offset position is still buildable
      const margin = 2;
      const maxOff = (GRID - w - margin * 2) / 2;
      const ox = (hashRand(gx, gz, 4) - 0.5) * maxOff;
      const oz = (hashRand(gx, gz, 5) - 0.5) * maxOff;
      const fx = cx + ox;
      const fz = cz + oz;

      // Final check: building corners must not overlap road
      if (isOnRoad(fx - w / 2, fz - dep / 2) || isOnRoad(fx + w / 2, fz + dep / 2) ||
          isOnRoad(fx - w / 2, fz + dep / 2) || isOnRoad(fx + w / 2, fz - dep / 2)) continue;

      out.push({
        x: fx, z: fz, width: w, depth: dep, height: h,
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
// Street segments (for rendering — derived from roads)
// ============================================================

export interface StreetSegment {
  x: number; z: number;
  width: number; depth: number;
  horizontal: boolean;
  sidewalkWidth: number;
  hasCenterLine: boolean;
  isMainRoad: boolean;
}

function generateStreetSegments(): StreetSegment[] {
  return ROADS.map(r => ({
    x: r.axis === 'x' ? 0 : r.pos,
    z: r.axis === 'x' ? r.pos : 0,
    width: r.axis === 'x' ? r.length : r.asphaltHalf * 2,
    depth: r.axis === 'x' ? r.asphaltHalf * 2 : r.length,
    horizontal: r.axis === 'x',
    sidewalkWidth: r.sidewalkWidth,
    hasCenterLine: true,
    isMainRoad: r.isMain,
  }));
}

export const STREETS: StreetSegment[] = generateStreetSegments();

// ============================================================
// Helpers
// ============================================================

export function nearestBuilding(x: number, z: number): { building: BuildingPos; distance: number } | null {
  let nearest: BuildingPos | null = null;
  let nearestDist = Infinity;
  for (const b of BUILDINGS) {
    const d = Math.sqrt((x - b.x) ** 2 + (z - b.z) ** 2);
    if (d < nearestDist) { nearestDist = d; nearest = b; }
  }
  return nearest ? { building: nearest, distance: nearestDist } : null;
}

// Get a random sidewalk point near a given position (for NPC spawning)
export function randomSidewalkPoint(nearX: number, nearZ: number, maxDist: number): { x: number; z: number } | null {
  for (let i = 0; i < 20; i++) {
    const dx = (Math.random() - 0.5) * maxDist;
    const dz = (Math.random() - 0.5) * maxDist;
    const x = nearX + dx;
    const z = nearZ + dz;
    if (isOnSidewalk(x, z)) return { x, z };
  }
  return null;
}
