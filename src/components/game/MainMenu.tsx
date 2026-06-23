'use client';

import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { useGame } from '@/lib/game/store';
import { formatMoneyFull } from '@/lib/game/format';

const SCHEME_HIGHLIGHTS = [
  { emoji: '📦', name: 'E-Com', tag: 'Safe-ish slow money' },
  { emoji: '📈', name: 'Day Trading', tag: 'Yolo your savings' },
  { emoji: '🎰', name: 'Gambling', tag: 'Pure variance' },
  { emoji: '💊', name: 'Drugs', tag: 'Old reliable' },
  { emoji: '🎣', name: 'Scamming', tag: 'The internet pays' },
  { emoji: '🔫', name: 'Robbery', tag: 'High risk / high reward' },
  { emoji: '🧾', name: 'Tax Fraud', tag: 'Passive illegal income' },
  { emoji: '💸', name: 'Wire Fraud', tag: 'Big tech money' },
];

export function MainMenu() {
  const start = useGame((s) => s.start);

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <Card className="max-w-3xl w-full p-6 md:p-10">
        {/* Title */}
        <div className="text-center">
          <div className="text-6xl md:text-7xl mb-2">💸</div>
          <h1 className="text-3xl md:text-5xl font-extrabold tracking-tight">
            UNEMPLOYMENT
            <span className="block text-primary">SIMULATOR 3D</span>
          </h1>
          <p className="mt-3 text-muted-foreground text-sm md:text-base max-w-xl mx-auto">
            You&apos;ve been laid off. The unemployment money is running out. Mom keeps
            asking when you&apos;re &ldquo;going to get a real job.&rdquo; Prove her wrong.
            Walk around a 3D city, hustle 8 shady schemes, and make $1,000,000 in 60 days —
            without ever stepping foot in a McDonald&apos;s.
          </p>
        </div>

        {/* Controls hint */}
        <div className="mt-4 rounded-lg border bg-muted/30 p-3">
          <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground mb-1.5">
            Controls — First-Person (GTA-style)
          </h3>
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 text-xs">
            <div className="flex items-center gap-1.5">
              <kbd className="px-1.5 py-0.5 rounded border bg-card font-mono text-[10px]">WASD</kbd>
              <span className="text-muted-foreground">Walk / Drive</span>
            </div>
            <div className="flex items-center gap-1.5">
              <kbd className="px-1.5 py-0.5 rounded border bg-card font-mono text-[10px]">Mouse</kbd>
              <span className="text-muted-foreground">Look around</span>
            </div>
            <div className="flex items-center gap-1.5">
              <kbd className="px-1.5 py-0.5 rounded border bg-card font-mono text-[10px]">Click</kbd>
              <span className="text-muted-foreground">Lock mouse</span>
            </div>
            <div className="flex items-center gap-1.5">
              <kbd className="px-1.5 py-0.5 rounded border bg-card font-mono text-[10px]">V</kbd>
              <span className="text-muted-foreground">1st/3rd person</span>
            </div>
            <div className="flex items-center gap-1.5">
              <kbd className="px-1.5 py-0.5 rounded border bg-card font-mono text-[10px]">E</kbd>
              <span className="text-muted-foreground">Enter building</span>
            </div>
            <div className="flex items-center gap-1.5">
              <kbd className="px-1.5 py-0.5 rounded border bg-card font-mono text-[10px]">F</kbd>
              <span className="text-muted-foreground">Enter / exit car</span>
            </div>
            <div className="flex items-center gap-1.5">
              <kbd className="px-1.5 py-0.5 rounded border bg-card font-mono text-[10px]">Space</kbd>
              <span className="text-muted-foreground">Handbrake (in car)</span>
            </div>
            <div className="flex items-center gap-1.5">
              <kbd className="px-1.5 py-0.5 rounded border bg-card font-mono text-[10px]">Esc</kbd>
              <span className="text-muted-foreground">Release mouse / exit</span>
            </div>
          </div>
          <p className="mt-2 text-[10px] text-muted-foreground">
            Walk to a parked car and press F to drive. In 3rd person: right-click + drag to rotate camera.
          </p>
        </div>

        {/* Win/Lose conditions */}
        <div className="mt-6 grid sm:grid-cols-2 gap-3">
          <div className="rounded-lg border border-emerald-200 dark:border-emerald-900 bg-emerald-50 dark:bg-emerald-950/30 p-4">
            <h3 className="font-bold text-emerald-700 dark:text-emerald-400 flex items-center gap-2">
              🏆 How to Win
            </h3>
            <p className="mt-1 text-sm">
              Reach <strong>$1,000,000</strong> in cash. Don&apos;t get arrested.
              Don&apos;t go bankrupt. Don&apos;t put on the uniform.
            </p>
          </div>
          <div className="rounded-lg border border-red-200 dark:border-red-900 bg-red-50 dark:bg-red-950/30 p-4">
            <h3 className="font-bold text-red-700 dark:text-red-400 flex items-center gap-2">
              🍟 How to Lose
            </h3>
            <ul className="mt-1 text-sm space-y-0.5">
              <li>• Heat hits 100 → arrested</li>
              <li>• Cash below -$1,000 → bankrupt</li>
              <li>• Day 60 with under $50k → forced to take the McDonald&apos;s job</li>
            </ul>
          </div>
        </div>

        {/* Scheme gallery */}
        <div className="mt-6">
          <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground mb-2">
            8 Schemes to Hustle
          </h3>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
            {SCHEME_HIGHLIGHTS.map((s) => (
              <div
                key={s.name}
                className="rounded-lg border bg-card p-2.5 text-center hover:border-primary/40 transition-colors"
              >
                <div className="text-2xl">{s.emoji}</div>
                <div className="mt-1 text-xs font-semibold">{s.name}</div>
                <div className="text-[10px] text-muted-foreground leading-tight mt-0.5">
                  {s.tag}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Start button */}
        <div className="mt-8 flex flex-col items-center gap-3">
          <Button size="lg" className="w-full sm:w-auto px-12 text-base" onClick={start}>
            Start Hustling →
          </Button>
          <p className="text-[11px] text-muted-foreground">
            Starting cash: {formatMoneyFull(500)} · Max actions per day: 3 · 60 days to make it
          </p>
        </div>
      </Card>
    </div>
  );
}


