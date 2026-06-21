'use client';

import { Canvas, useFrame } from '@react-three/fiber';
import { Suspense, useEffect, useRef } from 'react';
import * as THREE from 'three';
import { GameScene } from './Scene';
import { FollowCamera } from './FollowCamera';
import { usePlayer } from './playerStore';
import { useGame } from '../../lib/game/store';
import { BUILDINGS, nearestBuilding } from './layout';
import type { SchemeId } from '../../lib/game/types';

// Per-frame game tick: updates player movement and triggers nearby-building interactions
function GameTick() {
  const lastTime = useRef<number>(0);
  const tick = usePlayer((s) => s.tick);

  useFrame((state) => {
    const now = state.clock.elapsedTime;
    const dt = Math.min(0.1, now - lastTime.current);
    lastTime.current = now;
    tick(dt);
  });

  return null;
}

// Keyboard handler: E to enter nearby building, WASD/arrows to move
function KeyboardController() {
  const moveTo = usePlayer((s) => s.moveTo);
  const setActionPanel = usePlayer((s) => s.setActionPanel);

  // Use refs so we don't tear down/recreate the listeners every time nearbyBuildingId changes
  const nearbyRef = useRef<SchemeId | null>(null);
  const panelOpenRef = useRef<boolean>(false);
  const keys = useRef<Record<string, boolean>>({});
  const lastMoveUpdate = useRef<number>(0);

  // Keep refs in sync with the store (subscribe via selectors)
  usePlayer((s) => {
    if (s.nearbyBuildingId !== nearbyRef.current) nearbyRef.current = s.nearbyBuildingId;
    if (s.actionPanelOpen !== panelOpenRef.current) panelOpenRef.current = s.actionPanelOpen;
    return s.nearbyBuildingId; // only re-subscribe on this value changing
  });

  useEffect(() => {
    const handleDown = (e: KeyboardEvent) => {
      // Ignore when typing in inputs
      const target = e.target as HTMLElement;
      if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA') return;

      // E to enter building
      if ((e.key === 'e' || e.key === 'E') && nearbyRef.current && !panelOpenRef.current) {
        setActionPanel(true);
        e.preventDefault();
        return;
      }
      // Esc to close action panel
      if (e.key === 'Escape' && panelOpenRef.current) {
        setActionPanel(false);
        return;
      }

      keys.current[e.key.toLowerCase()] = true;
    };
    const handleUp = (e: KeyboardEvent) => {
      keys.current[e.key.toLowerCase()] = false;
    };
    window.addEventListener('keydown', handleDown);
    window.addEventListener('keyup', handleUp);

    // Movement loop using requestAnimationFrame
    let raf: number;
    const moveLoop = () => {
      const now = performance.now();
      if (now - lastMoveUpdate.current > 30 && !panelOpenRef.current) {
        const k = keys.current;
        let dx = 0;
        let dz = 0;
        if (k['w'] || k['arrowup']) dz -= 1;
        if (k['s'] || k['arrowdown']) dz += 1;
        if (k['a'] || k['arrowleft']) dx -= 1;
        if (k['d'] || k['arrowright']) dx += 1;
        if (dx !== 0 || dz !== 0) {
          const s = usePlayer.getState();
          const len = Math.sqrt(dx * dx + dz * dz);
          const nx = s.x + (dx / len) * 1.2;
          const nz = s.z + (dz / len) * 1.2;
          // Clamp to world radius
          const r = Math.sqrt(nx * nx + nz * nz);
          const max = 27;
          if (r <= max) {
            moveTo(nx, nz);
          }
          lastMoveUpdate.current = now;
        }
      }
      raf = requestAnimationFrame(moveLoop);
    };
    raf = requestAnimationFrame(moveLoop);

    return () => {
      window.removeEventListener('keydown', handleDown);
      window.removeEventListener('keyup', handleUp);
      cancelAnimationFrame(raf);
    };
  }, [moveTo, setActionPanel]);

  return null;
}

// Click-to-building shortcut: click a building mesh to walk to it
export function BuildingClickHandler({ onBuildingClick }: { onBuildingClick: (id: SchemeId) => void }) {
  // We expose this via a global event listener
  useEffect(() => {
    const handler = (e: Event) => {
      const id = (e as CustomEvent<SchemeId>).detail;
      onBuildingClick(id);
    };
    window.addEventListener('enter-building', handler as EventListener);
    return () => window.removeEventListener('enter-building', handler as EventListener);
  }, [onBuildingClick]);
  return null;
}

export function GameCanvas() {
  const setActionPanel = usePlayer((s) => s.setActionPanel);
  const phase = useGame((s) => s.phase);

  return (
    <div
      className="absolute inset-0 w-full h-full"
      // Make sure clicks on the canvas area focus the window so WASD works immediately
      onPointerDown={(e) => {
        // Only refocus if the click was on the canvas itself
        if (e.target instanceof HTMLCanvasElement) {
          window.focus();
        }
      }}
    >
      <Canvas
        shadows
        camera={{ position: [0, 14, 14], fov: 50, near: 0.1, far: 200 }}
        gl={{ antialias: true, powerPreference: 'high-performance', preserveDrawingBuffer: true }}
        onCreated={({ gl }) => {
          gl.setClearColor('#0a0e1a');
          gl.toneMapping = THREE.ACESFilmicToneMapping;
          gl.toneMappingExposure = 1.1;
        }}
      >
        <Suspense fallback={null}>
          <GameScene />
          <FollowCamera />
          <GameTick />
        </Suspense>
      </Canvas>

      {phase === 'playing' && <KeyboardController />}
    </div>
  );
}

// Helper: walk to a specific building (used by HUD buttons)
export function walkToBuilding(id: SchemeId) {
  const b = BUILDINGS.find((x) => x.id === id);
  if (!b) return;
  // Walk to a point just in front of the building door
  const dx = -b.x;
  const dz = -b.z;
  const len = Math.sqrt(dx * dx + dz * dz);
  const offset = Math.max(b.width, b.depth) / 2 + 2;
  const targetX = b.x + (dx / len) * offset;
  const targetZ = b.z + (dz / len) * offset;
  usePlayer.getState().moveTo(targetX, targetZ);
}

// Helper: check if a building is the nearest to the player
export function isPlayerNear(id: SchemeId): boolean {
  const s = usePlayer.getState();
  const near = nearestBuilding(s.x, s.z);
  return near?.building.id === id && near.distance < 5.5;
}

// Re-export for convenience
export { usePlayer };
