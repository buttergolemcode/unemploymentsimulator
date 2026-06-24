'use client';

import { useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import * as THREE from 'three';
import { useVehicle } from './vehicleStore';
import { terrainHeight } from './terrain';
import type { VehicleState } from './vehicleStore';

// A simple low-poly car: body box + cabin box + 4 wheels + 2 headlights.
// All dimensions in meters. Total length ~4.4m, width ~2m, height ~1.5m.
export function CarMesh({ vehicle }: { vehicle: VehicleState }) {
  const ref = useRef<THREE.Group>(null);

  useFrame(() => {
    if (!ref.current) return;
    const groundY = terrainHeight(vehicle.x, vehicle.z);
    ref.current.position.set(vehicle.x, groundY, vehicle.z);
    ref.current.rotation.y = vehicle.yaw + Math.PI;
  });

  return (
    <group ref={ref} position={[vehicle.x, 0, vehicle.z]} rotation={[0, vehicle.yaw + Math.PI, 0]}>
      {/* Body — main chassis, 4.4m long, 2m wide, 0.7m tall, centered at y=0.6 */}
      <mesh position={[0, 0.6, 0]} castShadow receiveShadow>
        <boxGeometry args={[2, 0.7, 4.4]} />
        <meshStandardMaterial color={vehicle.color} roughness={0.4} metalness={0.5} />
      </mesh>

      {/* Cabin — smaller box on top, 1.6m long, 1.7m wide, 0.6m tall, centered slightly back */}
      <mesh position={[0, 1.25, -0.2]} castShadow receiveShadow>
        <boxGeometry args={[1.7, 0.6, 2.0]} />
        <meshStandardMaterial color={vehicle.color} roughness={0.3} metalness={0.6} />
      </mesh>

      {/* Windshield + windows (dark tinted) */}
      <mesh position={[0, 1.25, 0.85]} rotation={[Math.PI / 2 - 0.3, 0, 0]}>
        <planeGeometry args={[1.6, 0.7]} />
        <meshStandardMaterial color="#0f172a" roughness={0.1} metalness={0.9} transparent opacity={0.8} />
      </mesh>
      <mesh position={[0, 1.25, -1.25]} rotation={[-Math.PI / 2 + 0.3, 0, 0]}>
        <planeGeometry args={[1.6, 0.7]} />
        <meshStandardMaterial color="#0f172a" roughness={0.1} metalness={0.9} transparent opacity={0.8} />
      </mesh>
      {/* Side windows */}
      <mesh position={[0.86, 1.25, -0.2]} rotation={[0, Math.PI / 2, 0]}>
        <planeGeometry args={[1.8, 0.4]} />
        <meshStandardMaterial color="#0f172a" roughness={0.1} metalness={0.9} transparent opacity={0.7} />
      </mesh>
      <mesh position={[-0.86, 1.25, -0.2]} rotation={[0, -Math.PI / 2, 0]}>
        <planeGeometry args={[1.8, 0.4]} />
        <meshStandardMaterial color="#0f172a" roughness={0.1} metalness={0.9} transparent opacity={0.7} />
      </mesh>

      {/* Wheels — 4 cylinders rotated to point sideways (wheel axle along X) */}
      <Wheel position={[-0.9, 0.35, 1.5]} />
      <Wheel position={[0.9, 0.35, 1.5]} />
      <Wheel position={[-0.9, 0.35, -1.5]} />
      <Wheel position={[0.9, 0.35, -1.5]} />

      {/* Headlights (front, +Z direction in car-local space) */}
      <mesh position={[0.6, 0.6, 2.21]}>
        <sphereGeometry args={[0.15, 8, 8]} />
        <meshStandardMaterial color="#fef3c7" emissive="#fef3c7" emissiveIntensity={1.5} />
      </mesh>
      <mesh position={[-0.6, 0.6, 2.21]}>
        <sphereGeometry args={[0.15, 8, 8]} />
        <meshStandardMaterial color="#fef3c7" emissive="#fef3c7" emissiveIntensity={1.5} />
      </mesh>

      {/* Taillights (back, -Z direction) */}
      <mesh position={[0.6, 0.6, -2.21]}>
        <sphereGeometry args={[0.12, 8, 8]} />
        <meshStandardMaterial color="#dc2626" emissive="#dc2626" emissiveIntensity={1.0} />
      </mesh>
      <mesh position={[-0.6, 0.6, -2.21]}>
        <sphereGeometry args={[0.12, 8, 8]} />
        <meshStandardMaterial color="#dc2626" emissive="#dc2626" emissiveIntensity={1.0} />
      </mesh>

      {/* Ground shadow blob */}
      <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, 0.02, 0]}>
        <planeGeometry args={[2.4, 4.8]} />
        <meshBasicMaterial color="#000000" transparent opacity={0.25} />
      </mesh>
    </group>
  );
}

function Wheel({ position }: { position: [number, number, number] }) {
  return (
    <mesh position={position} rotation={[0, 0, Math.PI / 2]} castShadow>
      <cylinderGeometry args={[0.35, 0.35, 0.25, 16]} />
      <meshStandardMaterial color="#1a1a1a" roughness={0.9} />
    </mesh>
  );
}

// Render all vehicles in the world
export function VehicleLayer() {
  const vehicles = useVehicle((s) => s.vehicles);
  return (
    <>
      {vehicles.map((v) => (
        <CarMesh key={v.id} vehicle={v} />
      ))}
    </>
  );
}
