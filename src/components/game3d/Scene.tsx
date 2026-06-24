'use client';

import { useRef, useMemo } from 'react';
import { useFrame, ThreeEvent } from '@react-three/fiber';
import { Text, RoundedBox, Cylinder } from '@react-three/drei';
import * as THREE from 'three';
import { BUILDINGS, INTERACT_DISTANCE, FILLER_BUILDINGS, STREETS, DISTRICTS, districtAt, WORLD_RADIUS } from './layout';
import { usePlayer } from './playerStore';
import { DayNightLighting } from './FollowCamera';
import { NPCLayer } from './NPCs';
import { Weather } from './Weather';
import { VehicleLayer } from './Vehicles';
import type { BuildingPos, FillerBuilding, StreetSegment } from './layout';
import type { SchemeId } from '../../lib/game/types';

// ---------- Building ----------
function Building({ b }: { b: BuildingPos }) {
  const nearbyId = usePlayer((s) => s.nearbyBuildingId);
  const isNearby = nearbyId === b.id;
  const ref = useRef<THREE.Group>(null);

  useFrame((state) => {
    if (!ref.current) return;
    // Subtle hover/bob
    const t = state.clock.elapsedTime;
    ref.current.position.y = isNearby ? Math.sin(t * 3) * 0.08 : 0;
  });

  return (
    <group position={[b.x, 0, b.z]}>
      <group ref={ref}>
        {/* Main body */}
        <RoundedBox
          args={[b.width, b.height, b.depth]}
          radius={0.15}
          smoothness={4}
          position={[0, b.height / 2, 0]}
          castShadow
          receiveShadow
        >
          <meshStandardMaterial
            color={b.color}
            emissive={isNearby ? b.accentColor : '#000000'}
            emissiveIntensity={isNearby ? 0.4 : 0}
            roughness={0.6}
            metalness={0.1}
          />
        </RoundedBox>

        {/* Roof accent */}
        <RoundedBox
          args={[b.width * 0.95, 0.3, b.depth * 0.95]}
          radius={0.08}
          smoothness={3}
          position={[0, b.height + 0.15, 0]}
        >
          <meshStandardMaterial color={b.accentColor} roughness={0.5} />
        </RoundedBox>

        {/* Door */}
        <mesh position={[0, 0.75, b.depth / 2 + 0.01]}>
          <planeGeometry args={[1, 1.5]} />
          <meshStandardMaterial color="#1f2937" roughness={0.8} />
        </mesh>

        {/* Windows — simple emissive squares */}
        {Array.from({ length: Math.max(1, Math.floor(b.height / 2)) }).map((_, row) =>
          Array.from({ length: 2 }).map((_, col) => (
            <mesh
              key={`w-${row}-${col}`}
              position={[
                (col - 0.5) * (b.width * 0.5),
                1.5 + row * 1.5,
                b.depth / 2 + 0.01,
              ]}
            >
              <planeGeometry args={[0.6, 0.6]} />
              <meshStandardMaterial
                color="#fde68a"
                emissive="#fde68a"
                emissiveIntensity={0.6}
                transparent
                opacity={0.9}
              />
            </mesh>
          )),
        )}

        {/* Emoji label floating above */}
        <Text
          position={[0, b.height + 1.2, 0]}
          fontSize={1.1}
          color="white"
          anchorX="center"
          anchorY="middle"
          outlineWidth={0.04}
          outlineColor="#000000"
        >
          {b.emoji}
        </Text>

        {/* Name label */}
        <Text
          position={[0, b.height + 0.5, 0]}
          fontSize={0.32}
          color="white"
          anchorX="center"
          anchorY="middle"
          outlineWidth={0.02}
          outlineColor="#000000"
        >
          {b.name}
        </Text>

        {/* "Press E" prompt when nearby */}
        {isNearby && (
          <Text
            position={[0, b.height + 1.9, 0]}
            fontSize={0.4}
            color="#fde047"
            anchorX="center"
            anchorY="middle"
            outlineWidth={0.03}
            outlineColor="#000000"
          >
            ▸ Press E to enter
          </Text>
        )}
      </group>

      {/* Glow ring on ground when nearby */}
      {isNearby && (
        <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, 0.02, 0]}>
          <ringGeometry args={[b.width * 0.7, b.width * 0.85, 32]} />
          <meshBasicMaterial color={b.accentColor} transparent opacity={0.7} />
        </mesh>
      )}
    </group>
  );
}

