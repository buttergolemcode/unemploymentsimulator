'use client';

import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { schemes } from '@/lib/game/store';
import { useGame } from '@/lib/game/store';
import type { Scheme, SchemeId } from '@/lib/game/types';
import { ShieldAlert, Clock, DollarSign } from 'lucide-react';
import { useState } from 'react';

const heatRiskColor: Record<Scheme['heatRisk'], string> = {
  low: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300',
  medium: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-950 dark:text-yellow-300',
  high: 'bg-orange-100 text-orange-700 dark:bg-orange-950 dark:text-orange-300',
  extreme: 'bg-red-100 text-red-700 dark:bg-red-950 dark:text-red-300',
};

export function SchemePanel({ scheme }: { scheme: Scheme }) {
  const performAction = useGame((s) => s.performAction);
  const actionsLeft = useGame((s) => s.actionsLeft);
  const skill = useGame((s) => s.skills[scheme.id]);
  const pendingEvent = useGame((s) => s.pendingEvent);
  const phase = useGame((s) => s.phase);

  const [busyAction, setBusyAction] = useState<string | null>(null);

  const disabled = pendingEvent !== null || phase !== 'playing';

  const handleAction = (actionId: string, cost: number) => {
    if (disabled) return;
    if (actionsLeft < cost) return;
    setBusyAction(actionId);
    // Slight delay for visual feedback
    setTimeout(() => {
      performAction(scheme.id, actionId);
      setBusyAction(null);
    }, 150);
  };

  return (
    <div className="space-y-3">
      {/* Header */}
      <Card className="p-4 md:p-5">
        <div className="flex items-start gap-3">
          <div className="text-3xl md:text-4xl leading-none">{scheme.emoji}</div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <h3 className="text-lg md:text-xl font-bold leading-none">{scheme.name}</h3>
              <Badge variant="outline" className={`text-[10px] ${heatRiskColor[scheme.heatRisk]}`}>
                <ShieldAlert className="h-3 w-3 mr-1" />
                {scheme.heatRisk.toUpperCase()} HEAT
              </Badge>
            </div>
            <p className="mt-1 text-xs md:text-sm text-muted-foreground italic">
              &ldquo;{scheme.tagline}&rdquo;
            </p>
            <p className="mt-2 text-sm">{scheme.description}</p>
            <div className="mt-3 flex flex-wrap items-center gap-3 text-xs text-muted-foreground">
              <span className="flex items-center gap-1">
                <DollarSign className="h-3 w-3" />
                {scheme.rewardRange}
              </span>
              <span className="flex items-center gap-1">
                <span className="font-semibold text-foreground">Skill:</span>
                Lv.{skill.level}
                <span className="text-muted-foreground/70">({skill.xp}/100 XP)</span>
              </span>
            </div>
            <div className="mt-1.5 h-1.5 w-full bg-muted rounded-full overflow-hidden">
              <div
                className="h-full bg-primary transition-all"
                style={{ width: `${skill.xp}%` }}
              />
            </div>
          </div>
        </div>
      </Card>

      {/* Actions */}
      <div className="grid gap-2 md:gap-3">
        {scheme.actions.map((action) => {
          const insufficientActions = actionsLeft < action.cost;
          const unavailable = action.available ? !action.available(useGame.getState()) : false;
          const isDisabled =
            disabled || insufficientActions || unavailable || busyAction === action.id;
          return (
            <Card
              key={action.id}
              className={`p-3 md:p-4 transition-colors ${
                isDisabled ? 'opacity-60' : 'hover:border-primary/40 cursor-pointer'
              }`}
              onClick={() => !isDisabled && handleAction(action.id, action.cost)}
            >
              <div className="flex items-start justify-between gap-3">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
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
                  onClick={(e) => {
                    e.stopPropagation();
                    handleAction(action.id, action.cost);
                  }}
                >
                  {busyAction === action.id ? '...' : 'Run'}
                </Button>
              </div>
            </Card>
          );
        })}
      </div>
    </div>
  );
}

export function SchemeTabs() {
  const [active, setActive] = useState<SchemeId>('ecom');
  const scheme = schemes.find((s) => s.id === active)!;

  return (
    <div className="space-y-3">
      {/* Scheme selector chips */}
      <div className="flex gap-2 overflow-x-auto pb-1 -mx-1 px-1">
        {schemes.map((s) => (
          <button
            key={s.id}
            onClick={() => setActive(s.id)}
            className={`shrink-0 px-3 py-2 rounded-lg border text-sm font-medium transition-colors ${
              active === s.id
                ? 'bg-primary text-primary-foreground border-primary'
                : 'bg-card border-border hover:border-primary/40'
            }`}
          >
            <span className="mr-1.5">{s.emoji}</span>
            {s.name}
          </button>
        ))}
      </div>
      <SchemePanel scheme={scheme} />
    </div>
  );
}
