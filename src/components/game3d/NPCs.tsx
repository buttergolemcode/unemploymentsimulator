'use client';

import { useRef, useState } from 'react';
import type { RefCallback } from 'react';
import { useFrame } from '@react-three/fiber';
import * as THREE from 'three';
import { districtAt, isOnSidewalk, ROADS, randomSidewalkPoint } from './layout';
import { terrainHeight } from './terrain';
import type { DistrictId } from './layout';

// ============================================================
// NPC system — pedestrians walk on sidewalks, merchants stand near buildings
// ============================================================

interface NPCState {
  id: number;
  x: number;
  z: number;
  targetX: number;
  targetZ: number;
  speed: number;
  color: string;
  district: DistrictId;
  facing: number;
  kind: 'pedestrian' | 'merchant';
}

const PEDESTRIAN_PALETTE: Record<DistrictId, string[]> = {
  downtown: ['#1e293b', '#0f172a', '#374151', '#1f2937', '#4b5563'],
  harbor: ['#1c1917', '#292524', '#44403c', '#57534e'],
  slums: ['#7c2d12', '#9a3412', '#451a03', '#78350f', '#1c1917'],
  industrial: ['#3f3f46', '#525252', '#27272a', '#18181b'],
  suburbs: ['#525252', '#737373', '#404040', '#525252'],
};

const MERCHANT_PALETTE: Record<DistrictId, string> = {
  downtown: '#16a34a',
  harbor: '#7e22ce',
  slums: '#b91c1c',
  industrial: '#d97706',
  suburbs: '#0891b2',
};

// Merchant positions — near scheme building entrances, on sidewalks
const MERCHANT_POSITIONS: { x: number; z: number; district: DistrictId }[] = [
  { x: -8, z: -38, district: 'downtown' },
  { x: -33, z: -18, district: 'downtown' },
  { x: -18, z: -10, district: 'downtown' },
  { x: 25, z: -35, district: 'harbor' },
  { x: -25, z: 20, district: 'slums' },
  { x: -14, z: 35, district: 'slums' },
  { x: 18, z: 25, district: 'industrial' },
  { x: 38, z: 15, district: 'industrial' },
];

const PEDESTRIAN_DENSITY: Record<DistrictId, number> = {
  downtown: 8,
  harbor: 3,
  slums: 10,
  industrial: 5,
  suburbs: 4,
};

// Find a random sidewalk point within a district
function randomSidewalkInDistrict(d: DistrictId): [number, number] {
  // Try roads within the district's area
  const bounds = d === 'downtown' ? { minX: -60, maxX: 0, minZ: -60, maxZ: 0 } :
    d === 'harbor' ? { minX: 0, maxX: 60, minZ: -60, maxZ: 0 } :
    d === 'slums' ? { minX: -60, maxX: 0, minZ: 0, maxZ: 60 } :
    d === 'industrial' ? { minX: 0, maxX: 60, minZ: 0, maxZ: 60 } :
    { minX: -100, maxX: 100, minZ: -100, maxZ: 100 };

  for (let i = 0; i < 30; i++) {
    const x = bounds.minX + Math.random() * (bounds.maxX - bounds.minX);
    const z = bounds.minZ + Math.random() * (bounds.maxZ - bounds.minZ);
    if (isOnSidewalk(x, z)) return [x, z];
  }
  // Fallback: any road position
  return randomSidewalkPoint(0, 0, 100) ?? [0, 10];
}

function spawnPedestrian(id: number, district: DistrictId): NPCState {
  const [x, z] = randomSidewalkInDistrict(district);
  const [tx, tz] = randomSidewalkInDistrict(district);
  const palette = PEDESTRIAN_PALETTE[district];
  return {
    id, x, z, targetX: tx, targetZ: tz,
    speed: 1.2 + Math.random() * 1.0,
    color: palette[Math.floor(Math.random() * palette.length)],
    district, facing: 0, kind: 'pedestrian',
  };
}