// ---------- Player Avatar ----------
function PlayerAvatar() {
  const x = usePlayer((s) => s.x);
  const z = usePlayer((s) => s.z);
  const walking = usePlayer((s) => s.walking);
  const ref = useRef<THREE.Group>(null);
  const facingRef = useRef<number>(0);

  // Track previous position to compute facing direction
  const lastPos = useRef<{ x: number; z: number }>({ x, z });

  useFrame((state, dt) => {
    if (!ref.current) return;
    const t = state.clock.elapsedTime;

    // Compute facing
    const dx = x - lastPos.current.x;
    const dz = z - lastPos.current.z;
    if (Math.abs(dx) > 0.001 || Math.abs(dz) > 0.001) {
      const targetAngle = Math.atan2(dx, dz);
      // Smoothly rotate toward target
      let diff = targetAngle - facingRef.current;
      while (diff > Math.PI) diff -= Math.PI * 2;
      while (diff < -Math.PI) diff += Math.PI * 2;
      facingRef.current += diff * Math.min(1, dt * 10);
    }
    ref.current.rotation.y = facingRef.current;
    lastPos.current = { x, z };

    // Bob up and down while walking
    if (walking) {
      ref.current.position.y = Math.abs(Math.sin(t * 8)) * 0.15;
    } else {
      ref.current.position.y = Math.sin(t * 2) * 0.04;
    }
  });

  return (
    <group ref={ref} position={[x, 0, z]}>
      {/* Body */}
      <Cylinder args={[0.35, 0.45, 1.1, 16]} position={[0, 0.55, 0]} castShadow>
        <meshStandardMaterial color="#1e293b" roughness={0.7} />
      </Cylinder>
      {/* Head */}
      <mesh position={[0, 1.4, 0]} castShadow>
        <sphereGeometry args={[0.32, 16, 16]} />
        <meshStandardMaterial color="#fde68a" roughness={0.5} />
      </mesh>
      {/* Beanie */}
      <mesh position={[0, 1.55, 0]} castShadow>
        <sphereGeometry args={[0.34, 16, 16, 0, Math.PI * 2, 0, Math.PI / 2]} />
        <meshStandardMaterial color="#dc2626" roughness={0.6} />
      </mesh>
      {/* Beard */}
      <mesh position={[0, 1.2, 0.2]} castShadow>
        <sphereGeometry args={[0.22, 12, 12]} />
        <meshStandardMaterial color="#422006" roughness={0.9} />
      </mesh>
      {/* Arms */}
      <Cylinder args={[0.1, 0.1, 0.8, 8]} position={[-0.45, 0.6, 0]} rotation={[0, 0, 0.3]} castShadow>
        <meshStandardMaterial color="#1e293b" roughness={0.7} />
      </Cylinder>
      <Cylinder args={[0.1, 0.1, 0.8, 8]} position={[0.45, 0.6, 0]} rotation={[0, 0, -0.3]} castShadow>
        <meshStandardMaterial color="#1e293b" roughness={0.7} />
      </Cylinder>
      {/* Shadow blob (fake) */}
      <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, 0.01, 0]}>
        <circleGeometry args={[0.5, 16]} />
        <meshBasicMaterial color="#000000" transparent opacity={0.25} />
      </mesh>
    </group>
  );
}

