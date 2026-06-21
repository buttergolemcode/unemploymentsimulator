'use client';

import { useRef, useMemo, useState } from 'react';
import { useFrame } from '@react-three/fiber';
import * as THREE from 'three';

// ============================================================
// Weather system
// ============================================================
// Rain rendered as line segments (each drop = a short vertical line) so it
// actually reads as "rain streaks" rather than dots.

interface RainDrop {
  x: number;
  y: number;
  z: number;
  speed: number;
}

const RAIN_COUNT = 1500;
const RAIN_AREA = 50;
const RAIN_HEIGHT = 25;
const DROP_LENGTH = 0.6;

function buildInitialRain(): RainDrop[] {
  const out: RainDrop[] = [];
  for (let i = 0; i < RAIN_COUNT; i++) {
    out.push({
      x: (Math.random() - 0.5) * RAIN_AREA,
      y: Math.random() * RAIN_HEIGHT,
      z: (Math.random() - 0.5) * RAIN_AREA,
      speed: 22 + Math.random() * 12,
    });
  }
  return out;
}

export function Weather() {
  const linesRef = useRef<THREE.LineSegments>(null);
  const [initialRain] = useState<RainDrop[]>(buildInitialRain);
  const rainRef = useRef<RainDrop[]>(initialRain);

  // Build line-segments geometry: each drop = 2 vertices (top, bottom)
  const geometry = useMemo(() => {
    const geo = new THREE.BufferGeometry();
    const positions = new Float32Array(RAIN_COUNT * 6); // 2 verts × 3 coords per drop
    for (let i = 0; i < RAIN_COUNT; i++) {
      const d = initialRain[i];
      // Top vertex
      positions[i * 6] = d.x;
      positions[i * 6 + 1] = d.y + DROP_LENGTH;
      positions[i * 6 + 2] = d.z;
      // Bottom vertex
      positions[i * 6 + 3] = d.x;
      positions[i * 6 + 4] = d.y;
      positions[i * 6 + 5] = d.z;
    }
    geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    return geo;
  }, [initialRain]);

  useFrame((state, dt) => {
    if (!linesRef.current) return;
    const camPos = state.camera.position;
    const rain = rainRef.current;
    const positions = (linesRef.current.geometry.attributes.position as THREE.BufferAttribute).array as Float32Array;
    for (let i = 0; i < RAIN_COUNT; i++) {
      const d = rain[i];
      d.y -= d.speed * dt;
      if (d.y < 0) {
        d.y = RAIN_HEIGHT;
        d.x = camPos.x + (Math.random() - 0.5) * RAIN_AREA;
        d.z = camPos.z + (Math.random() - 0.5) * RAIN_AREA;
      }
      const dx = d.x - camPos.x;
      const dz = d.z - camPos.z;
      if (Math.abs(dx) > RAIN_AREA / 2) d.x = camPos.x - Math.sign(dx) * RAIN_AREA / 2 + (Math.random() - 0.5) * 4;
      if (Math.abs(dz) > RAIN_AREA / 2) d.z = camPos.z - Math.sign(dz) * RAIN_AREA / 2 + (Math.random() - 0.5) * 4;

      // Top vertex
      positions[i * 6] = d.x;
      positions[i * 6 + 1] = d.y + DROP_LENGTH;
      positions[i * 6 + 2] = d.z;
      // Bottom vertex
      positions[i * 6 + 3] = d.x;
      positions[i * 6 + 4] = d.y;
      positions[i * 6 + 5] = d.z;
    }
    (linesRef.current.geometry.attributes.position as THREE.BufferAttribute).needsUpdate = true;
  });

  return (
    <>
      {/* Rain as line segments — vertical streaks */}
      <lineSegments ref={linesRef} geometry={geometry}>
        <lineBasicMaterial
          color="#a8c5e8"
          transparent
          opacity={0.5}
        />
      </lineSegments>

      {/* Volumetric cloud layer — a dark plane above the rain area for atmosphere */}
      <mesh position={[0, 30, 0]} rotation={[Math.PI / 2, 0, 0]}>
        <planeGeometry args={[200, 200]} />
        <meshBasicMaterial color="#0c1322" transparent opacity={0.4} side={THREE.DoubleSide} />
      </mesh>

      {/* Subtle blue overlay light to give "rainy" feel — additive to the day/night lighting. */}
      <ambientLight intensity={0.08} color="#3b4f6e" />
    </>
  );
}
