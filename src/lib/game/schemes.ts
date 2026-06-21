// Unemployment Simulator — Money-Making Schemes
import type { SchemeAction, SchemeId, GameState } from './types';

// ---------- Helpers ----------
function randInt(min: number, max: number) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function chance(p: number) {
  return Math.random() < p;
}

// ====================================================================
// E-COM — Dropshipping / flipping
// Low risk, low-medium reward, low heat
// ====================================================================
export const ecomActions: SchemeAction[] = [
  {
    id: 'flip_finds',
    label: 'Flip Thrift Finds',
    description:
      'Hit up local Goodwills and estate sales, then list finds on eBay. Risky but legal-ish.',
    cost: 1,
    perform: (s) => {
      const skill = s.skills.ecom.level;
      const profit = randInt(40, 180) * skill;
      const caught = chance(0.05);
      if (caught) {
        return {
          moneyDelta: -randInt(20, 80),
          heatDelta: 1,
          xpGain: 8,
          logText: `Bought a "vintage" vase that turned out to be a reproduction. Lost some cash on shipping.`,
          logType: 'danger',
        };
      }
      return {
        moneyDelta: profit,
        xpGain: 10,
        logText: `Flipped a thrift-store jacket for $${profit}. Vintage tag did the heavy lifting.`,
        logType: 'money',
      };
    },
  },
  {
    id: 'dropship_batch',
    label: 'Run Dropship Batch',
    description:
      'Order cheap gadgets from AliExpress, mark up 4x with a slick Shopify store. The American Dream.',
    cost: 2,
    perform: (s) => {
      const skill = s.skills.ecom.level;
      const base = randInt(120, 400) * skill;
      const chargebacks = chance(0.12);
      if (chargebacks) {
        const lost = randInt(80, 200);
        return {
          moneyDelta: -lost,
          heatDelta: 2,
          xpGain: 12,
          logText: `Wave of chargebacks hit your store — PayPal froze $${lost} for 6 months.`,
          logType: 'danger',
        };
      }
      return {
        moneyDelta: base,
        xpGain: 15,
        logText: `Sold 12 units of "ergonomic toe-stretchers" at 4x markup. Net: $${base}.`,
        logType: 'money',
      };
    },
  },
  {
    id: 'review_farm',
    label: 'Run Review Farm',
    description:
      'Pay offshore workers $1 each to leave 5-star reviews. Slightly illegal, slightly profitable.',
    cost: 2,
    perform: (s) => {
      const skill = s.skills.ecom.level;
      const profit = randInt(150, 500) * skill;
      const busted = chance(0.18);
      if (busted) {
        return {
          moneyDelta: -randInt(50, 150),
          heatDelta: 8,
          xpGain: 6,
          logText: `Amazon flagged your listing for "suspicious review activity." Store suspended.`,
          logType: 'danger',
        };
      }
      return {
        moneyDelta: profit,
        heatDelta: 2,
        xpGain: 12,
        logText: `Reviews boosted your conversion rate. Cleared $${profit} this batch.`,
        logType: 'money',
      };
    },
  },
];

