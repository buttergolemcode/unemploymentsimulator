'use client';

import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { useGame } from '@/lib/game/store';
import type { LogEntry } from '@/lib/game/types';
import {
  DollarSign,
  TrendingDown,
  Flame,
  Info,
  AlertTriangle,
  Newspaper,
  Trophy,
} from 'lucide-react';

const typeMeta: Record<
  LogEntry['type'],
  { icon: typeof Info; color: string; bg: string }
> = {
  info: { icon: Info, color: 'text-muted-foreground', bg: '' },
  success: { icon: Trophy, color: 'text-emerald-600 dark:text-emerald-400', bg: 'bg-emerald-50 dark:bg-emerald-950/30' },
  money: { icon: DollarSign, color: 'text-emerald-600 dark:text-emerald-400', bg: 'bg-emerald-50 dark:bg-emerald-950/30' },
  danger: { icon: AlertTriangle, color: 'text-red-600 dark:text-red-400', bg: 'bg-red-50 dark:bg-red-950/30' },
  heat: { icon: Flame, color: 'text-orange-600 dark:text-orange-400', bg: 'bg-orange-50 dark:bg-orange-950/30' },
  event: { icon: Newspaper, color: 'text-purple-600 dark:text-purple-400', bg: 'bg-purple-50 dark:bg-purple-950/30' },
};

export function ActionLog() {
  const log = useGame((s) => s.log);

  return (
    <Card className="p-3 md:p-4 flex flex-col h-full">
      <div className="flex items-center justify-between mb-2">
        <h3 className="text-sm font-semibold uppercase tracking-wide text-muted-foreground">
          Action Log
        </h3>
        <Badge variant="outline" className="text-[10px]">
          {log.length} entries
        </Badge>
      </div>
      <div className="flex-1 overflow-y-auto max-h-[420px] md:max-h-[600px] pr-1 -mr-1 space-y-1.5">
        {log.length === 0 && (
          <p className="text-sm text-muted-foreground italic">No activity yet.</p>
        )}
        {log.map((entry) => {
          const meta = typeMeta[entry.type];
          const Icon = meta.icon;
          return (
            <div
              key={entry.id}
              className={`flex items-start gap-2 rounded-md p-2 text-xs md:text-sm ${meta.bg}`}
            >
              <Icon className={`h-3.5 w-3.5 mt-0.5 shrink-0 ${meta.color}`} />
              <div className="flex-1 min-w-0">
                <span className={`font-mono text-[10px] mr-1 ${meta.color}`}>
                  D{entry.day}
                </span>
                <span className="leading-snug">{entry.text}</span>
              </div>
            </div>
          );
        })}
      </div>
    </Card>
  );
}