// ---------- Ground ----------
function Ground() {
  const moveTo = usePlayer((s) => s.moveTo);
  const actionPanelOpen = usePlayer((s) => s.actionPanelOpen);

  const handleClick = (e: ThreeEvent<MouseEvent>) => {
    if (actionPanelOpen) return;
    // In first-person mode, clicks go to the canvas for pointer-lock, not click-to-move
    const cameraMode = usePlayer.getState().cameraMode;
    if (cameraMode === 'first') return;
    e.stopPropagation();
    const point = e.point;
    // Clamp to world radius
    const r = Math.sqrt(point.x * point.x + point.z * point.z);
    const max = WORLD_RADIUS - 5;
    if (r > max) {
      const scale = max / r;
      moveTo(point.x * scale, point.z * scale);
    } else {
      moveTo(point.x, point.z);
    }
  };

  // Grid pattern via shader-ish material — use a simple plane with grid texture
  const gridTexture = useMemo(() => {
    const size = 512;
    const canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext('2d')!;
    ctx.fillStyle = '#1a1a1a';
    ctx.fillRect(0, 0, size, size);
    // Grid lines
    ctx.strokeStyle = '#2a2a2a';
    ctx.lineWidth = 2;
    const step = size / 16;
    for (let i = 0; i <= 16; i++) {
      ctx.beginPath();
      ctx.moveTo(i * step, 0);
      ctx.lineTo(i * step, size);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(0, i * step);
      ctx.lineTo(size, i * step);
      ctx.stroke();
    }
    // Asphalt texture: random dots
    for (let i = 0; i < 2000; i++) {
      const x = Math.random() * size;
      const y = Math.random() * size;
      const v = Math.random() * 60 + 20;
      ctx.fillStyle = `rgb(${v},${v},${v})`;
      ctx.fillRect(x, y, 1, 1);
    }
    const tex = new THREE.CanvasTexture(canvas);
    tex.wrapS = THREE.RepeatWrapping;
    tex.wrapT = THREE.RepeatWrapping;
    tex.repeat.set(24, 24);
    return tex;
  }, []);

  return (
    <mesh
      rotation={[-Math.PI / 2, 0, 0]}
      position={[0, 0, 0]}
      onClick={handleClick}
      receiveShadow
    >
      <circleGeometry args={[WORLD_RADIUS + 5, 96]} />
      <meshStandardMaterial map={gridTexture} roughness={0.95} />
    </mesh>
  );
}

// ---------- Click target marker ----------
function ClickMarker({ x, z }: { x: number; z: number }) {
  const ref = useRef<THREE.Mesh>(null);
  useFrame((state) => {
    if (!ref.current) return;
    const t = state.clock.elapsedTime;
    const s = 1 + Math.sin(t * 6) * 0.2;
    ref.current.scale.set(s, s, s);
    (ref.current.material as THREE.MeshBasicMaterial).opacity = 0.6 + Math.sin(t * 6) * 0.2;
  });
  return (
    <mesh ref={ref} rotation={[-Math.PI / 2, 0, 0]} position={[x, 0.05, z]}>
      <ringGeometry args={[0.3, 0.5, 24]} />
      <meshBasicMaterial color="#fde047" transparent opacity={0.7} />
    </mesh>
  );
}

function TargetMarkerLayer() {
  const targetX = usePlayer((s) => s.targetX);
  const targetZ = usePlayer((s) => s.targetZ);
  const walking = usePlayer((s) => s.walking);
  if (!walking) return null;
  return <ClickMarker x={targetX} z={targetZ} />;
}

// ---------- Decorative street lamps ----------
function StreetLamp({ x, z }: { x: number; z: number }) {
  return (
    <group position={[x, 0, z]}>
      <Cylinder args={[0.06, 0.08, 3.5, 8]} position={[0, 1.75, 0]} castShadow>
        <meshStandardMaterial color="#1f2937" />
      </Cylinder>
      <mesh position={[0, 3.5, 0]}>
        <sphereGeometry args={[0.2, 12, 12]} />
        <meshStandardMaterial
          color="#fef3c7"
          emissive="#fef3c7"
          emissiveIntensity={1.5}
        />
      </mesh>
      <pointLight position={[0, 3.5, 0]} intensity={5} distance={8} color="#fef3c7" />
    </group>
  );
}