// ====================================================================
// TRADING — Day trading stocks
// Medium risk (your own money), zero legal heat
// ====================================================================
export const tradingActions: SchemeAction[] = [
  {
    id: 'daytrade_meme',
    label: 'Yolo on Meme Stock',
    description: 'Put it all on $PEPE or $ROPE. The pros on WallStreetBets have never led you astray.',
    cost: 1,
    perform: (s) => {
      const skill = s.skills.trading.level;
      const roll = Math.random();
      let delta: number;
      let text: string;
      if (roll < 0.4) {
        delta = -randInt(80, 300);
        text = `Meme stock cratered -${Math.abs(delta)}%. Reddit says "diamond hands." You sold at the bottom.`;
      } else if (roll < 0.7) {
        delta = randInt(50, 200) * skill;
        text = `Caught a +${randInt(5, 20)}% pump. Out at +$${delta}.`;
      } else if (roll < 0.92) {
        delta = randInt(150, 600) * skill;
        text = `Earnings beat, IV crush didn't crush you. +$${delta}.`;
      } else {
        delta = randInt(800, 2500) * skill;
        text = `🚀 You caught the bottom of a 3x runner. +$${delta}.tendies secured.`;
      }
      return {
        moneyDelta: delta,
        xpGain: 12,
        logText: text,
        logType: delta >= 0 ? 'money' : 'danger',
      };
    },
  },
  {
    id: 'options_play',
    label: '0DTE Options Gamble',
    description: 'Buy same-day-expiry call options. Either 10x or zero. Mostly zero.',
    cost: 1,
    perform: (s) => {
      const skill = s.skills.trading.level;
      const stake = Math.min(s.money, 200 + skill * 50);
      const win = chance(0.32 + skill * 0.015);
      if (win) {
        const profit = Math.floor(stake * (1.5 + Math.random() * 4));
        return {
          moneyDelta: profit,
          xpGain: 15,
          logText: `0DTE printed. $${stake} in, $${profit} out. The Greeks were on your side today.`,
          logType: 'money',
        };
      }
      return {
        moneyDelta: -stake,
        xpGain: 8,
        logText: `0DTE went to zero. Theta gang ate $${stake}. You held to expiry like a moron.`,
        logType: 'danger',
      };
    },
  },
  {
    id: 'pump_dump',
    label: 'Pump & Dump Microcap',
    description: 'Buy illiquid penny stock, hype it in Discord, dump on the bagholders. SEC may notice.',
    cost: 2,
    perform: (s) => {
      const skill = s.skills.trading.level;
      const profit = randInt(400, 1500) * skill;
      const sec = chance(0.22);
      if (sec) {
        return {
          moneyDelta: -randInt(200, 800),
          heatDelta: 15,
          xpGain: 5,
          logText: `SEC opened an informal inquiry. Your broker froze the account and clawed back $${randInt(200, 800)}.`,
          logType: 'danger',
        };
      }
      return {
        moneyDelta: profit,
        heatDelta: 4,
        xpGain: 18,
        logText: `Hyped $ZZZZ on the Discord. Bagholders bought your bags for +$${profit}.`,
        logType: 'money',
      };
    },
  },
];

// ====================================================================
// GAMBLING — Casino
// Pure RNG, high variance, low heat (legal)
// ====================================================================
function rouletteSpin() {
  // European roulette, single zero. Bet on red/black for ~48.6% win.
  const spin = randInt(0, 36);
  const isRed = spin !== 0 && [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36].includes(spin);
  return { spin, isRed };
}

