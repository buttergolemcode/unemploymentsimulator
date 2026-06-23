// Vehicle movement store — separate from player + game state.
// We use a simple kinematic approach (no full Rapier physics yet, since
// the player physics are also kinematic). We can upgrade to dynamic Rapier
// bodies later when we want crashes/flips/etc.

import { create } from 'zustand';
import { BUILDINGS, FILLER_BUILDINGS } from './layout';
import { usePlayer } from './playerStore';

export interface VehicleState {
  id: number;
  x: number;
  z: number;
  yaw: number;          // facing direction (radians)
  speed: number;        // current forward speed (m/s, can be negative for reverse)
  color: string;
  // Static config
  maxSpeed: number;     // m/s forward
  maxReverse: number;   // m/s reverse (positive value)
  accel: number;        // m/s²
  brake: number;        // m/s² deceleration when braking
  friction: number;     // m/s² natural deceleration
  turnRate: number;     // radians/second at max (scales down with speed)
  width: number;        // for collision
  length: number;       // for collision
}

// Pre-computed building AABBs for vehicle collision (slightly larger than player AABBs
// because vehicles are bigger — we use the vehicle's half-extent).
const VEHICLE_HALF_W = 1.0;  // 2m wide car
const VEHICLE_HALF_L = 2.2;  // 4.4m long car

interface AABB {
  minX: number;
  maxX: number;
  minZ: number;
  maxZ: number;
}

const BUILDING_AABBS: AABB[] = [
  ...BUILDINGS.map((b) => ({
    minX: b.x - b.width / 2 - VEHICLE_HALF_L,
    maxX: b.x + b.width / 2 + VEHICLE_HALF_L,
    minZ: b.z - b.depth / 2 - VEHICLE_HALF_L,
    maxZ: b.z + b.depth / 2 + VEHICLE_HALF_L,
  })),
  ...FILLER_BUILDINGS.map((b) => ({
    minX: b.x - b.width / 2 - VEHICLE_HALF_L,
    maxX: b.x + b.width / 2 + VEHICLE_HALF_L,
    minZ: b.z - b.depth / 2 - VEHICLE_HALF_L,
    maxZ: b.z + b.depth / 2 + VEHICLE_HALF_L,
  })),
];

function isBlocked(x: number, z: number): boolean {
  for (const a of BUILDING_AABBS) {
    if (x > a.minX && x < a.maxX && z > a.minZ && z < a.maxZ) return true;
  }
  return false;
}

// World bounds for vehicles (slightly tighter than player since they're bigger)
const VEHICLE_WORLD_MAX = 58;

interface VehicleStore {
  vehicles: VehicleState[];
  // ID of the vehicle the player is currently in (null = on foot)
  inVehicleId: number | null;
  // Input state (set per-frame by keyboard controller when in vehicle)
  input: { throttle: number; brake: number; steer: number };  // -1..1
  setInput: (input: { throttle: number; brake: number; steer: number }) => void;
  // Enter/exit the vehicle with given ID (or the nearest one if no ID)
  enterVehicle: (id?: number) => boolean;
  exitVehicle: () => void;
  // Per-frame update
  tick: (dt: number) => void;
  // Reset
  reset: () => void;
}

// Initial parked vehicles around the city
function makeInitialVehicles(): VehicleState[] {
  const colors = ['#dc2626', '#2563eb', '#16a34a', '#facc15', '#7c3aed', '#f97316', '#06b6d4', '#ec4899'];
  const positions: { x: number; z: number; yaw: number }[] = [
    // Near spawn (central plaza edges)
    { x: 8, z: 4, yaw: 0 },       // facing north, parked by roadside
    { x: -8, z: 6, yaw: Math.PI },
    { x: 4, z: -8, yaw: Math.PI / 2 },
    // Downtown
    { x: -20, z: -25, yaw: 0 },
    { x: -38, z: -10, yaw: Math.PI / 2 },
    // Harbor
    { x: 22, z: -30, yaw: -Math.PI / 2 },
    { x: 38, z: -8, yaw: 0 },
    // Slums
    { x: -22, z: 22, yaw: Math.PI },
    { x: -38, z: 10, yaw: 0 },
    // Industrial
    { x: 22, z: 28, yaw: -Math.PI / 2 },
    { x: 42, z: 10, yaw: Math.PI },
  ];

  return positions.map((pos, i) => ({
    id: i,
    x: pos.x,
    z: pos.z,
    yaw: pos.yaw,
    speed: 0,
    color: colors[i % colors.length],
    maxSpeed: 22,       // ~80 km/h
    maxReverse: 8,
    accel: 8,
    brake: 14,
    friction: 3,
    turnRate: 1.8,
    width: 2,
    length: 4.4,
  }));
}

// Find nearest vehicle within enter-range of the player
function findNearestEnterableVehicle(px: number, pz: number): VehicleState | null {
  const vehicles = useVehicle.getState().vehicles;
  const ENTER_RANGE = 4; // 4 meters
  let nearest: VehicleState | null = null;
  let nearestDist = Infinity;
  for (const v of vehicles) {
    const dx = v.x - px;
    const dz = v.z - pz;
    const d = Math.sqrt(dx * dx + dz * dz);
    if (d < ENTER_RANGE && d < nearestDist) {
      nearestDist = d;
      nearest = v;
    }
  }
  return nearest;
}

