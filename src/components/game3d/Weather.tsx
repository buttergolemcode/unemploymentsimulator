'use client';

import { useRef, useMemo, useState } from 'react';
import { useFrame } from '@react-three/fiber';
import * as THREE from 'three';

// ============================================================
// Weather system
// ============================================================
// Rain rendered as line segments (vertical streaks).
// Rain is NOT permanent — it cycles through phases:
//   1. Clear (no rain) — random duration 20-60s
//   2. Fading in — 4s transition where rain opacity ramps up
//   3. Raining — random duration 30-90s
//   4. Fading out — 4s transition where rain opacity ramps down
// Then back to clear.
// Cloud opacity ramps in sync, slightly slower.

type WeatherPhase = 'clear' | 'fading_in' | 'raining' | 'fading_out';

interface WeatherState {
  phase: WeatherPhase;
  phaseEndsAt: number; // seconds (clock time)
  rainOpacity: number; // 0..1 (current visible opacity, ramped)
  cloudOpacity: number; // 0..1
}

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

// Phase durations (seconds)
const FADE_DURATION = 4;
const CLEAR_MIN = 20;
const CLEAR_MAX = 60;
const RAIN_MIN = 30;
const RAIN_MAX = 90;

function randRange(min: number, max: number) {
  return min + Math.random() * (max - min);
}

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

// Decide initial phase — always start clear so the player can see the city on game start.
// First rain will come after a random clear period (20-60s).
function buildInitialWeatherState(now: number): WeatherState {
  return {
    phase: 'clear',
    phaseEndsAt: now + randRange(CLEAR_MIN, CLEAR_MAX),
    rainOpacity: 0,
    cloudOpacity: 0,
  };
}

// Advance weather state machine by `dt` seconds.
function advanceWeather(s: WeatherState, now: number): WeatherState {
  // Helper to pick next phase
  const next = (currentPhase: WeatherPhase): WeatherState => {
    if (currentPhase === 'clear') {
      return {
        phase: 'fading_in',
        phaseEndsAt: now + FADE_DURATION,
        rainOpacity: 0,
        cloudOpacity: 0,
      };
    }
    if (currentPhase === 'fading_in') {
      return {
        phase: 'raining',
        phaseEndsAt: now + randRange(RAIN_MIN, RAIN_MAX),
        rainOpacity: 1,
        cloudOpacity: 1,
      };
    }
    if (currentPhase === 'raining') {
      return {
        phase: 'fading_out',
        phaseEndsAt: now + FADE_DURATION,
        rainOpacity: 1,
        cloudOpacity: 1,
      };
    }
    // fading_out → clear
    return {
      phase: 'clear',
      phaseEndsAt: now + randRange(CLEAR_MIN, CLEAR_MAX),
      rainOpacity: 0,
      cloudOpacity: 0,
    };
  };

  // Advance phase if time elapsed
  if (now >= s.phaseEndsAt) {
    return next(s.phase);
  }

  // Compute current opacity based on phase + time remaining
  let rainOpacity = s.rainOpacity;
  let cloudOpacity = s.cloudOpacity;
  const phaseProgress = 1 - Math.max(0, (s.phaseEndsAt - now) / FADE_DURATION);

  if (s.phase === 'fading_in') {
    rainOpacity = phaseProgress;
    cloudOpacity = Math.min(1, phaseProgress * 1.2); // clouds arrive slightly faster
  } else if (s.phase === 'fading_out') {
    rainOpacity = 1 - phaseProgress;
    cloudOpacity = Math.max(0, 1 - phaseProgress * 0.9); // clouds linger a bit after rain stops
  } else if (s.phase === 'raining') {
    rainOpacity = 1;
    cloudOpacity = 1;
  } else {
    rainOpacity = 0;
    // During 'clear', clouds gradually dissipate (in case they were lingering from a recent fade-out)
    cloudOpacity = Math.max(0, s.cloudOpacity - 0.01);
  }

  return { ...s, rainOpacity, cloudOpacity };
}

export function Weather() {
  const linesRef = useRef<THREE.LineSegments>(null);
  const cloudMatRef = useRef<THREE.MeshBasicMaterial>(null);
  const rainMatRef = useRef<THREE.LineBasicMaterial>(null);
  const ambientRef = useRef<THREE.AmbientLight>(null);

  const [initialRain] = useState<RainDrop[]>(buildInitialRain);
  const rainRef = useRef<RainDrop[]>(initialRain);
  // Weather state stored in a ref so we can mutate it each frame without re-rendering.
  // Initialize at clock time 0.
  const weatherRef = useRef<WeatherState>(buildInitialWeatherState(0));

  // Build line-segments geometry: each drop = 2 vertices (top, bottom)
  const geometry = useMemo(() => {
    const geo = new THREE.BufferGeometry();
    const positions = new Float32Array(RAIN_COUNT * 6);
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
    const now = state.clock.elapsedTime;
    // Advance weather state machine
    weatherRef.current = advanceWeather(weatherRef.current, now);
    const w = weatherRef.current;

    // Update material opacities based on weather
    if (rainMatRef.current) {
      rainMatRef.current.opacity = 0.5 * w.rainOpacity;
      rainMatRef.current.visible = w.rainOpacity > 0.01;
    }
    if (cloudMatRef.current) {
      cloudMatRef.current.opacity = 0.4 * w.cloudOpacity;
      cloudMatRef.current.visible = w.cloudOpacity > 0.01;
    }
    if (ambientRef.current) {
      ambientRef.current.intensity = 0.08 * w.rainOpacity;
    }

    // Only update rain particles if rain is visible (perf optimization during clear weather)
    if (w.rainOpacity < 0.01) return;

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

      positions[i * 6] = d.x;
      positions[i * 6 + 1] = d.y + DROP_LENGTH;
      positions[i * 6 + 2] = d.z;
      positions[i * 6 + 3] = d.x;
      positions[i * 6 + 4] = d.y;
      positions[i * 6 + 5] = d.z;
    }
    (linesRef.current.geometry.attributes.position as THREE.BufferAttribute).needsUpdate = true;
  });

  return (
    <>
      {/* Rain as line segments — vertical streaks (hidden when not raining) */}
      <lineSegments ref={linesRef} geometry={geometry}>
        <lineBasicMaterial
          ref={rainMatRef}
          color="#a8c5e8"
          transparent
          opacity={0}
        />
      </lineSegments>

      {/* Cloud layer — dark plane above the rain area, fades in/out with weather */}
      <mesh position={[0, 30, 0]} rotation={[Math.PI / 2, 0, 0]}>
        <planeGeometry args={[200, 200]} />
        <meshBasicMaterial
          ref={cloudMatRef}
          color="#0c1322"
          transparent
          opacity={0}
          side={THREE.DoubleSide}
          visible={false}
        />
      </mesh>

      {/* Subtle blue overlay light during rain — fades with rain intensity */}
      <ambientLight ref={ambientRef} intensity={0} color="#3b4f6e" />
    </>
  );
}
