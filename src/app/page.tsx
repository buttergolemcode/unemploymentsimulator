'use client';

import { useGame } from '@/lib/game/store';
import { StatsBar } from '@/components/game/StatsBar';
import { SchemeTabs } from '@/components/game/SchemePanel';
import { ActionLog } from '@/components/game/ActionLog';
import { EventModal } from '@/components/game/EventModal';
import { MainMenu } from '@/components/game/MainMenu';
import { EndScreen } from '@/components/game/EndScreen';
import { Button } from '@/components/ui/button';
import { Bed, Bug } from 'lucide-react';

export default function Home() {
  const phase = useGame((s) => s.phase);
  const actionsLeft = useGame((s) => s.actionsLeft);
  const endDay = useGame((s) => s.endDay);
  const reset = useGame((s) => s.reset);

  if (phase === 'menu') {
    return <MainMenu />;
  }

  if (phase === 'won' || phase === 'lost') {
    return <EndScreen />;
  }

  return (
    <div className="min-h-screen flex flex-col bg-background">
      {/* Top nav */}
      <header className="border-b bg-card/80 backdrop-blur sticky top-0 z-20">
        <div className="max-w-7xl mx-auto px-3 md:px-6 py-2.5 flex items-center justify-between gap-3">
          <div className="flex items-center gap-2 min-w-0">
            <span className="text-2xl">💸</span>
            <div className="min-w-0">
              <div className="text-sm md:text-base font-bold leading-none truncate">
                Unemployment Simulator
              </div>
              <div className="text-[10px] text-muted-foreground leading-none mt-0.5">
                Make $1M. Avoid McDonald&apos;s.
              </div>
            </div>
          </div>
          <div className="flex items-center gap-2">
            {actionsLeft > 0 ? (
              <Button
                size="sm"
                variant="ghost"
                onClick={() => {
                  if (
                    confirm(
                      'End the day early? You have actions left — they will be wasted.',
                    )
                  ) {
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
            <Button size="sm" variant="outline" onClick={reset}>
              <Bug className="h-4 w-4 mr-1" />
              Restart
            </Button>
          </div>
        </div>
      </header>

      {/* Main grid */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-3 md:px-6 py-4 md:py-6">
        <div className="grid lg:grid-cols-[1fr_400px] gap-4 md:gap-6">
          {/* Left column: stats + scheme */}
          <div className="space-y-4 md:space-y-6 min-w-0">
            <StatsBar />
            <SchemeTabs />
          </div>

          {/* Right column: log */}
          <div className="lg:sticky lg:top-[72px] lg:self-start">
            <ActionLog />
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t mt-8">
        <div className="max-w-7xl mx-auto px-3 md:px-6 py-3 text-center text-[11px] text-muted-foreground">
          Unemployment Simulator · A satirical game about late-stage capitalism ·{' '}
          <span className="text-destructive">Do not try any of this IRL</span>
        </div>
      </footer>

      {/* Event modal */}
      <EventModal />
    </div>
  );
}