// ---------- Filler (background) buildings ----------
function FillerBuildingMesh({ b }: { b: FillerBuilding }) {
  return (
    <group position={[b.x, 0, b.z]}>
      <RoundedBox
        args={[b.width, b.height, b.depth]}
        radius={0.1}
        smoothness={2}
        position={[0, b.height / 2, 0]}
        castShadow
        receiveShadow
      >
        <meshStandardMaterial color={b.color} roughness={0.75} metalness={0.1} />
      </RoundedBox>

      {/* Windows — emissive grid, only if building has them */}
      {b.hasWindows && (
        <BuildingWindows
          width={b.width}
          height={b.height}
          depth={b.depth}
          litChance={b.windowLitChance}
          seed={Math.abs(b.x * 13 + b.z * 7)}
        />
      )}
    </group>
  );
}

// Shared window component for both scheme and filler buildings.
function BuildingWindows({
  width,
  height,
  depth,
  litChance = 0.4,
  seed = 1,
}: {
  width: number;
  height: number;
  depth: number;
  litChance?: number;
  seed?: number;
}) {
  const rows = Math.max(1, Math.floor(height / 1.8));
  const cols = Math.max(1, Math.floor(width / 1.2));
  const windows = [];
  for (let row = 0; row < rows; row++) {
    for (let col = 0; col < cols; col++) {
      // Pseudo-random based on seed + row/col
      const r = ((seed + row * 31 + col * 17) % 100) / 100;
      const lit = r < litChance;
      const wx = (col - (cols - 1) / 2) * 1.2;
      const wy = 1.2 + row * 1.8;
      // Front face
      windows.push(
        <mesh key={`f-${row}-${col}`} position={[wx, wy, depth / 2 + 0.01]}>
          <planeGeometry args={[0.55, 0.7]} />
          <meshStandardMaterial
            color={lit ? '#fde68a' : '#1f2937'}
            emissive={lit ? '#fde68a' : '#000000'}
            emissiveIntensity={lit ? 0.9 : 0}
            transparent
            opacity={0.95}
          />
        </mesh>,
      );
      // Back face (mirrored)
      windows.push(
        <mesh key={`b-${row}-${col}`} position={[wx, wy, -depth / 2 - 0.01]} rotation={[0, Math.PI, 0]}>
          <planeGeometry args={[0.55, 0.7]} />
          <meshStandardMaterial
            color={lit ? '#fde68a' : '#1f2937'}
            emissive={lit ? '#fde68a' : '#000000'}
            emissiveIntensity={lit ? 0.9 : 0}
            transparent
            opacity={0.95}
          />
        </mesh>,
      );
    }
  }
  return <>{windows}</>;
}

// ---------- Street segments ----------
function Street({ s }: { s: StreetSegment }) {
  return (
    <mesh
      rotation={[-Math.PI / 2, 0, 0]}
      position={[s.x, 0.02, s.z]}
      receiveShadow
    >
      <planeGeometry args={[s.width, s.depth]} />
      <meshStandardMaterial color="#18181b" roughness={0.95} />
    </mesh>
  );
}

// Lane markings — dashed yellow line down the middle of each street
function StreetMarkings({ s }: { s: StreetSegment }) {
  const dashes: { x: number; z: number }[] = [];
  const length = s.horizontal ? s.width : s.depth;
  const count = Math.floor(length / 2.5);
  for (let i = 0; i < count; i++) {
    const offset = (i - (count - 1) / 2) * 2.5;
    dashes.push(
      s.horizontal ? { x: s.x + offset, z: s.z } : { x: s.x, z: s.z + offset },
    );
  }
  return (
    <>
      {dashes.map((d, i) => (
        <mesh key={i} rotation={[-Math.PI / 2, 0, 0]} position={[d.x, 0.04, d.z]}>
          <planeGeometry args={[s.horizontal ? 1.2 : 0.15, s.horizontal ? 0.15 : 1.2]} />
          <meshBasicMaterial color="#fbbf24" />
        </mesh>
      ))}
    </>
  );
}