export const gamblingActions: SchemeAction[] = [
  {
    id: 'slots',
    label: 'Slot Machine',
    description: 'Pull the lever. Mostly lose, sometimes win small, rarely jackpot.',
    cost: 1,
    perform: () => {
      const roll = Math.random();
      if (roll < 0.6) {
        return {
          moneyDelta: -50,
          xpGain: 4,
          logText: `Slots ate your $50. The lights are pretty, though.`,
          logType: 'danger',
        };
      } else if (roll < 0.9) {
        const win = randInt(80, 250);
        return {
          moneyDelta: win,
          xpGain: 6,
          logText: `Three cherries! +$${win}. Tip the dealer $5, walk away.`,
          logType: 'money',
        };
      } else if (roll < 0.99) {
        const win = randInt(800, 2500);
        return {
          moneyDelta: win,
          xpGain: 10,
          logText: `MINOR JACKPOT! +$${win}. Floor manager is watching.`,
          logType: 'money',
        };
      } else {
        const win = randInt(15000, 50000);
        return {
          moneyDelta: win,
          xpGain: 20,
          logText: `MEGA JACKPOT! +$${win}! Sirens, champagne, the works. You tip the dealer $500.`,
          logType: 'money',
        };
      }
    },
  },
  {
    id: 'roulette_red',
    label: 'Roulette — Bet Red',
    description: 'Bet $500 on red. Pays 1:1. 48.6% to win (single zero).',
    cost: 1,
    perform: (s) => {
      const stake = Math.min(s.money, 500);
      const { spin, isRed } = rouletteSpin();
      if (isRed) {
        return {
          moneyDelta: stake,
          xpGain: 6,
          logText: `Spin landed ${spin} (RED). +$${stake}.`,
          logType: 'money',
        };
      }
      return {
        moneyDelta: -stake,
        xpGain: 4,
        logText: `Spin landed ${spin === 0 ? '0 GREEN' : `${spin} BLACK`}. Lost $${stake}.`,
        logType: 'danger',
      };
    },
  },
  {
    id: 'roulette_number',
    label: 'Roulette — Bet Single Number',
    description: 'Bet $100 on a single number. Pays 35:1. 2.7% to win.',
    cost: 1,
    perform: (s) => {
      const stake = Math.min(s.money, 100);
      const target = randInt(1, 36);
      const spin = randInt(0, 36);
      if (spin === target) {
        const win = stake * 35;
        return {
          moneyDelta: win,
          xpGain: 12,
          logText: `Number ${target} HIT! Paid 35:1 — you walked with +$${win}.`,
          logType: 'money',
        };
      }
      return {
        moneyDelta: -stake,
        xpGain: 4,
        logText: `Bet on ${target}, landed ${spin}. Lost $${stake}.`,
        logType: 'danger',
      };
    },
  },
  {
    id: 'blackjack_count',
    label: 'Count Cards at Blackjack',
    description: 'Sit at the $100-min table and count. Edge is real, but if pit boss notices...',
    cost: 2,
    perform: (s) => {
      const skill = s.skills.gambling.level;
      const winRate = 0.5 + skill * 0.025;
      const win = chance(winRate);
      const caught = chance(0.18);
      if (caught) {
        return {
          moneyDelta: -randInt(200, 600),
          heatDelta: 6,
          xpGain: 5,
          logText: `Pit boss tapped your shoulder. "Sir, you're no longer welcome here." Walked out minus $${randInt(200, 600)} in un-cashed chips.`,
          logType: 'danger',
        };
      }
      if (win) {
        const profit = randInt(200, 800) * skill;
        return {
          moneyDelta: profit,
          xpGain: 12,
          logText: `Counting paid off. +$${profit} across 4 shoes.`,
          logType: 'money',
        };
      }
      return {
        moneyDelta: -randInt(150, 500),
        xpGain: 8,
        logText: `Count was off — bad shoe. -$${randInt(150, 500)}.`,
        logType: 'danger',
      };
    },
  },
];