export const useVehicle = create<VehicleStore>((set, get) => ({
  vehicles: makeInitialVehicles(),
  inVehicleId: null,
  input: { throttle: 0, brake: 0, steer: 0 },

  setInput: (input) => set({ input }),

  enterVehicle: (id) => {
    const state = get();
    if (state.inVehicleId !== null) return false; // already in a vehicle
    let target: VehicleState | undefined;
    if (id !== undefined) {
      target = state.vehicles.find((v) => v.id === id);
    } else {
      const player = usePlayer.getState();
      target = findNearestEnterableVehicle(player.x, player.z) ?? undefined;
    }
    if (!target) return false;
    set({ inVehicleId: target.id });
    // Snap player position to vehicle (so when they exit, they don't get stuck in a wall)
    usePlayer.getState().setActionPanel(true); // pause player movement while driving
    return true;
  },

  exitVehicle: () => {
    const state = get();
    if (state.inVehicleId === null) return;
    const v = state.vehicles.find((veh) => veh.id === state.inVehicleId);
    if (v) {
      // Place player beside the vehicle (left side)
      const exitOffsetX = Math.cos(v.yaw) * -1.8;
      const exitOffsetZ = -Math.sin(v.yaw) * -1.8;
      const exitX = v.x + exitOffsetX;
      const exitZ = v.z + exitOffsetZ;
      // Clamp: don't exit into a wall
      if (!isBlocked(exitX, exitZ)) {
        usePlayer.setState({ x: exitX, z: exitZ, yaw: v.yaw });
      } else {
        // Try right side
        const rX = v.x - exitOffsetX;
        const rZ = v.z - exitOffsetZ;
        if (!isBlocked(rX, rZ)) {
          usePlayer.setState({ x: rX, z: rZ, yaw: v.yaw });
        } else {
          // Try behind
          const bX = v.x - Math.sin(v.yaw) * 3;
          const bZ = v.z - Math.cos(v.yaw) * 3;
          usePlayer.setState({ x: bX, z: bZ, yaw: v.yaw });
        }
      }
    }
    set({ inVehicleId: null, input: { throttle: 0, brake: 0, steer: 0 } });
    usePlayer.getState().setActionPanel(false); // resume player movement
  },

  tick: (dt) => {
    const state = get();
    if (state.inVehicleId === null) return;
    const v = state.vehicles.find((veh) => veh.id === state.inVehicleId);
    if (!v) return;

    const { throttle, brake, steer } = state.input;

    // Apply throttle/brake to speed
    if (throttle > 0) {
      v.speed += v.accel * throttle * dt;
      if (v.speed > v.maxSpeed) v.speed = v.maxSpeed;
    } else if (throttle < 0) {
      // Reverse
      v.speed += -v.accel * Math.abs(throttle) * dt * 0.6; // reverse accel is slower
      if (v.speed < -v.maxReverse) v.speed = -v.maxReverse;
    } else {
      // Natural friction
      if (v.speed > 0) {
        v.speed -= v.friction * dt;
        if (v.speed < 0) v.speed = 0;
      } else if (v.speed < 0) {
        v.speed += v.friction * dt;
        if (v.speed > 0) v.speed = 0;
      }
    }
    // Brake (always decelerates toward 0)
    if (brake > 0) {
      const decel = v.brake * brake * dt;
      if (v.speed > 0) {
        v.speed = Math.max(0, v.speed - decel);
      } else if (v.speed < 0) {
        v.speed = Math.min(0, v.speed + decel);
      }
    }

    // Steering (only effective when moving; scales with speed)
    const speedFactor = Math.min(1, Math.abs(v.speed) / 5); // full steer at 5 m/s+
    const turn = steer * v.turnRate * speedFactor * dt;
    // Reverse steering direction when going backwards (so it feels like a real car)
    if (v.speed < 0) {
      v.yaw -= turn;
    } else {
      v.yaw += turn;
    }

    // Compute new position
    const dx = Math.sin(v.yaw) * v.speed * dt;
    const dz = Math.cos(v.yaw) * v.speed * dt;

    // Try X movement
    const newX = v.x + dx;
    if (!isBlocked(newX, v.z)) {
      v.x = newX;
    } else {
      v.speed *= 0.3; // crash slow-down
    }
    // Try Z movement
    const newZ = v.z + dz;
    if (!isBlocked(v.x, newZ)) {
      v.z = newZ;
    } else {
      v.speed *= 0.3;
    }

    // World bounds
    const r = Math.sqrt(v.x * v.x + v.z * v.z);
    if (r > VEHICLE_WORLD_MAX) {
      const scale = VEHICLE_WORLD_MAX / r;
      v.x *= scale;
      v.z *= scale;
      v.speed *= 0.3;
    }

    // Sync player position to vehicle (so when they exit, they're in the right spot)
    usePlayer.setState({ x: v.x, z: v.z, yaw: v.yaw });

    // Trigger re-render of subscribers
    set({ vehicles: [...state.vehicles] });
  },

  reset: () => {
    set({
      vehicles: makeInitialVehicles(),
      inVehicleId: null,
      input: { throttle: 0, brake: 0, steer: 0 },
    });
  },
}));
