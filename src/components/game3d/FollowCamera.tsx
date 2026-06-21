'use client';

import { useRef } from 'react';
import { useFrame, useThree } from '@react-three/fiber';
import * as THREE from 'three';
import { usePlayer } from './playerStore';

// Third-person follow camera. Looks down at the player from behind/above.
export function FollowCamera() {
  const { camera } = useThree();
  const targetVec = useRef(new THREE.Vector3());
  const desiredPos = useRef(new THREE.Vector3());

  useFrame(() => {
    const px = usePlayer.getState().x;
    const pz = usePlayer.getState().z;

    // Camera offset: behind and above the player
    const camOffsetX = 0;
    const camOffsetY = 14;
    const camOffsetZ = 14;

    desiredPos.current.set(px + camOffsetX, camOffsetY, pz + camOffsetZ);
    targetVec.current.set(px, 1, pz);

    // Smoothly lerp camera toward desired position
    camera.position.lerp(desiredPos.current, 0.08);
    camera.lookAt(targetVec.current);
  });

  return null;
}