// ====================================================================
// DRUGS — Selling narcotics
// High heat, high reward, scales with reputation
// ====================================================================
export const drugsActions: SchemeAction[] = [
  {
    id: 'slang_bud',
    label: 'Slang a Bag of Bud',
    description: 'Low-stakes weed deals. $50 profit each, low heat, builds street cred.',
    cost: 1,
    perform: (s) => {
      const skill = s.skills.drugs.level;
      const profit = randInt(40, 90) * skill;
      const snitch = chance(0.07);
      if (snitch) {
        return {
          moneyDelta: 0,
          heatDelta: 6,
          reputationDelta: -2,
          xpGain: 4,
          logText: `Buyer ghosted and you caught a weird vibe. Might've been a CI.`,
          logType: 'heat',
        };
      }
      return {
        moneyDelta: profit,
        heatDelta: 2,
        reputationDelta: 1,
        xpGain: 10,
        logText: `Sold an eighth to a regular for $${profit}. Word of mouth is good.`,
        logType: 'money',
      };
    },
  },
  {
    id: 'flip_pills',
    label: 'Flip a Bottle of Pills',
    description: 'Move a bottle of prescription painkillers. Higher profit, higher heat.',
    cost: 1,
    perform: (s) => {
      const skill = s.skills.drugs.level;
      const profit = randInt(300, 800) * skill;
      const caught = chance(0.14);
      if (caught) {
        return {
          moneyDelta: -randInt(100, 400),
          heatDelta: 14,
          xpGain: 6,
          logText: `Buyer was wearing a wire. You bolted but lost the product ($${randInt(100, 400)}).`,
          logType: 'danger',
        };
      }
      return {
        moneyDelta: profit,
        heatDelta: 6,
        reputationDelta: 2,
        xpGain: 12,
        logText: `Moved a bottle of blues for $${profit}. Repeat customer incoming.`,
        logType: 'money',
      };
    },
  },
  {
    id: 'supply_run',
    label: 'Pick Up from the Plug',
    description: 'Drive 2 hours to the wholesale plug. Big risk, big supply drop, big heat.',
    cost: 2,
    perform: (s) => {
      const skill = s.skills.drugs.level;
      const profit = randInt(1500, 4000) * skill;
      const pulled = chance(0.2);
      if (pulled) {
        // Maybe let them bribe if they have cash?
        const bribe = randInt(300, 800);
        if (s.money > bribe + 200 && chance(0.7)) {
          return {
            moneyDelta: -bribe,
            heatDelta: 8,
            xpGain: 8,
            logText: `Highway patrol pulled you over. Slipped the officer $${bribe} and walked. Sweating bullets.`,
            logType: 'heat',
          };
        }
        return {
          moneyDelta: -randInt(500, 1500),
          heatDelta: 30,
          xpGain: 4,
          logText: `Got pulled over with product in the trunk. Couldn't talk your way out. Lost the stash and a badge knows your face.`,
          logType: 'danger',
        };
      }
      return {
        moneyDelta: profit,
        heatDelta: 8,
        reputationDelta: 5,
        xpGain: 20,
        logText: `Plug hooked you up. Flipped the whole zip in a day for +$${profit}.`,
        logType: 'money',
      };
    },
  },
];

// ====================================================================
// SCAM — Phishing, pig butchering, romance scams
// Medium heat, medium-high reward
// ====================================================================
export const scamActions: SchemeAction[] = [
  {
    id: 'phish_emails',
    label: 'Send Phishing Emails',
    description: 'Blast 10k fake "Netflix" emails. ~0.3% click rate, ~$20 per victim.',
    cost: 1,
    perform: (s) => {
      const skill = s.skills.scam.level;
      const caught = chance(0.1);
      if (caught) {
        return {
          moneyDelta: 0,
          heatDelta: 5,
          xpGain: 5,
          logText: `Email provider flagged the domain. Have to start the funnel over.`,
          logType: 'heat',
        };
      }
      const profit = randInt(80, 250) * skill;
      return {
        moneyDelta: profit,
        heatDelta: 2,
        xpGain: 10,
        logText: `Got ${randInt(3, 9)} victims to log into your fake portal. Net: +$${profit}.`,
        logType: 'money',
      };
    },
  },
  {
    id: 'romance_scam',
    label: 'Run a Romance Scam',
    description: 'Catfish a lonely boomer for 2 weeks. Sometimes they send gift cards.',
    cost: 2,
    perform: (s) => {
      const skill = s.skills.scam.level;
      const caught = chance(0.18);
      if (caught) {
        return {
          moneyDelta: 0,
          heatDelta: 8,
          reputationDelta: -1,
          xpGain: 4,
          logText: `Target's grandkid reverse-image-searched your pics. They filed an IC3 complaint.`,
          logType: 'heat',
        };
      }
      const profit = randInt(300, 1200) * skill;
      return {
        moneyDelta: profit,
        heatDelta: 4,
        xpGain: 14,
        logText: `"Margaret" sent $${profit} in Apple gift cards for "her grandson's bail." You feel nothing.`,
        logType: 'money',
      };
    },
  },
  {
    id: 'pig_butchering',
    label: 'Pig-Butchering Scheme',
    description: 'Weeks of "crypto investment" grooming. Big payoff, but FBI loves these.',
    cost: 2,
    perform: (s) => {
      const skill = s.skills.scam.level;
      const caught = chance(0.28);
      if (caught) {
        return {
          moneyDelta: -randInt(100, 500),
          heatDelta: 18,
          xpGain: 6,
          logText: `Target reported to FBI IC3. They're pulling chat logs from Telegram.`,
          logType: 'danger',
        };
      }
      const profit = randInt(2500, 8000) * skill;
      return {
        moneyDelta: profit,
        heatDelta: 8,
        reputationDelta: 3,
        xpGain: 22,
        logText: `"Daniel" withdrew his "crypto gains" — straight to your wallet. +$${profit}. You monster.`,
        logType: 'money',
      };
    },
  },
];

