'use client';

import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { useGame } from '@/lib/game/store';

export function EventModal() {
  const pendingEvent = useGame((s) => s.pendingEvent);
  const resolveEvent = useGame((s) => s.resolveEvent);

  return (
    <Dialog open={pendingEvent !== null} onOpenChange={() => { /* can't dismiss */ }}>
      <DialogContent className="max-w-md" >
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 text-xl">
            <span className="text-2xl">📰</span>
            {pendingEvent?.title ?? 'Event'}
          </DialogTitle>
          <DialogDescription className="text-sm leading-relaxed pt-1">
            {pendingEvent?.description}
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-2 pt-2">
          {pendingEvent?.choices.map((choice, i) => (
            <Button
              key={i}
              variant={i === 0 ? 'default' : 'outline'}
              className="w-full justify-start text-left h-auto py-3 whitespace-normal"
              onClick={() => resolveEvent(i)}
            >
              {choice.label}
            </Button>
          ))}
        </div>
      </DialogContent>
    </Dialog>
  );
}
