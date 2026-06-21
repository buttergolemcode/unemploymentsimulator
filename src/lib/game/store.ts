// Unemployment Simulator — Game Store (Zustand)
import { create } from 'zustand';
import type {
  GameState,
  LogEntry,
  SkillId,
  SchemeId,
  GameEvent,
  GameEventChoice,
} from './types';
import { schemes, getScheme } from './schemes';
import { rollDailyEvent } from './events';

const WIN_AMOUNT = 1_000_000;
const MAX_ACTIONS = 3;
const STARTING_MONEY = 500;
const MAX_DAYS = 60; // soft cap — after this, McDonald's offer becomes inevitable

// Module-level flag for "is the 3D action panel currently open?"
// This avoids a circular import between the game store and the player store.
let _actionPanelOpen = false;
function isActionPanelOpen() {
  return _actionPanelOpen;
}
export function setActionPanelOpen(open: boolean) {
  _actionPanelOpen = open;
}

function makeInitialSkills(): Record<SkillId, { level: number; xp: number }> {
  const ids: SkillId[] = [
    'ecom',
    'trading',
    'gambling',
    'drugs',
    'scam',
    'robbery',
    'taxfraud',
    'wirefraud',
    'hustle',
  ];
  const out = {} as Record<SkillId, { level: number; xp: number }>;
  for (const id of ids) {
    out[id] = { level: 1, xp: 0 };
  }
  return out;
}

function makeInitialState(): GameState {
  return {
    phase: 'menu',
    loseReason: null,
    money: STARTING_MONEY,
    day: 1,
    actionsLeft: MAX_ACTIONS,
    maxActions: MAX_ACTIONS,
    heat: 0,
    reputation: 0,
    skills: makeInitialSkills(),
    stocks: [],
    taxSetup: false,
    taxAccrued: 0,
    stats: {
      totalEarned: 0,
      totalLost: 0,
      dealsClosed: 0,
      daysSurvived: 1,
    },
    log: [
      {
        id: crypto.randomUUID(),
        day: 1,
        type: 'info',
        text: 'Welcome to the unemployment simulator. You\'ve got $500, no job, and 60 days to hit $1,000,000. Good luck out there.',
      },
    ],
    pendingEvent: null,
  };
}

function clamp(n: number, min: number, max: number) {
  return Math.max(min, Math.min(max, n));
}

function makeLogEntry(day: number, type: LogEntry['type'], text: string): LogEntry {
  return { id: crypto.randomUUID(), day, type, text };
}

interface GameStore extends GameState {
  start: () => void;
  reset: () => void;
  performAction: (schemeId: SchemeId, actionId: string) => void;
  endDay: () => void;
  resolveEvent: (choiceIndex: number) => void;
  dismissEvent: () => void;
}

