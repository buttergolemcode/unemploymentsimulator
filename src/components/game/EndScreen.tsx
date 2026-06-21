'use client';

import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { useGame } from '@/lib/game/store';
import { formatMoneyFull } from '@/lib/game/format';

const LOSE_REASONS: Record<string, { title: string; emoji: string; flavor: string }> = {
  mcdonalds: {
    title: 'You Put On the Uniform',
    emoji: '🍟',
    flavor:
      'Day 60 came and went. The unemployment money was long gone. Mom stopped returning your calls. You walked into McDonald\'s, filled out the application, and asked the 19-year-old manager when you could start. He said "tomorrow at 6 AM." You showed up at 5:45. The dream is dead. You smell like fry grease forever.',
  },
  arrested: {
    title: 'Busted',
    emoji: '🚔',
    flavor:
      'Heat hit 100. Federal agents kicked your door in at 4 AM. Your lawyer says you\'re looking at 8-12 years. The feds seized every dollar they could find. Mom cried in the courtroom. On the bright side, three meals a day and a cot — kind of like having a job after all.',
  },
  bankrupt: {
    title: 'Broke Beyond Recovery',
    emoji: '💸',
    flavor:
      'You over-leveraged. The bad bets compounded. Creditors are calling. There\'s a stack of overdue bills on the kitchen table. You couldn\'t make rent this month. The McDonald\'s "NOW HIRING" sign in the window was the only job posting you qualified for. You took it. The fries are soggy. So is your spirit.',
  },
};

export function EndScreen() {
  const phase = useGame((s) => s.phase);
  const loseReason = useGame((s) => s.loseReason);
  const money = useGame((s) => s.money);
  const day = useGame((s) => s.day);
  const stats = useGame((s) => s.stats);
  const skills = useGame((s) => s.skills);
  const reset = useGame((s) => s.reset);

  if (phase !== 'won' && phase !== 'lost') return null;

  const isWin = phase === 'won';
  const loseMeta = loseReason ? LOSE_REASONS[loseReason] : null;

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <Card
        className={`max-w-2xl w-full p-6 md:p-10 ${
          isWin
            ? 'border-emerald-300 dark:border-emerald-700'
            : 'border-red-300 dark:border-red-700'
        }`}
      >
        {/* Header */}
        <div className="text-center">
          <div className="text-6xl md:text-7xl mb-3">
            {isWin ? '🏆' : loseMeta?.emoji}
          </div>
          <h1
            className={`text-3xl md:text-4xl font-extrabold tracking-tight ${
              isWin
                ? 'text-emerald-600 dark:text-emerald-400'
                : 'text-red-600 dark:text-red-400'
            }`}
          >
            {isWin ? 'YOU MADE IT' : 'GAME OVER'}
          </h1>
          <h2 className="mt-1 text-lg md:text-xl font-semibold">
            {isWin
              ? '$1,000,000 in the bank. No job. No boss.'
              : loseMeta?.title ?? 'The dream is over'}
          </h2>
        </div>

        {/* Flavor text */}
        <p className="mt-5 text-sm md:text-base leading-relaxed text-muted-foreground">
          {isWin
            ? 'You stared down McDonald\'s and won. The funds cleared, the heat cooled, and you walked out of the hustle with seven figures. Mom still doesn\'t know how you did it. She thinks you "got into crypto." You\'re moving to a beach town with no extradition treaty. The dream is real. You are officially unemployed and rich.'
            : loseMeta?.flavor}
        </p>

        {/* Run stats */}
        <div className="mt-6 grid grid-cols-2 sm:grid-cols-4 gap-2">
          <Stat label="Final Cash" value={formatMoneyFull(money)} />
          <Stat label="Days Survived" value={`${day}`} />
          <Stat label="Total Earned" value={formatMoneyFull(stats.totalEarned)} />
          <Stat label="Deals Closed" value={`${stats.dealsClosed}`} />
        </div>

        {/* Skills */}
        <div className="mt-4">
          <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground mb-2">
            Skill Levels Reached
          </h3>
          <div className="grid grid-cols-3 sm:grid-cols-5 gap-2">
            {Object.entries(skills)
              .filter(([id]) => id !== 'hustle')
              .map(([id, s]) => (
                <div
                  key={id}
                  className="rounded-md border bg-card p-2 text-center"
                >
                  <div className="text-xs uppercase tracking-wide text-muted-foreground">
                    {id}
                  </div>
                  <div className="text-lg font-bold tabular-nums">Lv.{s.level}</div>
                </div>
              ))}
          </div>
        </div>

        {/* Restart */}
        <div className="mt-8 flex justify-center">
          <Button size="lg" onClick={reset} className="px-12">
            Try Again
          </Button>
        </div>
      </Card>
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-md border bg-card p-2 text-center">
      <div className="text-[10px] uppercase tracking-wide text-muted-foreground">
        {label}
      </div>
      <div className="text-base md:text-lg font-bold tabular-nums">{value}</div>
    </div>
  );
}
