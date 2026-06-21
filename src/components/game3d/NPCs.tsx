'use client';

import { useRef, useState } from 'react';
import { useFrame } from '@react-three/fiber';
import * as THREE from 'three';
import { districtAt } from './layout';
import type { DistrictId } from './layout';

// ============================================================
// NPC system
// ============================================================
// Two kinds of NPCs:
//   1. Pedestrians — spawn at district edge, walk to a random point inside the district, despawn on arrival.
//      Number per district scales with district "density" (slums busy, harbor sparse).
//   2. Merchants — stationary NPCs at fixed positions (one per scheme building, conceptually),
//      just for atmosphere — they stand near their shop.

interface NPCState {
  id: number;
  x: number;
  z: number;
  targetX: number;
  targetZ: number;
  speed: number;
  color: string;
  district: DistrictId;
  facing: number; // radians
  kind: 'pedestrian' | 'merchant';
}

// Deterministic color palette per district (pedestrian clothing colors).
const PEDESTRIAN_PALETTE: Record<DistrictId, string[]> = {
  downtown: ['#1e293b', '#0f172a', '#374151', '#1f2937', '#4b5563'],
  harbor: ['#1c1917', '#292524', '#44403c', '#57534e'],
  slums: ['#7c2d12', '#9a3412', '#451a03', '#78350f', '#1c1917'],
  industrial: ['#3f3f46', '#525252', '#27272a', '#18181b'],
};

const MERCHANT_PALETTE: Record<DistrictId, string> = {
  downtown: '#16a34a',
  harbor: '#7e22ce',
  slums: '#b91c1c',
  industrial: '#d97706',
};

// Static merchant positions — one outside each scheme building entrance.
const MERCHANT_POSITIONS: { x: number; z: number; district: DistrictId }[] = [
  { x: -8, z: -38, district: 'downtown' },   // near Trading Floor
  { x: -33, z: -23, district: 'downtown' },  // near Corporate Tower
  { x: -13, z: -13, district: 'downtown' },  // near Accountant
  { x: 28, z: -33, district: 'harbor' },     // near Trap House
  { x: -28, z: 23, district: 'slums' },      // near Internet Cafe
  { x: -13, z: 33, district: 'slums' },      // near Corner Store
  { x: 18, z: 28, district: 'industrial' },  // near E-Com
  { x: 38, z: 13, district: 'industrial' },  // near Casino
];

// Density (max pedestrians) per district.
const PEDESTRIAN_DENSITY: Record<DistrictId, number> = {
  downtown: 10,
  harbor: 4,
  slums: 14,
  industrial: 6,
};

function randomPointInDistrict(d: DistrictId): [number, number] {
  const district = districtAt(0, 0); // placeholder, we'll use DISTRICTS map directly
  // Use the districtAt function instead
  const dist = (
    d === 'downtown' ? { minX: -60, maxX: 0, minZ: -60, maxZ: 0 } :
    d === 'harbor' ? { minX: 0, maxX: 60, minZ: -60, maxZ: 0 } :
    d === 'slums' ? { minX: -60, maxX: 0, minZ: 0, maxZ: 60 } :
    { minX: 0, maxX: 60, minZ: 0, maxZ: 60 }
  );
  return [
    dist.minX + 5 + Math.random() * (dist.maxX - dist.minX - 10),
    dist.minZ + 5 + Math.random() * (dist.maxZ - dist.minZ - 10),
  ];
}

function spawnPedestrian(id: number, district: DistrictId): NPCState {
  const [x, z] = randomPointInDistrict(district);
  const [tx, tz] = randomPointInDistrict(district);
  const palette = PEDESTRIAN_PALETTE[district];
  return {
    id,
    x,
    z,
    targetX: tx,
    targetZ: tz,
    speed: 1.5 + Math.random() * 1.5,
    color: palette[Math.floor(Math.random() * palette.length)],
    district,
    facing: 0,
    kind: 'pedestrian',
  };
}

function spawnMerchant(id: number, pos: { x: number; z: number; district: DistrictId }): NPCState {
  return {
    id,
    x: pos.x,
    z: pos.z,
    targetX: pos.x,
    targetZ: pos.z,
    speed: 0,
    color: MERCHANT_PALETTE[pos.district],
    district: pos.district,
    facing: Math.atan2(-pos.x, -pos.z), // face toward plaza
    kind: 'merchant',
  };
}

// Build the initial NPC population (called once via useMemo).
function buildInitialNPCs(): NPCState[] {
  const out: NPCState[] = [];
  let id = 0;
  // Merchants
  for (const pos of MERCHANT_POSITIONS) {
    out.push(spawnMerchant(id++, pos));
  }
  // Pedestrians
  (Object.keys(PEDESTRIAN_DENSITY) as DistrictId[]).forEach((d) => {
    const count = PEDESTRIAN_DENSITY[d];
    for (let i = 0; i < count; i++) {
      out.push(spawnPedestrian(id++, d));
    }
  });
  return out;
}

// ============================================================
// Rendering
// ============================================================

