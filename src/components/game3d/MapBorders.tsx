'use client';

import { useMemo } from 'react';
import * as THREE from 'three';
import { terrainHeight } from './terrain';

// ============================================================
// Map Borders — creative natural barriers instead of hard walls
// ============================================================
// North: Mountain range (steep rock walls, unclimbable)
// South: Ocean (water extends to horizon, player pushed back by current)
// East: Highway construction barricade ("ROAD CLOSED")
// West: Military zone fence ("RESTRICTED AREA")
// NW/NE: Dense forest (trees become impassable)

// ---------- Mountains (North) ----------
function MountainRange() {
  const mountains = useMemo(() => {
    const out: { x: number; z: number; height: number; radius: number; rot: number }[] = [];
    // Chain of mountains along the northern border (z = -220 to -260)
    for (let i = -260; i <= 260; i += 30) {
      const x = i + (Math.random() - 0.5) * 20;
      const z = -220 - Math.random() * 40;
      out.push({
        x,
        z,
        height: 35 + Math.random() * 20,
        radius: 25 + Math.random() * 15,
        rot: Math.random() * Math.PI,
      });
    }
    return out;
  }, []);

  return (
    <group>
      {mountains.map((m, i) => {
        const groundY = terrainHeight(m.x, m.z);
        return (
          <mesh
            key={i}
            position={[m.x, groundY + m.height / 2, m.z]}
            rotation={[0, m.rot, 0]}
          >
            <coneGeometry args={[m.radius, m.height, 6]} />
            <meshStandardMaterial color="#5a4a3a" roughness={0.95} flatShading />
          </mesh>
        );
      })}
    </group>
  );
}

// ---------- Dense Forest (NW and NE borders) ----------
function DenseForest() {
  const trees = useMemo(() => {
    const out: { x: number; z: number; scale: number; rot: number }[] = [];
    // NW forest (x: -220 to -270, z: -220 to -50)
    for (let i = 0; i < 120; i++) {
      const x = -220 - Math.random() * 50;
      const z = -220 + Math.random() * 170;
      out.push({ x, z, scale: 0.8 + Math.random() * 0.6, rot: Math.random() * Math.PI * 2 });
    }
    // NE forest (x: 220 to 270, z: -220 to -50)
    for (let i = 0; i < 120; i++) {
      const x = 220 + Math.random() * 50;
      const z = -220 + Math.random() * 170;
      out.push({ x, z, scale: 0.8 + Math.random() * 0.6, rot: Math.random() * Math.PI * 2 });
    }
    return out;
  }, []);

  return (
    <group>
      {trees.map((t, i) => {
        const groundY = terrainHeight(t.x, t.z);
        return (
          <group key={i} position={[t.x, groundY, t.z]} rotation={[0, t.rot, 0]} scale={t.scale}>
            {/* Trunk */}
            <mesh position={[0, 1.5, 0]}>
              <cylinderGeometry args={[0.2, 0.3, 3, 6]} />
              <meshStandardMaterial color="#4a3a1a" roughness={0.9} />
            </mesh>
            {/* Foliage — 2 stacked cones */}
            <mesh position={[0, 3.5, 0]}>
              <coneGeometry args={[1.5, 3, 6]} />
              <meshStandardMaterial color="#2a4a1a" roughness={0.85} flatShading />
            </mesh>
            <mesh position={[0, 5, 0]}>
              <coneGeometry args={[1.0, 2.5, 6]} />
              <meshStandardMaterial color="#2a5a2a" roughness={0.85} flatShading />
            </mesh>
          </group>
        );
      })}
    </group>
  );
}