function spawnMerchant(id: number, pos: { x: number; z: number; district: DistrictId }): NPCState {
  return {
    id, x: pos.x, z: pos.z, targetX: pos.x, targetZ: pos.z,
    speed: 0, color: MERCHANT_PALETTE[pos.district],
    district: pos.district, facing: 0, kind: 'merchant',
  };
}

function buildInitialNPCs(): NPCState[] {
  const out: NPCState[] = [];
  let id = 0;
  for (const pos of MERCHANT_POSITIONS) out.push(spawnMerchant(id++, pos));
  (Object.keys(PEDESTRIAN_DENSITY) as DistrictId[]).forEach((d) => {
    for (let i = 0; i < PEDESTRIAN_DENSITY[d]; i++) out.push(spawnPedestrian(id++, d));
  });
  return out;
}

// ============================================================
// Rendering
// ============================================================

function NPCAvatar({ npc, groupRef }: { npc: NPCState; groupRef: RefCallback<THREE.Group> }) {
  return (
    <group ref={groupRef} position={[npc.x, 0, npc.z]}>
      <mesh position={[0, 0.95, 0]}>
        <capsuleGeometry args={[0.22, 1.0, 4, 8]} />
        <meshStandardMaterial color={npc.color} roughness={0.8} />
      </mesh>
      <mesh position={[0, 1.65, 0]}>
        <sphereGeometry args={[0.13, 8, 8]} />
        <meshStandardMaterial color="#fde68a" roughness={0.6} />
      </mesh>
      <mesh position={[0, 1.71, 0]}>
        <sphereGeometry args={[0.14, 8, 8, 0, Math.PI * 2, 0, Math.PI / 2]} />
        <meshStandardMaterial color="#1c1917" roughness={0.9} />
      </mesh>
      <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, 0.01, 0]}>
        <circleGeometry args={[0.35, 8]} />
        <meshBasicMaterial color="#000000" transparent opacity={0.2} />
      </mesh>
      {npc.kind === 'merchant' && (
        <mesh position={[0, 2.0, 0]}>
          <sphereGeometry args={[0.1, 8, 8]} />
          <meshStandardMaterial color={npc.color} emissive={npc.color} emissiveIntensity={1.2} />
        </mesh>
      )}
    </group>
  );
}

/* eslint-disable react-hooks/immutability */
export function NPCLayer() {
  const [npcs] = useState<NPCState[]>(buildInitialNPCs);
  const groupRefs = useRef<(THREE.Group | null)[]>([]);

  useFrame((_, dt) => {
    const step = Math.min(dt, 0.1);
    for (let i = 0; i < npcs.length; i++) {
      const npc = npcs[i];
      const grp = groupRefs.current[i];
      if (!grp) continue;

      let diff = npc.facing - grp.rotation.y;
      while (diff > Math.PI) diff -= Math.PI * 2;
      while (diff < -Math.PI) diff += Math.PI * 2;
      grp.rotation.y += diff * Math.min(1, dt * 8);
      grp.position.x = npc.x;
      grp.position.z = npc.z;
      const groundY = terrainHeight(npc.x, npc.z);

      if (npc.kind === 'merchant') continue;

      const dx = npc.targetX - npc.x;
      const dz = npc.targetZ - npc.z;
      const dist = Math.sqrt(dx * dx + dz * dz);
      if (dist < 0.5) {
        // Reached target — pick a new sidewalk point
        const [tx, tz] = randomSidewalkInDistrict(npc.district);
        npc.targetX = tx;
        npc.targetZ = tz;
      } else {
        const move = npc.speed * step;
        npc.x += (dx / dist) * move;
        npc.z += (dz / dist) * move;
        npc.facing = Math.atan2(dx, dz);
        grp.position.y = groundY + Math.abs(Math.sin(performance.now() * 0.008 + i)) * 0.06;
      }
    }
  });

  return (
    <>
      {npcs.map((npc, i) => (
        <NPCAvatar
          key={npc.id}
          npc={npc}
          groupRef={(el: THREE.Group | null) => { groupRefs.current[i] = el; }}
        />
      ))}
    </>
  );
}