// ====================================================================
// ROBBERY — Mugging, burglary, armed robbery
// Very high heat, very high reward, can end run instantly
// ====================================================================
export const robberyActions: SchemeAction[] = [
  {
    id: 'snatch_phone',
    label: 'Snatch a Phone',
    description: 'Grab a tourist\'s iPhone off a cafe table. Quick $200, low heat.',
    cost: 1,
    perform: (s) => {
      const skill = s.skills.robbery.level;
      const caught = chance(0.15);
      if (caught) {
        return {
          moneyDelta: 0,
          heatDelta: 12,
          xpGain: 4,
          logText: `Tourist chased you down. Bystander filmed it. Cops have your face on CCTV.`,
          logType: 'danger',
        };
      }
      const profit = randInt(100, 350) * skill;
      return {
        moneyDelta: profit,
        heatDelta: 4,
        reputationDelta: 1,
        xpGain: 10,
        logText: `Snatched an iPhone 15 Pro, fenced for $${profit}. Tourist is crying on Yelp.`,
        logType: 'money',
      };
    },
  },
  {
    id: 'burglary',
    label: 'Burglarize a House',
    description: 'Casing a suburban home — owner is on a 2-week vacation. Bigger score, bigger heat.',
    cost: 2,
    perform: (s) => {
      const skill = s.skills.robbery.level;
      const caught = chance(0.22);
      if (caught) {
        return {
          moneyDelta: -randInt(100, 300),
          heatDelta: 25,
          xpGain: 6,
          logText: `Neighbor's Ring camera caught your face. Cops matched it to a database. You're a person of interest now.`,
          logType: 'danger',
        };
      }
      const profit = randInt(1500, 5000) * skill;
      return {
        moneyDelta: profit,
        heatDelta: 10,
        reputationDelta: 4,
        xpGain: 18,
        logText: `Jewelry, electronics, cash in a sock drawer. Fenced for +$${profit}.`,
        logType: 'money',
      };
    },
  },
  {
    id: 'armed_robbery',
    label: 'Arm-Rob a Corner Store',
    description: 'Mask up, walk in with a (replica) Glock. $5-15k score, but if the heat finds you, you\'re done.',
    cost: 3,
    perform: (s) => {
      const skill = s.skills.robbery.level;
      const caught = chance(0.35);
      if (caught) {
        return {
          moneyDelta: 0,
          heatDelta: 50,
          xpGain: 4,
          logText: `Clerk hit the silent alarm. Cops were 90 seconds out. You escaped but they got your plates.`,
          logType: 'danger',
        };
      }
      const profit = randInt(4000, 14000) * skill;
      return {
        moneyDelta: profit,
        heatDelta: 18,
        reputationDelta: 8,
        xpGain: 25,
        logText: `Walked out with $${profit} in small bills. Clerk will be telling this story for years.`,
        logType: 'money',
      };
    },
  },
];