// ---------- Main scene ----------
export function GameScene() {
  const cameraMode = usePlayer((s) => s.cameraMode);
  return (
    <>
      {/* Lighting + sky/fog — DayNightLighting controls all of these */}
      <DayNightLighting />

      {/* Ground — larger to fit open world */}
      <Ground />

      {/* Streets */}
      {STREETS.map((s, i) => (
        <group key={`street-${i}`}>
          <Street s={s} />
          <StreetMarkings s={s} />
        </group>
      ))}

      {/* District-specific ground tints (subtle colored planes inside each district) */}
      <DistrictGroundTints />

      {/* Scheme buildings (interactive) */}
      {BUILDINGS.map((b) => (
        <Building key={b.id} b={b} />
      ))}

      {/* Filler (background) city buildings */}
      {FILLER_BUILDINGS.map((b, i) => (
        <FillerBuildingMesh key={`fill-${i}`} b={b} />
      ))}

      {/* Street lamps around plaza */}
      <StreetLamp x={-6} z={-4} />
      <StreetLamp x={6} z={-4} />
      <StreetLamp x={-6} z={6} />
      <StreetLamp x={6} z={6} />
      <StreetLamp x={-20} z={-20} />
      <StreetLamp x={20} z={-20} />
      <StreetLamp x={-20} z={20} />
      <StreetLamp x={20} z={20} />
      {/* Extra lamps per district for atmosphere */}
      <StreetLamp x={-30} z={-40} />
      <StreetLamp x={-45} z={-15} />
      <StreetLamp x={30} z={-40} />
      <StreetLamp x={45} z={-15} />
      <StreetLamp x={-30} z={40} />
      <StreetLamp x={-45} z={15} />
      <StreetLamp x={30} z={40} />
      <StreetLamp x={45} z={15} />

      {/* NPCs — pedestrians + merchants */}
      <NPCLayer />

      {/* Parked vehicles (drivable) */}
      <VehicleLayer />

      {/* Weather (rain + fog) */}
      <Weather />

      {/* Player avatar — visible only in third-person mode */}
      {cameraMode === 'third' && <PlayerAvatar />}

      {/* Target marker (third-person only) */}
      {cameraMode === 'third' && <TargetMarkerLayer />}
    </>
  );
}

// Subtle district ground tints — colored planes for each city quadrant + suburbs ring.
function DistrictGroundTints() {
  const CITY = 60;
  const SUBURB = WORLD_RADIUS;
  const quads = [
    { color: DISTRICTS.downtown.groundColor, x: -CITY / 2, z: -CITY / 2, w: CITY, h: CITY },
    { color: DISTRICTS.harbor.groundColor, x: CITY / 2, z: -CITY / 2, w: CITY, h: CITY },
    { color: DISTRICTS.slums.groundColor, x: -CITY / 2, z: CITY / 2, w: CITY, h: CITY },
    { color: DISTRICTS.industrial.groundColor, x: CITY / 2, z: CITY / 2, w: CITY, h: CITY },
  ];
  return (
    <>
      {quads.map((q, i) => (
        <mesh key={i} rotation={[-Math.PI / 2, 0, 0]} position={[q.x, 0.015, q.z]} receiveShadow>
          <planeGeometry args={[q.w, q.h]} />
          <meshStandardMaterial color={q.color} roughness={1} metalness={0} transparent opacity={0.5} />
        </mesh>
      ))}
      {/* Suburbs ring — a large plane with a hole (visual approximation) */}
      <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, 0.012, 0]} receiveShadow>
        <ringGeometry args={[CITY * 0.85, SUBURB, 64]} />
        <meshStandardMaterial color={DISTRICTS.suburbs.groundColor} roughness={1} metalness={0} transparent opacity={0.45} />
      </mesh>
    </>
  );
}

// Re-export for use elsewhere
export { BUILDINGS, INTERACT_DISTANCE, districtAt };
export type { BuildingPos };
