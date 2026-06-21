'use client';

import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  DollarSign, Flame, Calendar, Star, Zap, Bed, Bug, ChevronRight,
  Clock, Eye, Video, MousePointerClick,
} from 'lucide-react';
import { useGame, WIN_AMOUNT, MAX_ACTIONS, MAX_DAYS, schemes } from '@/lib/game/store';
import { formatMoney } from '@/lib/game/format';
import { useMemo, useEffect, useState } from 'react';
import { usePlayer } from './playerStore';
import { walkToBuilding } from './GameCanvas';
import { BUILDINGS } from './layout';
import { getTimeOfDay, getDayPhase, formatClock } from './dayNight';
import type { SchemeId } from '@/lib/game/types';

export function HUDStatsBar() {
  const money = useGame((s) => s.money);
  const day = useGame((s) => s.day);
  const heat = useGame((s) => s.heat);
  const reputation = useGame((s) => s.reputation);
  const actionsLeft = useGame((s) => s.actionsLeft);
  const maxActions = useGame((s) => s.maxActions);

  // Live clock — updates every second
  const [clock, setClock] = useState('06:00');
  const [phase, setPhase] = useState<'dawn' | 'day' | 'dusk' | 'night'>('dawn');
  const [startTime] = useState(() => performance.now());
  useEffect(() => {
    let raf: number;
    const tick = () => {
      const elapsed = (performance.now() - startTime) / 1000;
      const t = getTimeOfDay(elapsed, day);
      setClock(formatClock(t));
      setPhase(getDayPhase(t));
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [day, startTime]);

  const progressToWin = useMemo(() => Math.min(100, (money / WIN_AMOUNT) * 100), [money]);
  const daysLeft = Math.max(0, MAX_DAYS - day);

  const heatColor =
    heat >= 80
      ? 'bg-red-600'
      : heat >= 50
        ? 'bg-orange-500'
        : heat >= 25
          ? 'bg-yellow-500'
          : 'bg-emerald-500';

  const phaseEmoji =
    phase === 'dawn' ? '🌅' : phase === 'day' ? '☀️' : phase === 'dusk' ? '🌆' : '🌙';

  return (
    <div className="grid grid-cols-2 md:grid-cols-5 gap-2 md:gap-3">
      <Card className="p-2 md:p-3 backdrop-blur-md bg-card/80">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-1.5 text-muted-foreground text-[10px] uppercase tracking-wide">
            <DollarSign className="h-3 w-3" /> Cash
          </div>
          <Badge variant="outline" className="text-[9px] px-1 py-0">
            $1M
          </Badge>
        </div>
        <div className="mt-0.5 text-base md:text-xl font-bold tabular-nums leading-none">
          {formatMoney(money)}
        </div>
        <div className="mt-1 h-1 w-full bg-muted rounded-full overflow-hidden">
          <div className="h-full bg-emerald-500 transition-all" style={{ width: `${progressToWin}%` }} />
        </div>
      </Card>

      <Card className="p-2 md:p-3 backdrop-blur-md bg-card/80">
        <div className="flex items-center gap-1.5 text-muted-foreground text-[10px] uppercase tracking-wide">
          <Flame className="h-3 w-3" /> Heat
        </div>
        <div className="mt-0.5 text-base md:text-xl font-bold tabular-nums leading-none">
          {heat.toFixed(0)}
          <span className="text-xs text-muted-foreground">/100</span>
        </div>
        <div className="mt-1 h-1 w-full bg-muted rounded-full overflow-hidden">
          <div className={`h-full transition-all ${heatColor}`} style={{ width: `${Math.min(100, heat)}%` }} />
        </div>
      </Card>

      <Card className="p-2 md:p-3 backdrop-blur-md bg-card/80">
        <div className="flex items-center gap-1.5 text-muted-foreground text-[10px] uppercase tracking-wide">
          <Calendar className="h-3 w-3" /> Day
        </div>
        <div className="mt-0.5 text-base md:text-xl font-bold tabular-nums leading-none">{day}</div>
        <div className="mt-1 flex items-center gap-1">
          <Zap className="h-3 w-3 text-amber-500" />
          <span className="text-xs font-medium tabular-nums leading-none">
            {actionsLeft}<span className="text-muted-foreground">/{maxActions}</span>
          </span>
          <span className="text-[9px] text-muted-foreground ml-0.5">acts</span>
        </div>
      </Card>

      <Card className="p-2 md:p-3 backdrop-blur-md bg-card/80">
        <div className="flex items-center gap-1.5 text-muted-foreground text-[10px] uppercase tracking-wide">
          <Star className="h-3 w-3" /> Rep
        </div>
        <div className="mt-0.5 text-base md:text-xl font-bold tabular-nums leading-none">
          {reputation.toFixed(0)}
          <span className="text-xs text-muted-foreground">/100</span>
        </div>
        <div className="mt-1 h-1 w-full bg-muted rounded-full overflow-hidden">
          <div className="h-full bg-purple-500 transition-all" style={{ width: `${reputation}%` }} />
        </div>
      </Card>

      <Card className="p-2 md:p-3 backdrop-blur-md bg-card/80">
        <div className="flex items-center gap-1.5 text-muted-foreground text-[10px] uppercase tracking-wide">
          <Clock className="h-3 w-3" /> Time
        </div>
        <div className="mt-0.5 text-base md:text-xl font-bold tabular-nums leading-none">
          {phaseEmoji} {clock}
        </div>
        <div className="mt-1 text-[9px] text-muted-foreground capitalize">{phase}</div>
      </Card>
    </div>
  );
}

// Camera mode toggle (first/third person)
export function CameraToggle() {
  const cameraMode = usePlayer((s) => s.cameraMode);
  const toggleCamera = usePlayer((s) => s.toggleCamera);
  return (
    <Button
      size="sm"
      variant="outline"
      className="backdrop-blur-md bg-card/80"
      onClick={toggleCamera}
      title="Toggle camera (V)"
    >
      {cameraMode === 'first' ? <Eye className="h-4 w-4 mr-1" /> : <Video className="h-4 w-4 mr-1" />}
      {cameraMode === 'first' ? '1st' : '3rd'}
    </Button>
  );
}

// Crosshair for first-person mode
export function Crosshair() {
  const cameraMode = usePlayer((s) => s.cameraMode);
  const pointerLocked = usePlayer((s) => s.pointerLocked);
  const actionPanelOpen = usePlayer((s) => s.actionPanelOpen);
  if (cameraMode !== 'first' || actionPanelOpen) return null;
  return (
    <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-10 pointer-events-none">
      <div className="relative w-6 h-6 flex items-center justify-center">
        <div className="absolute w-0.5 h-0.5 bg-white/80 rounded-full" />
        <div className="absolute w-4 h-px bg-white/40" />
        <div className="absolute h-4 w-px bg-white/40" />
      </div>
      {!pointerLocked && (
        <div className="absolute top-6 left-1/2 -translate-x-1/2 whitespace-nowrap bg-black/70 text-white text-[10px] px-2 py-0.5 rounded border border-white/20">
          <MousePointerClick className="inline h-3 w-3 mr-1" />
          Click to lock mouse
        </div>
      )}
    </div>
  );
}

// Mini-map showing buildings + player dot
export function MiniMap() {
  const px = usePlayer((s) => s.x);
  const pz = usePlayer((s) => s.z);
  const nearbyId = usePlayer((s) => s.nearbyBuildingId);

  // Map world coords (-65..65) to map coords (0..100)
  const toMap = (n: number) => ((n + 65) / 130) * 100;

  return (
    <Card className="p-2 backdrop-blur-md bg-card/90 w-[140px] md:w-[180px]">
      <div className="text-[9px] uppercase tracking-wide text-muted-foreground mb-1">City Map</div>
      <div className="relative w-full aspect-square rounded-md bg-slate-950 border border-border overflow-hidden">
        {/* Buildings */}
        {BUILDINGS.map((b) => {
          const isNear = nearbyId === b.id;
          return (
            <button
              key={b.id}
              onClick={() => walkToBuilding(b.id)}
              title={`${b.name} — click to walk here`}
              className="absolute rounded-sm hover:scale-125 transition-transform"
              style={{
                left: `${toMap(b.x)}%`,
                top: `${toMap(b.z)}%`,
                width: '8px',
                height: '8px',
                transform: 'translate(-50%, -50%)',
                backgroundColor: b.color,
                boxShadow: isNear ? `0 0 8px ${b.color}` : 'none',
                border: isNear ? '1px solid white' : 'none',
                cursor: 'pointer',
              }}
            />
          );
        })}
        {/* Player */}
        <div
          className="absolute rounded-full bg-amber-300"
          style={{
            left: `${toMap(px)}%`,
            top: `${toMap(pz)}%`,
            width: '6px',
            height: '6px',
            transform: 'translate(-50%, -50%)',
            boxShadow: '0 0 6px #fde047',
          }}
        />
      </div>
      <div className="mt-1 text-[9px] text-muted-foreground">
        Click a dot to fast-travel
      </div>
    </Card>
  );
}

// Quick-buildings list (mobile-friendly alternative to walking)
export function QuickTravel() {
  const nearbyId = usePlayer((s) => s.nearbyBuildingId);
  const setActionPanel = usePlayer((s) => s.setActionPanel);
  const actionPanelOpen = usePlayer((s) => s.actionPanelOpen);
  const actionsLeft = useGame((s) => s.actionsLeft);
  const pendingEvent = useGame((s) => s.pendingEvent);
  const phase = useGame((s) => s.phase);

  const handleBuildingClick = (id: SchemeId) => {
    if (phase !== 'playing' || pendingEvent) return;
    if (nearbyId === id) {
      // Already here — open the panel
      setActionPanel(true);
    } else {
      // Walk there
      walkToBuilding(id);
    }
  };

  return (
    <Card className="p-2 backdrop-blur-md bg-card/90">
      <div className="text-[9px] uppercase tracking-wide text-muted-foreground mb-1">
        Quick Travel
      </div>
      <div className="grid grid-cols-4 gap-1">
        {schemes.map((s) => {
          const isNear = nearbyId === s.id;
          return (
            <button
              key={s.id}
              onClick={() => handleBuildingClick(s.id)}
              disabled={phase !== 'playing' || !!pendingEvent || actionPanelOpen || actionsLeft <= 0}
              className={`flex flex-col items-center rounded-md border p-1 text-[10px] transition-colors disabled:opacity-50 ${
                isNear
                  ? 'border-primary bg-primary/10'
                  : 'border-border hover:border-primary/40'
              }`}
              title={s.name}
            >
              <span className="text-base leading-none">{s.emoji}</span>
              <span className="mt-0.5 leading-none truncate w-full text-center">
                {s.name.split(' ')[0]}
              </span>
              {isNear && (
                <span className="text-[8px] text-primary font-semibold leading-none mt-0.5 flex items-center">
                  Enter <ChevronRight className="h-2 w-2" />
                </span>
              )}
            </button>
          );
        })}
      </div>
    </Card>
  );
}

// Top bar with day/end-day/restart buttons
export function TopBar() {
  const actionsLeft = useGame((s) => s.actionsLeft);
  const endDay = useGame((s) => s.endDay);
  const reset = useGame((s) => s.reset);
  const setActionPanel = usePlayer((s) => s.setActionPanel);
  const actionPanelOpen = usePlayer((s) => s.actionPanelOpen);

  return (
    <div className="flex items-center gap-2">
      {actionsLeft > 0 ? (
        <Button
          size="sm"
          variant="ghost"
          className="backdrop-blur-md bg-card/80"
          onClick={() => {
            if (actionPanelOpen) {
              setActionPanel(false);
              return;
            }
            if (confirm('End the day early? You have actions left — they will be wasted.')) {
              endDay();
            }
          }}
        >
          <Bed className="h-4 w-4 mr-1" />
          Sleep early
        </Button>
      ) : (
        <Button size="sm" onClick={endDay}>
          <Bed className="h-4 w-4 mr-1" />
          End day
        </Button>
      )}
      <Button size="sm" variant="outline" className="backdrop-blur-md bg-card/80" onClick={reset}>
        <Bug className="h-4 w-4 mr-1" />
        Restart
      </Button>
    </div>
  );
}