// ====================================================================
// TAX FRAUD — Fake dependents, fake deductions
// Setup cost, then passive income. Big audit risk.
// ====================================================================
export const taxfraudActions: SchemeAction[] = [
  {
    id: 'setup_tax_fraud',
    label: 'Set Up Fake Tax Return Scheme',
    description: 'Fabricate 12 dependents and $80k of fake business expenses. One-time setup. Then passive refunds.',
    cost: 3,
    perform: (s) => {
      if (s.taxSetup) {
        return {
          logText: 'You\'ve already set up the tax fraud scheme. Run "Harvest Refund" instead.',
          logType: 'info',
        };
      }
      return {
        moneyDelta: -300,
        heatDelta: 4,
        xpGain: 15,
        logText: `Hired a "creative accountant" off Craigslist. $300 fee. He set up 4 shell LLCs and a fake daycare business. Refunds will accrue.`,
        logType: 'info',
        extra: { taxSetup: true },
      };
    },
    available: (s) => !s.taxSetup,
  },
  {
    id: 'harvest_refund',
    label: 'Harvest Tax Refund',
    description: 'File another batch of fraudulent returns. $1-3k per filing. Heat climbs slowly.',
    cost: 1,
    perform: (s) => {
      if (!s.taxSetup) {
        return {
          logText: 'You need to set up the tax fraud scheme first.',
          logType: 'info',
        };
      }
      const skill = s.skills.taxfraud.level;
      const profit = randInt(1000, 3500) * skill;
      const audit = chance(0.1);
      if (audit) {
        return {
          moneyDelta: -randInt(500, 2000),
          heatDelta: 20,
          xpGain: 6,
          logText: `IRS flagged your batch for audit. You stalled but lost $${randInt(500, 2000)} in "fees" to your accountant.`,
          logType: 'danger',
        };
      }
      return {
        moneyDelta: profit,
        heatDelta: 3,
        xpGain: 12,
        logText: `Filed 4 fake returns. Treasury deposited $${profit}. Suck it, Uncle Sam.`,
        logType: 'money',
      };
    },
    available: (s) => s.taxSetup,
    unavailableReason: (s) => (s.taxSetup ? null : 'Set up the scheme first.'),
  },
];

// ====================================================================
// WIRE FRAUD — Business email compromise, fake invoices
// Medium-high heat, very high reward
// ====================================================================
export const wirefraudActions: SchemeAction[] = [
  {
    id: 'fake_invoice',
    label: 'Send Fake Vendor Invoice',
    description: 'Spoof a real vendor\'s email, send a $15k "past due" invoice to a mid-sized company.',
    cost: 2,
    perform: (s) => {
      const skill = s.skills.wirefraud.level;
      const caught = chance(0.22);
      if (caught) {
        return {
          moneyDelta: 0,
          heatDelta: 15,
          xpGain: 5,
          logText: `AP clerk at the target called the real vendor to verify. FBI Cyber Division now has your wire info.`,
          logType: 'danger',
        };
      }
      const profit = randInt(8000, 22000) * skill;
      return {
        moneyDelta: profit,
        heatDelta: 6,
        reputationDelta: 3,
        xpGain: 20,
        logText: `AP paid the fake invoice without checking. +$${profit} hit your mule account.`,
        logType: 'money',
      };
    },
  },
  {
    id: 'ceo_fraud',
    label: 'CEO Impersonation Wire',
    description: 'Spoof a CEO\'s email, pressure the CFO into wiring $50-150k "for an acquisition."',
    cost: 3,
    perform: (s) => {
      const skill = s.skills.wirefraud.level;
      const caught = chance(0.38);
      if (caught) {
        return {
          moneyDelta: 0,
          heatDelta: 30,
          xpGain: 4,
          logText: `CFO smelled something off, called the CEO directly. Secret Service opened a file.`,
          logType: 'danger',
        };
      }
      const profit = randInt(40000, 130000) * skill;
      return {
        moneyDelta: profit,
        heatDelta: 12,
        reputationDelta: 6,
        xpGain: 30,
        logText: `CFO wired $${profit} for the "urgent acquisition." Money is now bouncing through 4 countries.`,
        logType: 'money',
      };
    },
  },
];

