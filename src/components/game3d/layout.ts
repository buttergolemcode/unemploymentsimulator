// 3D World Layout — building positions for each scheme
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

// A small "city block" layout — 8 buildings arranged around a central plaza.
// The player spawns at origin (0,0,0). Buildings are arranged in a rough ring.
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

// Player spawn point
export const PLAYER_SPAWN: [number, number] = [0, 0];

// World bounds (player can't walk outside this radius)
export const WORLD_RADIUS = 28;

// Distance at which a building becomes "interactable" (player is close enough to enter)
export const INTERACT_DISTANCE = 5.5;

// Find nearest building to a point
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
