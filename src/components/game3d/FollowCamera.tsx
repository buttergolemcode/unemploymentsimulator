'use client';

import { useRef } from 'react';
import { useFrame, useThree } from '@react-three/fiber';
import * as THREE from 'three';
import { usePlayer } from './playerStore';
import { useGame } from '../../lib/game/store';
import { getDayPhase, getTimeOfDay } from './dayNight';

// Camera that switches between first-person and third-person based on player.cameraMode.
// First-person: camera at player eye height, looks where yaw/pitch point. Pointer-locked.
// Third-person: camera behind/above player, looking down at them.
export function FollowCamera() {
  const { camera, gl } = useThree();
  const targetVec = useRef(new THREE.Vector3());
  const desiredPos = useRef(new THREE.Vector3());
  const lookDir = useRef(new THREE.Vector3());

  useFrame(() => {
    const s = usePlayer.getState();
    const phase = useGame.getState().phase;
    if (phase !== 'playing') return;

    if (s.cameraMode === 'first') {
      // Eye position
      const eyeY = 1.6;
      desiredPos.current.set(s.x, eyeY, s.z);
      // Look direction from yaw/pitch
      // yaw=0 → looking -Z, pitch=0 → level
      // Forward = (-sin(yaw)*cos(pitch), sin(pitch), -cos(yaw)*cos(pitch))
      const cp = Math.cos(s.pitch);
      lookDir.current.set(
        -Math.sin(s.yaw) * cp,
        Math.sin(s.pitch),
        -Math.cos(s.yaw) * cp,
      );
      targetVec.current.copy(desiredPos.current).add(lookDir.current);

      // Snap (no lerp) for FPS to avoid motion sickness from lag
      camera.position.copy(desiredPos.current);
      camera.lookAt(targetVec.current);
    } else {
      // Third-person: behind player based on yaw
      const distance = 6;
      const height = 4;
      const behindX = Math.sin(s.yaw) * distance;
      const behindZ = Math.cos(s.yaw) * distance;
      desiredPos.current.set(s.x + behindX, height, s.z + behindZ);
      targetVec.current.set(s.x, 1.2, s.z);

      camera.position.lerp(desiredPos.current, 0.12);
      camera.lookAt(targetVec.current);
    }
  });

  // Pointer lock management — request on canvas click when in FPS mode
  const canvas = gl.domElement;
  useRef<() => void>(() => {
    const onClick = () => {
      const s = usePlayer.getState();
      if (s.cameraMode === 'first' && !s.actionPanelOpen && !s.pointerLocked) {
        canvas.requestPointerLock?.();
      }
    };
    const onPointerLockChange = () => {
      const locked = document.pointerLockElement === canvas;
      usePlayer.getState().setPointerLocked(locked);
    };
    const onMouseMove = (e: MouseEvent) => {
      const s = usePlayer.getState();
      if (s.pointerLocked && s.cameraMode === 'first') {
        s.applyMouseDelta(e.movementX, e.movementY);
      }
    };
    canvas.addEventListener('click', onClick);
    document.addEventListener('pointerlockchange', onPointerLockChange);
    document.addEventListener('mousemove', onMouseMove);
    return () => {
      canvas.removeEventListener('click', onClick);
      document.removeEventListener('pointerlockchange', onPointerLockChange);
      document.removeEventListener('mousemove', onMouseMove);
    };
  });

  // We need the effect to actually run — useRef only stores it. Use useEffect pattern:
  // (Re-doing this properly below via useFrame registering once is hard, so we use a separate effect component)
  return null;
}

// Separate component to register pointer-lock event listeners (so they're not re-registered every frame).
import { useEffect } from 'react';
export function PointerLockController() {
  const { gl } = useThree();
  const canvas = gl.domElement;

  useEffect(() => {
    const onClick = () => {
      const s = usePlayer.getState();
      const phase = useGame.getState().phase;
      if (
        phase === 'playing' &&
        s.cameraMode === 'first' &&
        !s.actionPanelOpen &&
        !s.pointerLocked
      ) {
        canvas.requestPointerLock?.();
      }
    };
    const onPointerLockChange = () => {
      const locked = document.pointerLockElement === canvas;
      usePlayer.getState().setPointerLocked(locked);
    };
    const onMouseMove = (e: MouseEvent) => {
      const s = usePlayer.getState();
      if (s.pointerLocked && s.cameraMode === 'first') {
        s.applyMouseDelta(e.movementX, e.movementY);
      }
    };

    canvas.addEventListener('click', onClick);
    document.addEventListener('pointerlockchange', onPointerLockChange);
    document.addEventListener('mousemove', onMouseMove);
    return () => {
      canvas.removeEventListener('click', onClick);
      document.removeEventListener('pointerlockchange', onPointerLockChange);
      document.removeEventListener('mousemove', onMouseMove);
      // Release pointer lock on unmount
      if (document.pointerLockElement === canvas) {
        document.exitPointerLock?.();
      }
    };
  }, [canvas]);

  return null;
}

