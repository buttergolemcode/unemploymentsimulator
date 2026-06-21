// Unemployment Simulator — Game Types

export type SchemeId =
  | 'ecom'
  | 'trading'
  | 'gambling'
  | 'drugs'
  | 'scam'
  | 'robbery'
  | 'taxfraud'
  | 'wirefraud';

export type SkillId = SchemeId | 'hustle';

export interface SkillState {
  level: number; // 1-10
  xp: number; // 0-100, rolls over into level
}

export interface LogEntry {
  id: string;
  day: number;
  type: 'info' | 'success' | 'danger' | 'money' | 'heat' | 'event';
  text: string;
}

export type GamePhase = 'menu' | 'playing' | 'won' | 'lost';

export type LoseReason = 'mcdonalds' | 'arrested' | 'bankrupt';

export interface StockPrice {
  symbol: string;
  name: string;
  price: number;
  history: number[];
}

export interface GameState {
  // Phase
  phase: GamePhase;
  loseReason: LoseReason | null;

  // Core stats
  money: number;
  day: number;
  actionsLeft: number;
  maxActions: number;
  heat: number; // 0-100 police suspicion
  reputation: number; // 0-100 street cred

  // Skills
  skills: Record<SkillId, SkillState>;

  // Market
  stocks: StockPrice[];
  taxSetup: boolean; // whether tax fraud scheme is set up
  taxAccrued: number; // money waiting to be claimed via tax fraud

  // Stats for end screen
  stats: {
    totalEarned: number;
    totalLost: number;
    dealsClosed: number;
    daysSurvived: number;
  };

  // Log
  log: LogEntry[];

  // Pending event choice (modal)
  pendingEvent: GameEvent | null;
}

export interface GameEventChoice {
  label: string;
  apply: (s: GameState) => Partial<GameState> & { logEntries?: LogEntry[] };
}

export interface GameEvent {
  id: string;
  title: string;
  description: string;
  choices: GameEventChoice[];
}

export interface SchemeAction {
  id: string;
  label: string;
  description: string;
  cost: number; // stamina cost
  // Returns delta patch to apply to state
  perform: (s: GameState) => {
    moneyDelta?: number;
    heatDelta?: number;
    reputationDelta?: number;
    xpGain?: number;
    logText: string;
    logType: LogEntry['type'];
    // Optional sub-result for specialized actions (gambling result etc.)
    extra?: Record<string, unknown>;
  };
  // Whether action is currently available
  available?: (s: GameState) => boolean;
  unavailableReason?: (s: GameState) => string | null;
}