// ---------- Highway Barricade (East) ----------
function HighwayBarricade() {
  const groundY = terrainHeight(240, 0);
  return (
    <group position={[240, groundY, 0]}>
      {/* Concrete barriers (Jersey barriers) along z-axis */}
      {Array.from({ length: 20 }).map((_, i) => {
        const z = -100 + i * 12;
        return (
          <mesh key={i} position={[0, 0.6, z]}>
            <boxGeometry args={[1.2, 1.2, 8]} />
            <meshStandardMaterial color="#a0a0a0" roughness={0.9} />
          </mesh>
        );
      })}
      {/* "ROAD CLOSED" sign */}
      <mesh position={[0, 3, 0]}>
        <boxGeometry args={[4, 1, 0.1]} />
        <meshStandardMaterial color="#dc2626" emissive="#dc2626" emissiveIntensity={0.3} />
      </mesh>
      {/* Sign posts */}
      <mesh position={[-1.5, 1.5, 0]}>
        <cylinderGeometry args={[0.06, 0.06, 3, 6]} />
        <meshStandardMaterial color="#555" />
      </mesh>
      <mesh position={[1.5, 1.5, 0]}>
        <cylinderGeometry args={[0.06, 0.06, 3, 6]} />
        <meshStandardMaterial color="#555" />
      </mesh>
    </group>
  );
}

// ---------- Military Zone Fence (West) ----------
function MilitaryFence() {
  const groundY = terrainHeight(-240, 0);
  const posts = useMemo(() => {
    return Array.from({ length: 40 }).map((_, i) => -200 + i * 10);
  }, []);

  return (
    <group position={[-240, groundY, 0]}>
      {/* Fence posts */}
      {posts.map((z, i) => (
        <mesh key={i} position={[0, 1.5, z]}>
          <cylinderGeometry args={[0.05, 0.05, 3, 6]} />
          <meshStandardMaterial color="#4a4a3a" roughness={0.9} />
        </mesh>
      ))}
      {/* Chain-link (simplified as thin boxes) */}
      {posts.slice(0, -1).map((z, i) => (
        <mesh key={`link-${i}`} position={[0, 1.5, (z + posts[i + 1]) / 2]}>
          <boxGeometry args={[0.02, 2.5, 10]} />
          <meshStandardMaterial color="#6a6a5a" transparent opacity={0.4} />
        </mesh>
      ))}
      {/* Warning sign */}
      <mesh position={[0.1, 2.5, 0]}>
        <boxGeometry args={[2, 1.5, 0.1]} />
        <meshStandardMaterial color="#facc15" emissive="#facc15" emissiveIntensity={0.2} />
      </mesh>
      {/* Watchtower */}
      <mesh position={[5, 4, 0]}>
        <boxGeometry args={[3, 8, 3]} />
        <meshStandardMaterial color="#4a4a3a" roughness={0.9} />
      </mesh>
      <mesh position={[5, 8.5, 0]}>
        <boxGeometry args={[4, 1, 4]} />
        <meshStandardMaterial color="#5a5a4a" roughness={0.85} />
      </mesh>
    </group>
  );
}

// ---------- Scattered trees in rural area ----------
function RuralTrees() {
  const trees = useMemo(() => {
    const out: { x: number; z: number; scale: number; rot: number }[] = [];
    // Scattered trees in rural zones (r > 150, not in city)
    for (let i = 0; i < 80; i++) {
      const angle = Math.random() * Math.PI * 2;
      const dist = 150 + Math.random() * 70;
      const x = Math.cos(angle) * dist;
      const z = Math.sin(angle) * dist;
      // Skip if in ocean (south, z > 100, r > 180)
      if (z > 100 && dist > 150) continue;
      out.push({ x, z, scale: 0.6 + Math.random() * 0.8, rot: Math.random() * Math.PI * 2 });
    }
    return out;
  }, []);

  return (
    <group>
      {trees.map((t, i) => {
        const groundY = terrainHeight(t.x, t.z);
        if (groundY < 0) return null; // skip underwater
        return (
          <group key={i} position={[t.x, groundY, t.z]} rotation={[0, t.rot, 0]} scale={t.scale}>
            <mesh position={[0, 1.5, 0]}>
              <cylinderGeometry args={[0.2, 0.3, 3, 6]} />
              <meshStandardMaterial color="#4a3a1a" roughness={0.9} />
            </mesh>
            <mesh position={[0, 3.5, 0]}>
              <coneGeometry args={[1.8, 4, 6]} />
              <meshStandardMaterial color="#2a4a1a" roughness={0.85} flatShading />
            </mesh>
          </group>
        );
      })}
    </group>
  );
}

// ---------- Main MapBorders component ----------
export function MapBorders() {
  return (
    <>
      <MountainRange />
      <DenseForest />
      <HighwayBarricade />
      <MilitaryFence />
      <RuralTrees />
    </>
  );
}
