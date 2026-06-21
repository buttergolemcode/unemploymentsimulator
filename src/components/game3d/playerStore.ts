// Player movement store — separate from game logic state
import { create } from 'zustand';
import { PLAYER_SPAWN, INTERACT_DISTANCE, nearestBuilding, BUILDINGS, FILLER_BUILDINGS } from './layout';
import type { SchemeId } from '../../lib/game/types';
import { setActionPanelOpen } from '../../lib/game/store';

// Pre-compute building AABBs once for collision (expanded by player radius).
// Each entry: { minX, maxX, minZ, maxZ }
const PLAYER_RADIUS = 0.5;

interface AABB {
  minX: number;
  maxX: number;
  minZ: number;
  maxZ: number;
}

const COLLIDER_AABBS: AABB[] = [
  // Scheme buildings (use full width/depth, expanded by player radius)
  ...BUILDINGS.map((b) => ({
    minX: b.x - b.width / 2 - PLAYER_RADIUS,
    maxX: b.x + b.width / 2 + PLAYER_RADIUS,
    minZ: b.z - b.depth / 2 - PLAYER_RADIUS,
    maxZ: b.z + b.depth / 2 + PLAYER_RADIUS,
  })),
  // Filler buildings (only the close ones matter; we include all of them — 80 is cheap to test)
  ...FILLER_BUILDINGS.map((b) => ({
    minX: b.x - b.width / 2 - PLAYER_RADIUS,
    maxX: b.x + b.width / 2 + PLAYER_RADIUS,
    minZ: b.z - b.depth / 2 - PLAYER_RADIUS,
    maxZ: b.z + b.depth / 2 + PLAYER_RADIUS,
  })),
];

// Check if a point (x, z) is inside any building AABB.
function isBlocked(x: number, z: number): boolean {
  for (const a of COLLIDER_AABBS) {
    if (x > a.minX && x < a.maxX && z > a.minZ && z < a.maxZ) return true;
  }
  return false;
}

// Move from (x, z) by (dx, dz), but stop at building walls.
// Resolves axis-separately so the player can slide along a wall instead of getting stuck.
function moveWithCollision(x: number, z: number, dx: number, dz: number): { x: number; z: number } {
  let nx = x;
  let nz = z;
  // Try X movement first
  if (dx !== 0) {
    const testX = x + dx;
    if (!isBlocked(testX, z)) {
      nx = testX;
    }
  }
  // Then Z movement (using the already-updated X so we slide correctly)
  if (dz !== 0) {
    const testZ = z + dz;
    if (!isBlocked(nx, testZ)) {
      nz = testZ;
    }
  }
  return { x: nx, z: nz };
}

export type CameraMode = 'first' | 'third';

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

  // --- First-person camera state ---
  // Camera mode (first person default, third person optional)
  cameraMode: CameraMode;
  toggleCamera: () => void;
  // Look direction (yaw = around Y axis, pitch = up/down)
  yaw: number;
  pitch: number;
  // Apply mouse delta to look (called by pointer-lock mousemove)
  applyMouseDelta: (dx: number, dy: number) => void;
  // Whether pointer is locked (for FPS mouse-look)
  pointerLocked: boolean;
  setPointerLocked: (locked: boolean) => void;
  // Manual movement input from WASD in FPS mode (set per-frame by keyboard controller)
  fpsInput: { forward: number; right: number }; // -1..1
  setFpsInput: (input: { forward: number; right: number }) => void;
  // Walking flag set by FPS controller when keys are pressed
  fpsMoving: boolean;
}

const SPEED = 7; // units per second (third-person click-to-move)
const FPS_SPEED = 5.5; // units per second (first-person WASD)
const PITCH_LIMIT = Math.PI / 2 - 0.05; // ~85 degrees
const WORLD_MAX = 60; // world bounds (enlarged for open-world)