export const useGame = create<GameStore>((set, get) => ({
  ...makeInitialState(),

  start: () => {
    set({ ...makeInitialState(), phase: 'playing' });
  },

  reset: () => {
    set({ ...makeInitialState(), phase: 'menu' });
  },

  performAction: (schemeId, actionId) => {
    const state = get();
    if (state.phase !== 'playing') return;
    if (state.actionsLeft <= 0) return;
    if (state.pendingEvent) return;

    const scheme = getScheme(schemeId);
    const action = scheme.actions.find((a) => a.id === actionId);
    if (!action) return;

    if (action.available && !action.available(state)) {
      const reason = action.unavailableReason?.(state) ?? 'Action unavailable.';
      set((s) => ({
        log: [
          makeLogEntry(s.day, 'info', reason),
          ...s.log,
        ].slice(0, 60),
      }));
      return;
    }

    const result = action.perform(state);

    // Compute new state
    const moneyDelta = result.moneyDelta ?? 0;
    const heatDelta = result.heatDelta ?? 0;
    const reputationDelta = result.reputationDelta ?? 0;
    const xpGain = result.xpGain ?? 0;

    const newMoney = state.money + moneyDelta;
    const newHeat = clamp(state.heat + heatDelta, 0, 100);
    const newRep = clamp(state.reputation + reputationDelta, 0, 100);
    const newActionsLeft = state.actionsLeft - action.cost;

    // Update skill XP
    const skill = state.skills[schemeId];
    let newXP = skill.xp + xpGain;
    let newLevel = skill.level;
    while (newXP >= 100 && newLevel < 10) {
      newXP -= 100;
      newLevel += 1;
    }
    if (newLevel >= 10) {
      newXP = 100;
      newLevel = 10;
    }
    const leveledUp = newLevel > skill.level;

    // Update stats
    const newStats = {
      ...state.stats,
      totalEarned: state.stats.totalEarned + (moneyDelta > 0 ? moneyDelta : 0),
      totalLost: state.stats.totalLost + (moneyDelta < 0 ? -moneyDelta : 0),
      dealsClosed: state.stats.dealsClosed + (moneyDelta > 0 ? 1 : 0),
    };

    // Build log entries
    const logEntries: LogEntry[] = [];
    logEntries.push(makeLogEntry(state.day, result.logType, result.logText));
    if (leveledUp) {
      logEntries.push(
        makeLogEntry(
          state.day,
          'success',
          `${scheme.name} skill reached Level ${newLevel}! Better payouts, lower failure rates.`,
        ),
      );
    }

    // Check for win / lose
    let phase: GameState['phase'] = 'playing';
    let loseReason: GameState['loseReason'] = null;
    let extraLog: LogEntry[] = [];

    if (newMoney >= WIN_AMOUNT) {
      phase = 'won';
      extraLog.push(
        makeLogEntry(state.day, 'success', `🎉 $1,000,000 reached. You beat the system.`),
      );
    } else if (newHeat >= 100) {
      phase = 'lost';
      loseReason = 'arrested';
      extraLog.push(
        makeLogEntry(
          state.day,
          'danger',
          `🚔 Heat hit 100. Federal agents kicked in your door at 4 AM. You're going away for a long time.`,
        ),
      );
    } else if (newMoney < -1000) {
      phase = 'lost';
      loseReason = 'bankrupt';
      extraLog.push(
        makeLogEntry(
          state.day,
          'danger',
          `💸 You're $${Math.abs(newMoney)} in the hole. Creditors are calling. There's only one place left to turn... McDonald's.`,
        ),
      );
    }

    // Build the next state patch
    set((s) => {
      const skillsPatch = { ...s.skills };
      skillsPatch[schemeId] = { level: newLevel, xp: newXP };

      const patch: Partial<GameState> = {
        money: newMoney,
        heat: newHeat,
        reputation: newRep,
        actionsLeft: Math.max(0, newActionsLeft),
        skills: skillsPatch,
        stats: newStats,
        phase,
        loseReason,
        taxSetup: result.extra?.taxSetup === true ? true : s.taxSetup,
        log: [...extraLog, ...logEntries, ...s.log].slice(0, 80),
      };
      return patch;
    });

    // If actions ran out, auto-trigger end-of-day event roll after a tiny delay.
    // The endDay function itself checks the action-panel flag, so it's safe.
    if (newActionsLeft <= 0 && phase === 'playing') {
      // Defer end-of-day event roll
      setTimeout(() => {
        // Wait a bit longer if the action panel is still open
        const tryEnd = () => {
          if (isActionPanelOpen()) {
            setTimeout(tryEnd, 400);
          } else {
            get().endDay();
          }
        };
        tryEnd();
      }, 600);
    }
  },

  endDay: () => {
    const state = get();
    if (state.phase !== 'playing') return;
    if (state.pendingEvent) return;
    // Don't auto-advance if the player is inside a building action panel
    // (we use a module-level flag set by the 3D UI to avoid a circular import)
    if (isActionPanelOpen()) return;

    // Roll event first — if one fires, present it; otherwise advance day.
    const event = rollDailyEvent(state);
    if (event) {
      set((s) => ({
        pendingEvent: event,
        log: [
          makeLogEntry(s.day, 'event', `📰 EVENT: ${event.title}`),
          ...s.log,
        ].slice(0, 80),
      }));
      return;
    }

    // No event — advance day
    advanceDay(set, get);
  },

  resolveEvent: (choiceIndex) => {
    const state = get();
    if (!state.pendingEvent) return;
    const choice = state.pendingEvent.choices[choiceIndex];
    if (!choice) return;

    const result = choice.apply(state);
    const event = state.pendingEvent;

    // Apply the patch
    set((s) => {
      const moneyDelta = result.moneyDelta ?? 0;
      const heatDelta = result.heatDelta ?? 0;
      const reputationDelta = result.reputationDelta ?? 0;
      const newMoney = s.money + moneyDelta;
      const newHeat = clamp(s.heat + heatDelta, 0, 100);
      const newRep = clamp(s.reputation + reputationDelta, 0, 100);

      let phase: GameState['phase'] = s.phase;
      let loseReason: GameState['loseReason'] = s.loseReason;

      if (result.phase === 'lost') {
        phase = 'lost';
        loseReason = result.loseReason ?? null;
      } else if (newMoney >= WIN_AMOUNT) {
        phase = 'won';
      } else if (newHeat >= 100) {
        phase = 'lost';
        loseReason = 'arrested';
      } else if (newMoney < -1000) {
        phase = 'lost';
        loseReason = 'bankrupt';
      }

      const logEntries = result.logEntries ?? [];

      return {
        pendingEvent: null,
        money: newMoney,
        heat: newHeat,
        reputation: newRep,
        actionsLeft: result.actionsLeft !== undefined ? result.actionsLeft : s.actionsLeft,
        phase,
        loseReason,
        log: [...logEntries, ...s.log].slice(0, 80),
      };
    });

    // If still playing and no actions left, advance the day
    const updated = get();
    if (updated.phase === 'playing' && updated.actionsLeft <= 0 && !updated.pendingEvent) {
      setTimeout(() => {
        advanceDay(set, get);
      }, 300);
    }
  },

  dismissEvent: () => {
    set({ pendingEvent: null });
  },
}));

