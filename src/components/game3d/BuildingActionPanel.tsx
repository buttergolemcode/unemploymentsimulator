'use client';

import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { schemes } from '@/lib/game/store';
import { useGame } from '@/lib/game/store';
import type { Scheme } from '@/lib/game/types';
import { ShieldAlert, Clock, DollarSign, X, MapPin } from 'lucide-react';
import { useState, useEffect } from 'react';
import { usePlayer } from './playerStore';

const heatRiskColor: Record<Scheme['heatRisk'], string> = {
  low: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300',
  medium: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-950 dark:text-yellow-300',
  high: 'bg-orange-100 text-orange-700 dark:bg-orange-950 dark:text-orange-300',
  extreme: 'bg-red-100 text-red-700 dark:bg-red-950 dark:text-red-300',
};

interface Props {
  schemeId: string;
  onClose: () => void;
}

export function BuildingActionPanel({ schemeId, onClose }: Props) {
  const scheme = schemes.find((s) => s.id === schemeId);
  const performAction = useGame((s) => s.performAction);
  const actionsLeft = useGame((s) => s.actionsLeft);
  const pendingEvent = useGame((s) => s.pendingEvent);
  const phase = useGame((s) => s.phase);
  const skill = useGame((s) => (scheme ? s.skills[scheme.id] : null));

  const [busyAction, setBusyAction] = useState<string | null>(null);

  // Esc closes the panel
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [onClose]);

  // Close automatically if game phase changes (won/lost) or event fires
  useEffect(() => {
    if (phase !== 'playing' || pendingEvent) onClose();
  }, [phase, pendingEvent, onClose]);

  if (!scheme || !skill) return null;

  const disabled = pendingEvent !== null || phase !== 'playing';

  const handleAction = (actionId: string, cost: number) => {
    if (disabled) return;
    if (actionsLeft < cost) return;
    setBusyAction(actionId);
    setTimeout(() => {
      performAction(scheme.id, actionId);
      setBusyAction(null);
    }, 150);
  };

  return (
    <div className="absolute inset-0 z-30 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-150">
      <Card className="max-w-2xl w-full max-h-[90vh] overflow-y-auto p-4 md:p-6 shadow-2xl">
        {/* Header */}
        <div className="flex items-start gap-3 mb-4">
          <div className="text-4xl md:text-5xl leading-none">{scheme.emoji}</div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <h3 className="text-xl md:text-2xl font-bold leading-none">{scheme.name}</h3>
              <Badge variant="outline" className={`text-[10px] ${heatRiskColor[scheme.heatRisk]}`}>
                <ShieldAlert className="h-3 w-3 mr-1" />
                {scheme.heatRisk.toUpperCase()} HEAT
              </Badge>
              <Badge variant="secondary" className="text-[10px]">
                <MapPin className="h-3 w-3 mr-1" />
                Inside
              </Badge>
            </div>
            <p className="mt-1 text-xs md:text-sm text-muted-foreground italic">
              &ldquo;{scheme.tagline}&rdquo;
            </p>
          </div>
          <Button
            size="icon"
            variant="ghost"
            className="shrink-0"
            onClick={onClose}
            aria-label="Exit building"
          >
            <X className="h-4 w-4" />
          </Button>
        </div>

        <p className="text-sm mb-4">{scheme.description}</p>

        {/* Skill bar */}
        <div className="mb-4 rounded-md border bg-muted/30 p-2.5">
          <div className="flex items-center justify-between text-xs">
            <span className="font-semibold">Skill Level</span>
            <span className="tabular-nums">
              Lv.{skill.level} <span className="text-muted-foreground">({skill.xp}/100 XP)</span>
            </span>
          </div>
          <div className="mt-1.5 h-1.5 w-full bg-muted rounded-full overflow-hidden">
            <div
              className="h-full bg-primary transition-all"
              style={{ width: `${skill.xp}%` }}
            />
          </div>
          <div className="mt-1 text-[10px] text-muted-foreground">
            Higher level = bigger payouts, lower failure rates.
          </div>
        </div>

        {/* Action list */}
        <div className="grid gap-2">
          {scheme.actions.map((action) => {
            const insufficientActions = actionsLeft < action.cost;
            const unavailable = action.available ? !action.available(useGame.getState()) : false;
            const isDisabled =
              disabled || insufficientActions || unavailable || busyAction === action.id;
            return (
              <Card
                key={action.id}
                className={`p-3 md:p-4 transition-colors ${
                  isDisabled ? 'opacity-60' : 'hover:border-primary/40'
                }`}
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <h4 className="font-semibold text-sm md:text-base">{action.label}</h4>
                      <Badge variant="secondary" className="text-[10px]">
                        <Clock className="h-2.5 w-2.5 mr-1" />
                        {action.cost} {action.cost === 1 ? 'action' : 'actions'}
                      </Badge>
                    </div>
                    <p className="mt-1 text-xs md:text-sm text-muted-foreground leading-snug">
                      {action.description}
                    </p>
                    {unavailable && (
                      <p className="mt-1 text-[11px] text-amber-600 dark:text-amber-400">
                        {action.unavailableReason?.(useGame.getState()) ?? 'Unavailable'}
                      </p>
                    )}
                  </div>
                  <Button
                    size="sm"
                    variant={insufficientActions ? 'outline' : 'default'}
                    disabled={isDisabled}
                    className="shrink-0"
                    onClick={() => handleAction(action.id, action.cost)}
                  >
                    {busyAction === action.id ? '...' : 'Run'}
                  </Button>
                </div>
              </Card>
            );
          })}
        </div>

        {/* Footer hint */}
        <div className="mt-4 pt-3 border-t flex items-center justify-between text-[11px] text-muted-foreground">
          <span className="flex items-center gap-1">
            <DollarSign className="h-3 w-3" />
            Reward range: {scheme.rewardRange}
          </span>
          <span>
            Press <kbd className="px-1.5 py-0.5 rounded border bg-muted font-mono text-[10px]">Esc</kbd> to leave
          </span>
        </div>
      </Card>
    </div>
  );
}
