'use client';

import { Canvas, useFrame } from '@react-three/fiber';
import { Suspense, useEffect, useRef } from 'react';
import * as THREE from 'three';
import { GameScene } from './Scene';
import { FollowCamera, PointerLockController } from './FollowCamera';
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

// Keyboard handler: E to enter nearby building, WASD/arrows to move, V to toggle camera
// Both first-person AND third-person use the SAME yaw-relative movement logic.
// This eliminates the "inverted / random WASD" bug when switching camera modes.
function KeyboardController() {
  const setActionPanel = usePlayer((s) => s.setActionPanel);
  const toggleCamera = usePlayer((s) => s.toggleCamera);
  const setFpsInput = usePlayer((s) => s.setFpsInput);

  // Refs that mirror frequently-changing store values without causing effect re-runs
  const nearbyRef = useRef<SchemeId | null>(null);
  const panelOpenRef = useRef<boolean>(false);
  const cameraModeRef = useRef<'first' | 'third'>('first');
  const keys = useRef<Record<string, boolean>>({});

  // Keep refs in sync with the store (subscribe via selector that returns cameraMode so we re-run on changes)
  usePlayer((s) => {
    nearbyRef.current = s.nearbyBuildingId;
    panelOpenRef.current = s.actionPanelOpen;
    cameraModeRef.current = s.cameraMode;
    return s.cameraMode;
  });

  // Helper: compute normalized {forward, right} input from currently-pressed keys.
  // W/Up = forward (+1), S/Down = backward (-1), A/Left = left (-1), D/Right = right (+1).
  const computeInput = () => {
    const k = keys.current;
    let forward = 0;
    let right = 0;
    if (k['w'] || k['arrowup']) forward += 1;
    if (k['s'] || k['arrowdown']) forward -= 1;
    if (k['a'] || k['arrowleft']) right -= 1;
    if (k['d'] || k['arrowright']) right += 1;
    // Clamp magnitude so diagonal isn't faster
    const len = Math.sqrt(forward * forward + right * right);
    if (len > 1) {
      forward /= len;
      right /= len;
    }
    return { forward, right };
  };

  useEffect(() => {
    const handleDown = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement;
      if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA') return;

      // V toggles camera mode — and we re-sync the input so movement continues smoothly
      if (e.key === 'v' || e.key === 'V') {
        toggleCamera();
        // After toggle, recompute FPS input so movement keeps flowing in the new mode
        setTimeout(() => setFpsInput(computeInput()), 0);
        e.preventDefault();
        return;
      }
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
      // Always update FPS input (used by BOTH camera modes for movement)
      setFpsInput(computeInput());
    };
    const handleUp = (e: KeyboardEvent) => {
      keys.current[e.key.toLowerCase()] = false;
      setFpsInput(computeInput());
    };
    const handleBlur = () => {
      // Clear all keys when window loses focus (prevents "stuck key" bugs)
      keys.current = {};
      setFpsInput({ forward: 0, right: 0 });
    };
    window.addEventListener('keydown', handleDown);
    window.addEventListener('keyup', handleUp);
    window.addEventListener('blur', handleBlur);

    return () => {
      window.removeEventListener('keydown', handleDown);
      window.removeEventListener('keyup', handleUp);
      window.removeEventListener('blur', handleBlur);
    };
  }, [setActionPanel, toggleCamera, setFpsInput]);

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
        camera={{ position: [0, 1.6, 4], fov: 70, near: 0.05, far: 250 }}
        gl={{ antialias: true, powerPreference: 'high-performance', preserveDrawingBuffer: true }}
        onCreated={({ gl }) => {
          gl.setClearColor('#1e3a8a');
          gl.toneMapping = THREE.ACESFilmicToneMapping;
          gl.toneMappingExposure = 1.1;
        }}
      >
        <Suspense fallback={null}>
          <GameScene />
          <FollowCamera />
          <PointerLockController />
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