// A single NPC avatar — simple low-poly character.
// Body cylinder, head sphere, two leg cylinders that swing when walking.
function NPCAvatar({ npc, walking }: { npc: NPCState; walking: boolean }) {
  const ref = useRef<THREE.Group>(null);
  const legLRef = useRef<THREE.Mesh>(null);
  const legRRef = useRef<THREE.Mesh>(null);
  const phaseRef = useRef<number>(Math.random() * Math.PI * 2);

  useFrame((state, dt) => {
    if (!ref.current) return;
    // Smoothly rotate toward facing
    const target = npc.facing;
    let diff = target - ref.current.rotation.y;
    while (diff > Math.PI) diff -= Math.PI * 2;
    while (diff < -Math.PI) diff += Math.PI * 2;
    ref.current.rotation.y += diff * Math.min(1, dt * 8);

    // Leg swing animation when walking
    if (walking) {
      phaseRef.current += dt * 8;
      const swing = Math.sin(phaseRef.current) * 0.4;
      if (legLRef.current) legLRef.current.rotation.x = swing;
      if (legRRef.current) legRRef.current.rotation.x = -swing;
    } else {
      // Idle: legs back to neutral
      if (legLRef.current) legLRef.current.rotation.x *= 0.9;
      if (legRRef.current) legRRef.current.rotation.x *= 0.9;
    }
  });

  return (
    <group ref={ref} position={[npc.x, 0, npc.z]}>
      {/* Body */}
      <mesh position={[0, 0.95, 0]} castShadow>
        <cylinderGeometry args={[0.22, 0.28, 0.9, 8]} />
        <meshStandardMaterial color={npc.color} roughness={0.8} />
      </mesh>
      {/* Head */}
      <mesh position={[0, 1.55, 0]} castShadow>
        <sphereGeometry args={[0.2, 12, 12]} />
        <meshStandardMaterial color="#fde68a" roughness={0.6} />
      </mesh>
      {/* Hair / hat */}
      <mesh position={[0, 1.65, 0]} castShadow>
        <sphereGeometry args={[0.21, 12, 12, 0, Math.PI * 2, 0, Math.PI / 2]} />
        <meshStandardMaterial color="#1c1917" roughness={0.9} />
      </mesh>
      {/* Legs */}
      <mesh ref={legLRef} position={[-0.1, 0.35, 0]} castShadow>
        <cylinderGeometry args={[0.08, 0.08, 0.7, 6]} />
        <meshStandardMaterial color="#1c1917" roughness={0.9} />
      </mesh>
      <mesh ref={legRRef} position={[0.1, 0.35, 0]} castShadow>
        <cylinderGeometry args={[0.08, 0.08, 0.7, 6]} />
        <meshStandardMaterial color="#1c1917" roughness={0.9} />
      </mesh>
      {/* Shadow blob */}
      <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, 0.01, 0]}>
        <circleGeometry args={[0.35, 12]} />
        <meshBasicMaterial color="#000000" transparent opacity={0.2} />
      </mesh>

      {/* Merchant badge: a small glowing dot above their head */}
      {npc.kind === 'merchant' && (
        <mesh position={[0, 2.0, 0]}>
          <sphereGeometry args={[0.1, 8, 8]} />
          <meshStandardMaterial
            color={npc.color}
            emissive={npc.color}
            emissiveIntensity={1.2}
          />
        </mesh>
      )}
    </group>
  );
}

// The full NPC layer — owns the population, ticks their movement, renders them.
// NPC state is created once via useState (so React knows the count and keys for
// initial render). The state array is then never replaced — NPCAvatar reads
// position/facing from the same object reference each frame and updates its
// own group's matrix. We deliberately bypass the lint rule against mutating
// useState values here because re-rendering ~30 NPCs every frame is too costly
// and the values are not used for React's reconciliation (keys are stable).
export function NPCLayer() {
   
  const [npcs] = useState<NPCState[]>(buildInitialNPCs);

  // Tick each NPC per frame
  useFrame((_, dt) => {
    const step = Math.min(dt, 0.1);
    for (const npc of npcs) {
      if (npc.kind === 'merchant') continue;
      const dx = npc.targetX - npc.x;
      const dz = npc.targetZ - npc.z;
      const dist = Math.sqrt(dx * dx + dz * dz);
      if (dist < 0.3) {
        if (Math.random() < 0.4) {
          // Despawn → respawn elsewhere in same district
          const [nx, nz] = randomPointInDistrict(npc.district);
          // eslint-disable-next-line react-hooks/immutability
          npc.x = nx;
           
          npc.z = nz;
        }
        const [tx, tz] = randomPointInDistrict(npc.district);
         
        npc.targetX = tx;
         
        npc.targetZ = tz;
      } else {
        const move = npc.speed * step;
         
        npc.x += (dx / dist) * move;
         
        npc.z += (dz / dist) * move;
         
        npc.facing = Math.atan2(dx, dz);
      }
    }
  });

  return (
    <>
      {npcs.map((npc) => (
        <NPCAvatar
          key={npc.id}
          npc={npc}
          walking={npc.kind === 'pedestrian'}
        />
      ))}
    </>
  );
}