export const usePlayer = create<PlayerStore>((set, get) => ({
  x: PLAYER_SPAWN[0],
  z: PLAYER_SPAWN[1],
  targetX: PLAYER_SPAWN[0],
  targetZ: PLAYER_SPAWN[1],
  walking: false,
  nearbyBuildingId: null,
  actionPanelOpen: false,

  // First-person defaults
  cameraMode: 'first',
  yaw: 0, // looking toward -Z (north)
  pitch: 0,
  pointerLocked: false,
  fpsInput: { forward: 0, right: 0 },
  fpsMoving: false,

  setActionPanel: (open) => {
    setActionPanelOpen(open);
    set({ actionPanelOpen: open });
  },

  toggleCamera: () => {
    set((s) => ({ cameraMode: s.cameraMode === 'first' ? 'third' : 'first' }));
  },

  setPointerLocked: (locked) => set({ pointerLocked: locked }),

  applyMouseDelta: (dx, dy) => {
    if (get().actionPanelOpen) return;
    const sensitivity = 0.0022;
    set((s) => {
      const newYaw = s.yaw - dx * sensitivity;
      let newPitch = s.pitch - dy * sensitivity;
      newPitch = Math.max(-PITCH_LIMIT, Math.min(PITCH_LIMIT, newPitch));
      return { yaw: newYaw, pitch: newPitch };
    });
  },

  setFpsInput: (input) => {
    const moving = input.forward !== 0 || input.right !== 0;
    set((s) => ({
      fpsInput: input,
      fpsMoving: moving,
      // Cancel any click-to-move target when using WASD in FPS mode
      walking: moving ? false : s.walking,
    }));
  },

  moveTo: (x, z) => {
    if (get().actionPanelOpen) return;
    if (get().cameraMode === 'first') {
      // In first-person, click-to-move doesn't make sense — ignore.
      // (The ground click handler should not call this in FPS mode.)
      return;
    }
    set({ targetX: x, targetZ: z, walking: true });
  },

  tick: (dt) => {
    const s = get();
    if (s.actionPanelOpen) return false;

    // --- WASD movement (yaw-relative) — used for BOTH first-person and third-person ---
    if (s.fpsMoving) {
      const { forward, right } = s.fpsInput;
      // Forward vector based on yaw (yaw=0 → looking -Z, so forward = (-sin(yaw), 0, -cos(yaw)))
      const fx = -Math.sin(s.yaw);
      const fz = -Math.cos(s.yaw);
      // Right vector (perpendicular, 90° clockwise from forward)
      const rx = Math.cos(s.yaw);
      const rz = -Math.sin(s.yaw);

      const dx = fx * forward + rx * right;
      const dz = fz * forward + rz * right;
      const len = Math.sqrt(dx * dx + dz * dz);
      if (len > 0) {
        const ndx = dx / len;
        const ndz = dz / len;
        const step = FPS_SPEED * dt;
        // Apply collision: try to move, sliding along walls if blocked
        const result = moveWithCollision(s.x, s.z, ndx * step, ndz * step);
        // Clamp to world bounds (circle)
        const r = Math.sqrt(result.x * result.x + result.z * result.z);
        if (r <= WORLD_MAX) {
          const near = nearestBuilding(result.x, result.z);
          const newId = near && near.distance < INTERACT_DISTANCE ? near.building.id : null;
          set({ x: result.x, z: result.z, nearbyBuildingId: newId });
          return true;
        }
      }
      return false;
    }

    // --- Click-to-move (only used in third-person when player clicks the ground) ---
    if (s.walking) {
      const dx = s.targetX - s.x;
      const dz = s.targetZ - s.z;
      const dist = Math.sqrt(dx * dx + dz * dz);
      if (dist < 0.05) {
        const near = nearestBuilding(s.x, s.z);
        const newId = near && near.distance < INTERACT_DISTANCE ? near.building.id : null;
        set({ walking: false, nearbyBuildingId: newId });
        return false;
      }
      const step = Math.min(dist, SPEED * dt);
      const ndx = (dx / dist) * step;
      const ndz = (dz / dist) * step;
      const result = moveWithCollision(s.x, s.z, ndx, ndz);
      const near = nearestBuilding(result.x, result.z);
      const newId = near && near.distance < INTERACT_DISTANCE ? near.building.id : null;
      // Make the player face the walk direction in third-person mode
      const newYaw = Math.atan2(dx, dz);
      set({ x: result.x, z: result.z, nearbyBuildingId: newId, yaw: newYaw });
      // If we didn't actually move (collision), stop walking to avoid jittering into a wall
      const moved = Math.abs(result.x - s.x) > 0.001 || Math.abs(result.z - s.z) > 0.001;
      if (!moved) {
        set({ walking: false });
      }
      return true;
    }

    // Idle — still update nearby-building state
    const near = nearestBuilding(s.x, s.z);
    const newId = near && near.distance < INTERACT_DISTANCE ? near.building.id : null;
    if (newId !== s.nearbyBuildingId) {
      set({ nearbyBuildingId: newId });
    }
    return false;
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
      // Don't reset cameraMode/yaw/pitch on game restart — let them persist
    });
  },
}));

export { WORLD_MAX };
