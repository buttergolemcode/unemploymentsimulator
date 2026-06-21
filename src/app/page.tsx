'use client';

import { useGame } from '@/lib/game/store';
import { GameCanvas } from '@/components/game3d/GameCanvas';
import { BuildingActionPanel } from '@/components/game3d/BuildingActionPanel';
import { EventModal } from '@/components/game/EventModal';
import { MainMenu } from '@/components/game/MainMenu';
import { EndScreen } from '@/components/game/EndScreen';
import { ActionLog } from '@/components/game/ActionLog';
import { usePlayer } from '@/components/game3d/playerStore';
import { useEffect, useState } from 'react';
import {
  HUDStatsBar,
  MiniMap,
  QuickTravel,
  TopBar,
} from '@/components/game3d/HUD';
import { Button } from '@/components/ui/button';
import { ScrollText as LogIcon, X } from 'lucide-react';

export default function Home() {
  const phase = useGame((s) => s.phase);
  const pendingEvent = useGame((s) => s.pendingEvent);
  const nearbyBuildingId = usePlayer((s) => s.nearbyBuildingId);
  const actionPanelOpen = usePlayer((s) => s.actionPanelOpen);
  const setActionPanel = usePlayer((s) => s.setActionPanel);
  const resetPosition = usePlayer((s) => s.resetPosition);

  // Local UI state
  const [logOpen, setLogOpen] = useState(false);

  // When the game phase changes to 'playing', reset the player position
  useEffect(() => {
    if (phase === 'playing') {
      resetPosition();
    }
  }, [phase, resetPosition]);

  // Keyboard shortcut 'E' to open action panel (handled in GameCanvas KeyboardController),
  // but we also listen here to keep panel state in sync.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'e' || e.key === 'E') {
        if (nearbyBuildingId && phase === 'playing' && !pendingEvent && !actionPanelOpen) {
          setActionPanel(true);
          e.preventDefault();
        }
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [nearbyBuildingId, phase, pendingEvent, actionPanelOpen, setActionPanel]);

  if (phase === 'menu') {
    return <MainMenu />;
  }

  if (phase === 'won' || phase === 'lost') {
    return <EndScreen />;
  }

  return (
    <div className="relative min-h-screen overflow-hidden bg-[#0a0e1a]">
      {/* 3D Canvas (full screen) */}
      <GameCanvas />

      {/* Top-left: title + actions */}
      <div className="absolute top-2 left-2 right-2 md:top-4 md:left-4 md:right-auto z-10 flex items-center gap-2">
        <div className="backdrop-blur-md bg-card/80 rounded-lg px-3 py-1.5 border">
          <div className="text-xs md:text-sm font-bold leading-none flex items-center gap-1.5">
            <span className="text-base">💸</span>
            <span className="hidden sm:inline">Unemployment Sim</span>
            <span className="sm:hidden">3D</span>
          </div>
        </div>
        <TopBar />
      </div>

      {/* Top-right: mini-map (desktop) */}
      <div className="absolute top-2 right-2 md:top-4 md:right-4 z-10 hidden md:block">
        <MiniMap />
      </div>

      {/* Below stats bar (top-left, full width) */}
      <div className="absolute top-14 md:top-20 left-2 right-2 md:left-4 md:right-auto md:max-w-md z-10">
        <HUDStatsBar />
      </div>

      {/* Bottom-left: Quick travel */}
      <div className="absolute bottom-2 left-2 md:bottom-4 md:left-4 z-10 max-w-xs">
        <QuickTravel />
      </div>

      {/* Bottom-right: log toggle + log panel */}
      <div className="absolute bottom-2 right-2 md:bottom-4 md:right-4 z-10 flex flex-col items-end gap-2 max-w-sm">
        {logOpen ? (
          <div className="w-[280px] md:w-[360px]">
            <div className="flex items-center justify-between mb-1">
              <span className="text-xs font-semibold uppercase tracking-wide text-white/70 px-1">
                Action Log
              </span>
              <Button
                size="icon"
                variant="ghost"
                className="h-6 w-6 text-white/70 hover:text-white"
                onClick={() => setLogOpen(false)}
              >
                <X className="h-3.5 w-3.5" />
              </Button>
            </div>
            <div className="max-h-[300px]">
              <ActionLog />
            </div>
          </div>
        ) : (
          <Button
            size="sm"
            variant="outline"
            className="backdrop-blur-md bg-card/80"
            onClick={() => setLogOpen(true)}
          >
            <LogIcon className="h-4 w-4 mr-1" />
            Log
          </Button>
        )}
      </div>

      {/* Bottom-center: interaction prompt */}
      {nearbyBuildingId && !actionPanelOpen && !pendingEvent && (
        <div className="absolute bottom-24 md:bottom-28 left-1/2 -translate-x-1/2 z-10">
          <Button
            size="lg"
            onClick={() => setActionPanel(true)}
            className="shadow-2xl animate-pulse"
          >
            Enter Building (E)
          </Button>
        </div>
      )}

      {/* Mobile-only: bottom-center hint */}
      <div className="absolute bottom-1 left-1/2 -translate-x-1/2 md:hidden text-[10px] text-white/50 z-0 pointer-events-none">
        Tap ground to walk · drag to look
      </div>

      {/* Building action panel (overlay) */}
      {actionPanelOpen && nearbyBuildingId && (
        <BuildingActionPanel
          schemeId={nearbyBuildingId}
          onClose={() => setActionPanel(false)}
        />
      )}

      {/* Random event modal */}
      <EventModal />
    </div>
  );
}
