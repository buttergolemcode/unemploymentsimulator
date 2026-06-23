'use client';

import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  DollarSign, Flame, Calendar, Star, Zap, Bed, Bug,
  Clock, Eye, Video, MousePointerClick, MapPin, Car, Gauge,
} from 'lucide-react';
import { useGame, WIN_AMOUNT, MAX_ACTIONS, MAX_DAYS } from '@/lib/game/store';
import { formatMoney } from '@/lib/game/format';
import { useMemo, useEffect, useState } from 'react';
import { usePlayer } from './playerStore';
import { useVehicle } from './vehicleStore';
import { walkToBuilding } from './GameCanvas';
import { BUILDINGS, districtAt, DISTRICTS } from './layout';
import { getTimeOfDay, getDayPhase, formatClock } from './dayNight';

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

// District badge — shows which district the player is currently in
export function DistrictBadge() {
  const px = usePlayer((s) => s.x);
  const pz = usePlayer((s) => s.z);
  const d = districtAt(px, pz);
  return (
    <div className="backdrop-blur-md bg-card/80 rounded-lg px-3 py-1.5 border flex items-center gap-1.5">
      <MapPin className="h-3.5 w-3.5 text-primary" />
      <span className="text-xs md:text-sm font-semibold leading-none">
        {d.emoji} {d.name}
      </span>
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

// Crosshair for first-person mode (hidden when driving)
export function Crosshair() {
  const cameraMode = usePlayer((s) => s.cameraMode);
  const pointerLocked = usePlayer((s) => s.pointerLocked);
  const actionPanelOpen = usePlayer((s) => s.actionPanelOpen);
  const inVehicle = useVehicle((s) => s.inVehicleId);
  if (inVehicle !== null || cameraMode !== 'first' || actionPanelOpen) return null;
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

// "Press F to enter vehicle" prompt — appears when player is near a vehicle (and on foot)
export function EnterVehiclePrompt() {
  const inVehicle = useVehicle((s) => s.inVehicleId);
  const px = usePlayer((s) => s.x);
  const pz = usePlayer((s) => s.z);
  const actionPanelOpen = usePlayer((s) => s.actionPanelOpen);
  const pendingEvent = useGame((s) => s.pendingEvent);

  if (inVehicle !== null || actionPanelOpen || pendingEvent) return null;

  // Check if any vehicle is in enter-range
  const vehicles = useVehicle.getState().vehicles;
  const near = vehicles.find((v) => {
    const d = Math.sqrt((v.x - px) ** 2 + (v.z - pz) ** 2);
    return d < 4;
  });
  if (!near) return null;

  return (
    <div className="absolute bottom-32 md:bottom-36 left-1/2 -translate-x-1/2 z-10 pointer-events-none">
      <div className="bg-black/85 backdrop-blur-md text-white text-xs px-3 py-1.5 rounded-md border border-emerald-400/40 flex items-center gap-2 shadow-lg">
        <Car className="h-3.5 w-3.5 text-emerald-400" />
        Press <kbd className="px-1.5 py-0.5 rounded bg-white/10 font-mono text-[10px]">F</kbd> to enter vehicle
      </div>
    </div>
  );
}

// Speedometer + drive controls hint — shown when driving
export function VehicleHUD() {
  const inVehicleId = useVehicle((s) => s.inVehicleId);
  const vehicles = useVehicle((s) => s.vehicles);
  const exitVehicle = useVehicle((s) => s.exitVehicle);
  if (inVehicleId === null) return null;
  const v = vehicles.find((veh) => veh.id === inVehicleId);
  if (!v) return null;

  // Convert m/s to km/h for display
  const kmh = Math.abs(v.speed) * 3.6;
  const isReversing = v.speed < -0.1;
  const throttlePct = Math.min(100, Math.max(0, (Math.abs(v.speed) / v.maxSpeed) * 100));

  return (
    <>
      {/* Speedometer — bottom center */}
      <div className="absolute bottom-20 md:bottom-24 left-1/2 -translate-x-1/2 z-10 pointer-events-none">
        <div className="bg-black/85 backdrop-blur-md text-white px-4 py-2 rounded-lg border border-white/20 flex items-center gap-3">
          <Gauge className="h-5 w-5 text-emerald-400" />
          <div className="flex flex-col">
            <div className="text-xl font-bold tabular-nums leading-none">
              {kmh.toFixed(0)} <span className="text-xs text-white/60">km/h</span>
              {isReversing && <span className="ml-2 text-xs text-amber-400">R</span>}
            </div>
            {/* Speed bar */}
            <div className="mt-1 h-1 w-32 bg-white/10 rounded-full overflow-hidden">
              <div
                className={`h-full transition-all ${isReversing ? 'bg-amber-500' : 'bg-emerald-500'}`}
                style={{ width: `${throttlePct}%` }}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Exit button — bottom right above log button */}
      <div className="absolute bottom-16 right-2 md:bottom-20 md:right-4 z-10 pointer-events-auto">
        <Button
          size="sm"
          variant="outline"
          className="backdrop-blur-md bg-card/80"
          onClick={exitVehicle}
        >
          <Car className="h-4 w-4 mr-1" />
          Exit (F)
        </Button>
      </div>

      {/* Driving controls hint — top center, fades after a few seconds */}
      <DriveControlsHint />
    </>
  );
}

// Brief hint shown when first entering a vehicle
function DriveControlsHint() {
  const [show, setShow] = useState(true);
  useEffect(() => {
    const t = setTimeout(() => setShow(false), 6000);
    return () => clearTimeout(t);
  }, []);
  if (!show) return null;
  return (
    <div className="absolute top-32 md:top-40 left-1/2 -translate-x-1/2 z-10 pointer-events-none animate-in fade-in duration-500">
      <div className="bg-black/85 backdrop-blur-md text-white text-xs px-4 py-2 rounded-lg border border-white/20 text-center max-w-md">
        <div className="font-semibold mb-1 text-emerald-400">Driving</div>
        <div>
          <kbd className="px-1.5 py-0.5 rounded bg-white/10 font-mono text-[10px]">W</kbd> / <kbd className="px-1.5 py-0.5 rounded bg-white/10 font-mono text-[10px]">S</kbd>
          {' '}— accelerate / reverse ·{' '}
          <kbd className="px-1.5 py-0.5 rounded bg-white/10 font-mono text-[10px]">A</kbd> / <kbd className="px-1.5 py-0.5 rounded bg-white/10 font-mono text-[10px]">D</kbd>
          {' '}— steer
        </div>
        <div className="mt-1">
          <kbd className="px-1.5 py-0.5 rounded bg-white/10 font-mono text-[10px]">Space</kbd>
          {' '}— handbrake ·{' '}
          <kbd className="px-1.5 py-0.5 rounded bg-white/10 font-mono text-[10px]">F</kbd>
          {' '}— exit vehicle
        </div>
      </div>
    </div>
  );
}

// Mini-map showing buildings + player dot
export function MiniMap() {
  const px = usePlayer((s) => s.x);
  const pz = usePlayer((s) => s.z);
  const nearbyId = usePlayer((s) => s.nearbyBuildingId);

  // Map world coords (-60..60) to map coords (0..100)
  const toMap = (n: number) => ((n + 60) / 120) * 100;

  return (
    <Card className="p-2 backdrop-blur-md bg-card/90 w-[140px] md:w-[180px]">
      <div className="text-[9px] uppercase tracking-wide text-muted-foreground mb-1">City Map</div>
      <div className="relative w-full aspect-square rounded-md bg-slate-950 border border-border overflow-hidden">
        {/* District quadrant tints */}
        <div className="absolute inset-0 grid grid-cols-2 grid-rows-2">
          <div className="bg-blue-950/40" title="Downtown" />
          <div className="bg-cyan-950/40" title="Harbor" />
          <div className="bg-orange-950/40" title="Slums" />
          <div className="bg-zinc-900/40" title="Industrial" />
        </div>
        {/* District labels */}
        <div className="absolute top-1 left-1 text-[7px] text-blue-300 font-semibold">DT</div>
        <div className="absolute top-1 right-1 text-[7px] text-cyan-300 font-semibold">HB</div>
        <div className="absolute bottom-1 left-1 text-[7px] text-orange-300 font-semibold">SL</div>
        <div className="absolute bottom-1 right-1 text-[7px] text-zinc-400 font-semibold">IN</div>
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
        Walk to a building and press E to enter
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