// Day/night lighting controller. Reads game day + a continuous time-of-day value,
// adjusts sun position, intensity, sky color.
export function DayNightLighting() {
  const sunRef = useRef<THREE.DirectionalLight>(null);
  const ambientRef = useRef<THREE.AmbientLight>(null);
  const hemiRef = useRef<THREE.HemisphereLight>(null);
  const bgRef = useRef<THREE.Color>(null);
  const fogRef = useRef<THREE.Fog>(null);
  const skyColorRef = useRef<THREE.Color>(new THREE.Color('#1e3a8a'));

  useFrame((state) => {
    const day = useGame.getState().day;
    const t = getTimeOfDay(state.clock.elapsedTime, day);
    const phase = getDayPhase(t);

    // Sun position: orbits around the scene
    const sunAngle = (t - 0.25) * Math.PI * 2;
    const sunX = Math.cos(sunAngle) * 30;
    const sunY = Math.sin(sunAngle) * 30;
    const sunZ = 8;

    if (sunRef.current) {
      sunRef.current.position.set(sunX, Math.max(sunY, -5), sunZ);
      sunRef.current.target.position.set(0, 0, 0);
      sunRef.current.target.updateMatrixWorld();
      const intensity = phase === 'night' ? 0.05 : phase === 'dusk' || phase === 'dawn' ? 0.4 : 1.4;
      sunRef.current.intensity = intensity;
      const color =
        phase === 'dawn'
          ? '#fb923c'
          : phase === 'dusk'
            ? '#dc2626'
            : phase === 'night'
              ? '#4f6dfa'
              : '#fff8e7';
      sunRef.current.color.set(color);
    }

    if (ambientRef.current) {
      const baseIntensity =
        phase === 'night' ? 0.18 : phase === 'dawn' || phase === 'dusk' ? 0.35 : 0.55;
      ambientRef.current.intensity = baseIntensity;
      const ambientColor =
        phase === 'night' ? '#1e293b' : phase === 'dawn' || phase === 'dusk' ? '#9a3412' : '#cbd5e1';
      ambientRef.current.color.set(ambientColor);
    }

    if (hemiRef.current) {
      hemiRef.current.intensity =
        phase === 'night' ? 0.15 : phase === 'dawn' || phase === 'dusk' ? 0.4 : 0.6;
    }

    // Target sky color
    const targetSky =
      phase === 'night'
        ? '#050816'
        : phase === 'dawn'
          ? '#7c2d12'
          : phase === 'dusk'
            ? '#450a0a'
            : '#1e3a8a';
    skyColorRef.current.lerp(new THREE.Color(targetSky), 0.02);

    // Apply to bg/fog refs we created as JSX
    if (bgRef.current) {
      bgRef.current.copy(skyColorRef.current);
    }
    if (fogRef.current) {
      fogRef.current.color.copy(skyColorRef.current);
    }
  });

  return (
    <>
      <color ref={bgRef} attach="background" args={['#1e3a8a']} />
      <fog ref={fogRef} attach="fog" args={['#1e3a8a', 30, 90]} />
      <ambientLight ref={ambientRef} intensity={0.4} />
      <hemisphereLight ref={hemiRef} args={['#3b82f6', '#1a1a1a', 0.3]} />
      <directionalLight
        ref={sunRef}
        position={[20, 30, 8]}
        intensity={1.4}
        castShadow
        shadow-mapSize={[2048, 2048]}
        shadow-camera-far={80}
        shadow-camera-left={-40}
        shadow-camera-right={40}
        shadow-camera-top={40}
        shadow-camera-bottom={-40}
      />
    </>
  );
}
