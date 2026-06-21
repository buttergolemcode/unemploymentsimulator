'use client';

import { useMemo } from 'react';
import { Card } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { Badge } from '@/components/ui/badge';
import { DollarSign, Flame, Calendar, Star, Zap } from 'lucide-react';
import { useGame, WIN_AMOUNT, MAX_ACTIONS, MAX_DAYS } from '@/lib/game/store';
import { formatMoney } from '@/lib/game/format';

export function StatsBar() {
  const money = useGame((s) => s.money);
  const day = useGame((s) => s.day);
  const heat = useGame((s) => s.heat);
  const reputation = useGame((s) => s.reputation);
  const actionsLeft = useGame((s) => s.actionsLeft);
  const maxActions = useGame((s) => s.maxActions);

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

  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
      <Card className="p-3 md:p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 text-muted-foreground text-xs uppercase tracking-wide">
            <DollarSign className="h-3.5 w-3.5" /> Cash
          </div>
          <Badge variant="outline" className="text-[10px]">
            Goal: $1M
          </Badge>
        </div>
        <div className="mt-1 text-xl md:text-2xl font-bold tabular-nums">
          {formatMoney(money)}
        </div>
        <Progress value={progressToWin} className="mt-2 h-1.5" />
        <div className="mt-1 text-[10px] text-muted-foreground">
          {progressToWin.toFixed(1)}% to $1,000,000
        </div>
      </Card>

      <Card className="p-3 md:p-4">
        <div className="flex items-center gap-2 text-muted-foreground text-xs uppercase tracking-wide">
          <Flame className="h-3.5 w-3.5" /> Heat
        </div>
        <div className="mt-1 text-xl md:text-2xl font-bold tabular-nums">
          {heat.toFixed(0)}
          <span className="text-sm text-muted-foreground">/100</span>
        </div>
        <div className="mt-2 h-1.5 w-full bg-muted rounded-full overflow-hidden">
          <div
            className={`h-full transition-all ${heatColor}`}
            style={{ width: `${Math.min(100, heat)}%` }}
          />
        </div>
        <div className="mt-1 text-[10px] text-muted-foreground">
          {heat >= 80 ? '🚔 RAID IMMINENT' : heat >= 50 ? 'Person of interest' : heat >= 25 ? 'On the radar' : 'Clean'}
        </div>
      </Card>

      <Card className="p-3 md:p-4">
        <div className="flex items-center gap-2 text-muted-foreground text-xs uppercase tracking-wide">
          <Calendar className="h-3.5 w-3.5" /> Day
        </div>
        <div className="mt-1 text-xl md:text-2xl font-bold tabular-nums">{day}</div>
        <div className="mt-2 flex items-center gap-1">
          <Zap className="h-3.5 w-3.5 text-amber-500" />
          <span className="text-sm font-medium tabular-nums">
            {actionsLeft}
            <span className="text-muted-foreground">/{maxActions}</span>
          </span>
          <span className="text-[10px] text-muted-foreground ml-1">actions left</span>
        </div>
        <div className="mt-1 text-[10px] text-muted-foreground">
          {daysLeft} days until McDonald's pressure
        </div>
      </Card>

      <Card className="p-3 md:p-4">
        <div className="flex items-center gap-2 text-muted-foreground text-xs uppercase tracking-wide">
          <Star className="h-3.5 w-3.5" /> Reputation
        </div>
        <div className="mt-1 text-xl md:text-2xl font-bold tabular-nums">
          {reputation.toFixed(0)}
          <span className="text-sm text-muted-foreground">/100</span>
        </div>
        <Progress value={reputation} className="mt-2 h-1.5" />
        <div className="mt-1 text-[10px] text-muted-foreground">
          {reputation >= 75 ? 'Kingpin' : reputation >= 50 ? 'Made man' : reputation >= 25 ? 'Hustler' : 'Nobody'}
        </div>
      </Card>
    </div>
  );
}
