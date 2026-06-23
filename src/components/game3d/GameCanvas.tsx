'use client';

import { Canvas, useFrame } from '@react-three/fiber';
import { Suspense, useEffect, useRef } from 'react';
import * as THREE from 'three';
import { GameScene } from './Scene';
import { FollowCamera, PointerLockController } from './FollowCamera';
import { usePlayer } from './playerStore';
import { useVehicle } from './vehicleStore';
import { useGame } from '../../lib/game/store';
import { BUILDINGS, nearestBuilding } from './layout';
import type { SchemeId } from '../../lib/game/types';

// Per-frame game tick: updates player movement AND vehicle movement
function GameTick() {
  const lastTime = useRef<number>(0);
  const tick = usePlayer((s) => s.tick);
  const vehicleTick = useVehicle((s) => s.tick);

  useFrame((state) => {
    const now = state.clock.elapsedTime;
    let dt = now - lastTime.current;
    if (!isFinite(dt) || dt < 0) dt = 0.016;
    dt = Math.min(0.1, dt);
    lastTime.current = now;
    tick(dt);
    vehicleTick(dt);
  });

  return null;
}

// Keyboard handler: E to enter building, F to enter/exit vehicle, WASD/arrows to move/drive, V to toggle camera
function KeyboardController() {
  const setActionPanel = usePlayer((s) => s.setActionPanel);
  const toggleCamera = usePlayer((s) => s.toggleCamera);
  const setFpsInput = usePlayer((s) => s.setFpsInput);
  const enterVehicle = useVehicle((s) => s.enterVehicle);
  const exitVehicle = useVehicle((s) => s.exitVehicle);
  const setVehicleInput = useVehicle((s) => s.setInput);

  // Refs that mirror frequently-changing store values without causing effect re-runs
  const nearbyRef = useRef<SchemeId | null>(null);
  const panelOpenRef = useRef<boolean>(false);
  const cameraModeRef = useRef<'first' | 'third'>('first');
  const inVehicleRef = useRef<number | null>(null);
  const keys = useRef<Record<string, boolean>>({});

  // Keep refs in sync with the stores
  usePlayer((s) => {
    nearbyRef.current = s.nearbyBuildingId;
    panelOpenRef.current = s.actionPanelOpen;
    cameraModeRef.current = s.cameraMode;
    return s.cameraMode;
  });
  useVehicle((s) => {
    inVehicleRef.current = s.inVehicleId;
    return s.inVehicleId;
  });

  // Compute on-foot input (forward/right for walking)
  const computeFootInput = () => {
    const k = keys.current;
    let forward = 0;
    let right = 0;
    if (k['w'] || k['arrowup']) forward += 1;
    if (k['s'] || k['arrowdown']) forward -= 1;
    if (k['a'] || k['arrowleft']) right -= 1;
    if (k['d'] || k['arrowright']) right += 1;
    const len = Math.sqrt(forward * forward + right * right);
    if (len > 1) {
      forward /= len;
      right /= len;
    }
    return { forward, right };
  };

  // Compute vehicle input (throttle/brake/steer for driving)
  // W = throttle forward, S = brake/reverse, A/D = steer left/right, Space = handbrake
  const computeVehicleInput = () => {
    const k = keys.current;
    let throttle = 0;
    let brake = 0;
    let steer = 0;
    if (k['w'] || k['arrowup']) throttle += 1;
    if (k['s'] || k['arrowdown']) throttle -= 1; // reverse
    if (k['a'] || k['arrowleft']) steer -= 1;
    if (k['d'] || k['arrowright']) steer += 1;
    if (k[' ']) brake = 1;  // space = handbrake
    return { throttle, brake, steer };
  };

  // Update whichever input mode is active
  const updateActiveInput = () => {
    if (inVehicleRef.current !== null) {
      setVehicleInput(computeVehicleInput());
    } else {
      setFpsInput(computeFootInput());
    }
  };

  useEffect(() => {
    const handleDown = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement;
      if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA') return;

      // V toggles camera mode
      if (e.key === 'v' || e.key === 'V') {
        toggleCamera();
        setTimeout(() => updateActiveInput(), 0);
        e.preventDefault();
        return;
      }
      // F to enter/exit vehicle
      if (e.key === 'f' || e.key === 'F') {
        if (inVehicleRef.current !== null) {
          exitVehicle();
        } else if (!panelOpenRef.current) {
          enterVehicle();
        }
        e.preventDefault();
        return;
      }
      // E to enter building (only when on foot, not in vehicle)
      if ((e.key === 'e' || e.key === 'E') && nearbyRef.current && !panelOpenRef.current && inVehicleRef.current === null) {
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
      updateActiveInput();
    };
    const handleUp = (e: KeyboardEvent) => {
      keys.current[e.key.toLowerCase()] = false;
      updateActiveInput();
    };
    const handleBlur = () => {
      keys.current = {};
      setFpsInput({ forward: 0, right: 0 });
      setVehicleInput({ throttle: 0, brake: 0, steer: 0 });
    };
    window.addEventListener('keydown', handleDown);
    window.addEventListener('keyup', handleUp);
    window.addEventListener('blur', handleBlur);

    return () => {
      window.removeEventListener('keydown', handleDown);
      window.removeEventListener('keyup', handleUp);
      window.removeEventListener('blur', handleBlur);
    };
  }, [setActionPanel, toggleCamera, setFpsInput, enterVehicle, exitVehicle, setVehicleInput]);

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
