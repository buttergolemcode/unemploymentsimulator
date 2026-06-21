// Day/night cycle utilities.
// Time-of-day t in [0, 1): 0 = midnight, 0.25 = dawn (6 AM), 0.5 = noon, 0.75 = dusk (6 PM).
// One in-game day = 90 real seconds. Each new game-day starts at dawn (t = 0.25).

const CYCLE_SECONDS = 90; // one full day-night cycle

export function getTimeOfDay(elapsedSeconds: number, gameDay: number): number {
  // We don't multiply by gameDay because the clock already advanced past dawn on day 1.
  // The cycle simply loops every CYCLE_SECONDS seconds.
  const cycle = (elapsedSeconds % CYCLE_SECONDS) / CYCLE_SECONDS;
  // Shift so that t=0 in our cycle is dawn (6 AM), making cycle 0..0.5 = daytime, 0.5..1 = night
  return (cycle + 0.25) % 1;
}

export type DayPhase = 'dawn' | 'day' | 'dusk' | 'night';

export function getDayPhase(t: number): DayPhase {
  // t in [0, 1)
  if (t < 0.08 || t >= 0.92) return 'night'; // 12am-5am, 10pm-12am
  if (t < 0.2) return 'dawn'; // 5am-7:30am
  if (t < 0.7) return 'day'; // 7:30am-4:30pm
  if (t < 0.83) return 'dusk'; // 4:30pm-8pm
  return 'night'; // 8pm-12am
}

// Format t to HH:MM
export function formatClock(t: number): string {
  const hours24 = Math.floor(t * 24);
  const minutes = Math.floor((t * 24 * 60) % 60);
  const hh = hours24.toString().padStart(2, '0');
  const mm = minutes.toString().padStart(2, '0');
  return `${hh}:${mm}`;
}

export const CYCLE_DURATION = CYCLE_SECONDS;
