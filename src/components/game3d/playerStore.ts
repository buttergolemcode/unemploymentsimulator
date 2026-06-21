// Player movement store — separate from game logic state
import { create } from 'zustand';
import { PLAYER_SPAWN, INTERACT_DISTANCE, nearestBuilding } from './layout';
import type { SchemeId } from '../../lib/game/types';
import { setActionPanelOpen } from '../../lib/game/store';

interface PlayerStore {
  // Player position (x, z) on the ground plane
  x: number;
  z: number;
  // Target position the player is walking toward
  targetX: number;
  targetZ: number;
  // Whether the player is currently walking
  walking: boolean;
  // Currently nearby building (within interact distance), null if none
  nearbyBuildingId: SchemeId | null;
  // Whether the action panel is open (pauses movement)
  actionPanelOpen: boolean;
  // Setter for action panel
  setActionPanel: (open: boolean) => void;
  // Move to a target point
  moveTo: (x: number, z: number) => void;
  // Per-frame update (called by the R3F loop). Returns true if movement happened.
  tick: (dt: number) => boolean;
  // Snap player back to spawn
  resetPosition: () => void;
}

const SPEED = 7; // units per second

export const usePlayer = create<PlayerStore>((set, get) => ({
  x: PLAYER_SPAWN[0],
  z: PLAYER_SPAWN[1],
  targetX: PLAYER_SPAWN[0],
  targetZ: PLAYER_SPAWN[1],
  walking: false,
  nearbyBuildingId: null,
  actionPanelOpen: false,

  setActionPanel: (open) => {
    setActionPanelOpen(open);
    set({ actionPanelOpen: open });
  },

  moveTo: (x, z) => {
    if (get().actionPanelOpen) return;
    set({ targetX: x, targetZ: z, walking: true });
  },

  tick: (dt) => {
    const s = get();
    if (s.actionPanelOpen) return false;
    if (!s.walking) {
      // Still need to update nearby building even if not walking
      const near = nearestBuilding(s.x, s.z);
      const newId = near && near.distance < INTERACT_DISTANCE ? near.building.id : null;
      if (newId !== s.nearbyBuildingId) {
        set({ nearbyBuildingId: newId });
      }
      return false;
    }
    const dx = s.targetX - s.x;
    const dz = s.targetZ - s.z;
    const dist = Math.sqrt(dx * dx + dz * dz);
    if (dist < 0.05) {
      // Arrived
      const near = nearestBuilding(s.x, s.z);
      const newId = near && near.distance < INTERACT_DISTANCE ? near.building.id : null;
      set({ walking: false, nearbyBuildingId: newId });
      return false;
    }
    // Move toward target
    const step = Math.min(dist, SPEED * dt);
    const nx = s.x + (dx / dist) * step;
    const nz = s.z + (dz / dist) * step;
    const near = nearestBuilding(nx, nz);
    const newId = near && near.distance < INTERACT_DISTANCE ? near.building.id : null;
    set({ x: nx, z: nz, nearbyBuildingId: newId });
    return true;
  },

  resetPosition: () => {
    set({
      x: PLAYER_SPAWN[0],
      z: PLAYER_SPAWN[1],
      targetX: PLAYER_SPAWN[0],
      targetZ: PLAYER_SPAWN[1],
      walking: false,
      nearbyBuildingId: null,
      actionPanelOpen: false,
    });
  },
}));
