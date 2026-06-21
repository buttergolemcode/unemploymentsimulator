// Player movement store — separate from game logic state
import { create } from 'zustand';
import { PLAYER_SPAWN, INTERACT_DISTANCE, nearestBuilding } from './layout';
import type { SchemeId } from '../../lib/game/types';
import { setActionPanelOpen } from '../../lib/game/store';

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

    // --- First-person movement (WASD relative to yaw) ---
    if (s.cameraMode === 'first' && s.fpsMoving) {
      const { forward, right } = s.fpsInput;
      // Forward vector based on yaw (yaw=0 means looking -Z, so forward = (-sin(yaw), 0, -cos(yaw)))
      const fx = -Math.sin(s.yaw);
      const fz = -Math.cos(s.yaw);
      // Right vector (perpendicular, 90° clockwise)
      const rx = Math.cos(s.yaw);
      const rz = -Math.sin(s.yaw);

      let dx = fx * forward + rx * right;
      let dz = fz * forward + rz * right;
      const len = Math.sqrt(dx * dx + dz * dz);
      if (len > 0) {
        dx /= len;
        dz /= len;
        const step = FPS_SPEED * dt;
        const nx = s.x + dx * step;
        const nz = s.z + dz * step;
        // Clamp to world bounds (circle)
        const r = Math.sqrt(nx * nx + nz * nz);
        if (r <= WORLD_MAX) {
          const near = nearestBuilding(nx, nz);
          const newId = near && near.distance < INTERACT_DISTANCE ? near.building.id : null;
          set({ x: nx, z: nz, nearbyBuildingId: newId });
          return true;
        }
      }
      return false;
    }

    // --- Third-person click-to-move ---
    if (!s.walking) {
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
      const near = nearestBuilding(s.x, s.z);
      const newId = near && near.distance < INTERACT_DISTANCE ? near.building.id : null;
      set({ walking: false, nearbyBuildingId: newId });
      return false;
    }
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
      // Don't reset cameraMode/yaw/pitch on game restart — let them persist
    });
  },
}));

export { WORLD_MAX };