// Advances the day: day++, restores actions, decays heat slightly, increments survived days.
function advanceDay(
  set: (fn: (s: GameState) => Partial<GameState>) => void,
  get: () => GameState,
) {
  const state = get();
  if (state.phase !== 'playing') return;

  const newDay = state.day + 1;
  const heatDecay = Math.max(0, 3 - Math.floor(state.heat / 30)); // higher heat decays slower
  const newHeat = clamp(state.heat - heatDecay, 0, 100);

  let phase: GameState['phase'] = 'playing';
  let loseReason: GameState['loseReason'] = null;
  let extraLog: LogEntry[] = [];

  // McDonald's pressure after day cap or running on fumes
  if (newDay > MAX_DAYS && state.money < 50000) {
    phase = 'lost';
    loseReason = 'mcdonalds';
    extraLog.push(
      makeLogEntry(
        newDay,
        'danger',
        `📅 Day ${newDay}. The unemployment money ran out months ago. Mom stopped returning your calls. You finally walked into McDonald's and asked for an application. The dream is over.`,
      ),
    );
  } else {
    extraLog.push(
      makeLogEntry(
        newDay,
        'info',
        `🌅 Day ${newDay}. You slept in. Heat cooled by ${heatDecay}. You've got ${MAX_ACTIONS} moves today.`,
      ),
    );
  }

  set((s) => ({
    day: newDay,
    actionsLeft: MAX_ACTIONS,
    maxActions: MAX_ACTIONS,
    heat: newHeat,
    phase,
    loseReason,
    stats: {
      ...s.stats,
      daysSurvived: newDay,
    },
    log: [...extraLog, ...s.log].slice(0, 80),
  }));
}

export { schemes, WIN_AMOUNT, MAX_ACTIONS, STARTING_MONEY, MAX_DAYS };