// ====================================================================
// All schemes aggregated
// ====================================================================
export interface Scheme {
  id: SchemeId;
  name: string;
  tagline: string;
  description: string;
  emoji: string;
  heatRisk: 'low' | 'medium' | 'high' | 'extreme';
  rewardRange: string;
  actions: SchemeAction[];
}

export const schemes: Scheme[] = [
  {
    id: 'ecom',
    name: 'E-Com',
    tagline: 'Capitalism, but legal-ish',
    description: 'Flip thrift finds, dropship garbage, run review farms. The respectable face of hustle culture. Low heat, slow money.',
    emoji: '📦',
    heatRisk: 'low',
    rewardRange: '$40 - $2,500',
    actions: ecomActions,
  },
  {
    id: 'trading',
    name: 'Day Trading',
    tagline: 'Stock market casino',
    description: 'Yolo your savings on meme stocks, 0DTE options, and pump-and-dumps. Zero legal heat but you can lose everything in 5 minutes.',
    emoji: '📈',
    heatRisk: 'low',
    rewardRange: '$50 - $15,000',
    actions: tradingActions,
  },
  {
    id: 'gambling',
    name: 'Gambling',
    tagline: 'The original side hustle',
    description: 'Slots, roulette, blackjack with card counting. Legal, but high variance and the casino will 86 you if you win too much.',
    emoji: '🎰',
    heatRisk: 'low',
    rewardRange: '-$500 to +$50,000',
    actions: gamblingActions,
  },
  {
    id: 'drugs',
    name: 'Selling Drugs',
    tagline: 'Old reliable',
    description: 'Slang weed, flip pills, run supply from the plug. Scales with street reputation. Heat builds fast, snitches are everywhere.',
    emoji: '💊',
    heatRisk: 'high',
    rewardRange: '$40 - $4,000',
    actions: drugsActions,
  },
  {
    id: 'scam',
    name: 'Scamming',
    tagline: 'The internet is your mark',
    description: 'Phishing, romance scams, pig-butchering. The FBI loves these, but the money is excellent and the victims rarely fight back.',
    emoji: '🎣',
    heatRisk: 'medium',
    rewardRange: '$80 - $8,000',
    actions: scamActions,
  },
  {
    id: 'robbery',
    name: 'Robbing',
    tagline: 'High risk, high reward, high adrenaline',
    description: 'Snatch phones, burgle houses, arm-rob corner stores. Highest payouts in the game but one wrong move and the heat ends your run.',
    emoji: '🔫',
    heatRisk: 'extreme',
    rewardRange: '$100 - $14,000',
    actions: robberyActions,
  },
  {
    id: 'taxfraud',
    name: 'Tax Fraud',
    tagline: 'Sticking it to the IRS',
    description: 'Fabricate dependents, fake business losses, milk refundable credits. Setup fee, then passive income. Audits are scary.',
    emoji: '🧾',
    heatRisk: 'medium',
    rewardRange: '$1,000 - $3,500 / filing',
    actions: taxfraudActions,
  },
  {
    id: 'wirefraud',
    name: 'Wire Fraud',
    tagline: 'Corporate treasury, your treasury',
    description: 'Fake vendor invoices, CEO impersonation wires. Big-tech-company money, big-tech-company risk. Secret Service gets involved.',
    emoji: '💸',
    heatRisk: 'high',
    rewardRange: '$8,000 - $130,000',
    actions: wirefraudActions,
  },
];

export function getScheme(id: SchemeId): Scheme {
  return schemes.find((s) => s.id === id)!;
}

export { randInt, chance };
