// Unemployment Simulator — Random Events
import type { GameEvent, GameState } from './types';
import { randInt, chance } from './schemes';

// Events fire probabilistically each day. Returns an event or null.
export function rollDailyEvent(state: GameState): GameEvent | null {
  // 35% chance of an event per day (after the action phase ends)
  if (!chance(0.35)) return null;

  const events = buildEventPool(state);
  if (events.length === 0) return null;
  return events[randInt(0, events.length - 1)];
}

function buildEventPool(state: GameState): GameEvent[] {
  const pool: GameEvent[] = [];

  // ---- HEAT-DRIVEN EVENTS ----
  if (state.heat >= 60) {
    pool.push({
      id: 'raid',
      title: 'Police Raid',
      description:
        'Two unmarked SUVs pulled up outside your apartment at 6 AM. They\'ve got a warrant. Your phone is buzzing with warnings from the crew.',
      choices: [
        {
          label: 'Bolt out the back window',
          apply: () => ({
            heatDelta: -10,
            moneyDelta: -randInt(500, 2000),
            logEntries: [
              {
                id: crypto.randomUUID(),
                day: state.day,
                type: 'event',
                text: `You shimmied down the fire escape with $${randInt(500, 2000)} of product you couldn't grab. Lost the stash but stayed free. Heat dropped 10.`,
              },
            ],
          }),
        },
        {
          label: 'Flush everything and play dumb',
          apply: () => ({
            heatDelta: -20,
            moneyDelta: -randInt(300, 1200),
            logEntries: [
              {
                id: crypto.randomUUID(),
                day: state.day,
                type: 'event',
                text: `You flushed the product down the toilet. Cops found nothing. They left frustrated. Heat dropped 20. Lost $${randInt(300, 1200)} in merch.`,
              },
            ],
          }),
        },
        {
          label: 'Lawyer up and ride it out',
          apply: (s) => {
            const fee = 5000;
            if (s.money >= fee) {
              return {
                moneyDelta: -fee,
                heatDelta: -35,
                logEntries: [
                  {
                    id: crypto.randomUUID(),
                    day: state.day,
                    type: 'event',
                    text: `$${fee} to a slick defense attorney. Charges dropped on a technicality. Heat dropped 35.`,
                  },
                ],
              };
            }
            return {
              heatDelta: -5,
              logEntries: [
                {
                  id: crypto.randomUUID(),
                  day: state.day,
                  type: 'danger',
                  text: `Couldn't afford the $${fee} retainer. Public defender got you ROR but the heat is still on.`,
                },
              ],
            };
          },
        },
      ],
    });
  }

  if (state.heat >= 35 && state.heat < 60) {
    pool.push({
      id: 'witness',
      title: 'A Witness Speaks Up',
      description:
        'A bystander from your last scheme went to the cops. Detectives want to "ask a few questions." Your phone rings — it\'s a 202 number.',
      choices: [
        {
          label: 'Lawyer up. Say nothing.',
          apply: (s) => {
            const fee = 1500;
            if (s.money >= fee) {
              return {
                moneyDelta: -fee,
                heatDelta: -12,
                logEntries: [
                  {
                    id: crypto.randomUUID(),
                    day: state.day,
                    type: 'event',
                    text: `Attorney got the interview cancelled. Heat -12, $${fee} lighter.`,
                  },
                ],
              };
            }
            return {
              heatDelta: 8,
              logEntries: [
                {
                  id: crypto.randomUUID(),
                  day: state.day,
                  type: 'danger',
                  text: `Couldn't afford counsel. You stammered through the interview and contradicted yourself twice. Heat +8.`,
                },
              ],
            };
          },
        },
        {
          label: 'Lay low for the day',
          apply: () => ({
            heatDelta: -8,
            actionsLeft: 0,
            logEntries: [
              {
                id: crypto.randomUUID(),
                day: state.day,
                type: 'event',
                text: `You went dark — turned off your phone, stayed inside. Lost a day of hustle, but the cops moved on. Heat -8.`,
              },
            ],
          }),
        },
      ],
    });
  }

  // ---- McDonald's bailouts (when broke) ----
  if (state.money < 100) {
    pool.push({
      id: 'mcdonalds_offer',
      title: 'McDonald\'s Is Hiring',
      description:
        'Your landlord is threatening eviction. Mom is calling again. There\'s a "NOW HIRING" sign in the McDonald\'s window down the street. The manager says you can start tomorrow.',
      choices: [
        {
          label: 'Take the job. Game over.',
          apply: () => ({
            phase: 'lost' as const,
            loseReason: 'mcdonalds' as const,
            logEntries: [
              {
                id: crypto.randomUUID(),
                day: state.day,
                type: 'danger',
                text: `You put on the uniform. You smell like fries forever. The dream is dead.`,
              },
            ],
          }),
        },
        {
          label: 'Decline. Hustle harder.',
          apply: () => ({
            moneyDelta: 50,
            reputationDelta: 2,
            logEntries: [
              {
                id: crypto.randomUUID(),
                day: state.day,
                type: 'event',
                text: `You told the manager you'd think about it, then sprinted home. Found $50 in a coat pocket. The dream survives — barely.`,
              },
            ],
          }),
        },
      ],
    });
  }

  // ---- LUCKY BREAKS ----
  pool.push({
    id: 'hot_tip',
    title: 'Hot Tip from r/WallStreetBets',
    description:
      'A mod on the Discord just dropped "DD" on a small-cap biotech. FDA approval news leaks tomorrow, allegedly. You can ape in early.',
    choices: [
      {
        label: 'Ape in $2,000',
        apply: (s) => {
          const stake = Math.min(s.money, 2000);
          if (stake < 200) {
            return {
              logEntries: [
                {
                  id: crypto.randomUUID(),
                  day: state.day,
                  type: 'info',
                  text: `You don't have enough to ape in meaningfully. Missed the pump.`,
                },
              ],
            };
          }
          if (chance(0.55)) {
            const win = Math.floor(stake * (1.5 + Math.random() * 2));
            return {
              moneyDelta: win,
              logEntries: [
                {
                  id: crypto.randomUUID(),
                  day: state.day,
                  type: 'money',
                  text: `The DD was real! Stock ripped +${Math.floor(Math.random() * 200 + 50)}%. You walked with +$${win}.`,
                },
              ],
            };
          }
          return {
            moneyDelta: -stake,
            logEntries: [
              {
                id: crypto.randomUUID(),
                day: state.day,
                type: 'danger',
                text: `The "DD" was hopium. Stock dumped -40% premarket. Lost $${stake}.`,
              },
            ],
          };
        },
      },
      {
        label: 'Skip — sounds like a trap',
        apply: () => ({
          logEntries: [
            {
              id: crypto.randomUUID(),
              day: state.day,
              type: 'info',
              text: `You watched from the sidelines. The stock pumped. Then dumped. Either way, your hands are clean.`,
            },
          ],
        }),
      },
    ],
  });

  pool.push({
    id: 'rich_uncle',
    title: 'Uncle Louie Visits',
    description:
      'Your shady uncle Louie is in town. He heard you\'re "between jobs." He slides you an envelope with a wink.',
    choices: [
      {
        label: 'Take the envelope',
        apply: () => {
          const amt = randInt(300, 1200);
          return {
            moneyDelta: amt,
            heatDelta: 2,
            logEntries: [
              {
                id: crypto.randomUUID(),
                day: state.day,
                type: 'money',
                text: `Uncle Louie slipped you $${amt}. "Don't ask where it came from, kid."`,
              },
            ],
          };
        },
      },
      {
        label: 'Politely refuse',
        apply: () => ({
          reputationDelta: 1,
          logEntries: [
            {
              id: crypto.randomUUID(),
              day: state.day,
              type: 'info',
              text: `You told Uncle Louie you're making your own way. He looked proud. Mom will be thrilled.`,
            },
          ],
        }),
      },
    ],
  });

  // ---- CREW / STREET EVENTS ----
  if (state.reputation >= 30) {
    pool.push({
      id: 'crew_offer',
      title: 'A Crew Wants to Hire You',
      description:
        'A local crew has been watching your moves. They\'re offering a steady cut — 20% of all product moved — in exchange for running their supply chain.',
      choices: [
        {
          label: 'Join the crew',
          apply: () => ({
            moneyDelta: randInt(2000, 5000),
            heatDelta: 10,
            reputationDelta: 10,
            logEntries: [
              {
                id: crypto.randomUUID(),
                day: state.day,
                type: 'money',
                text: `You shook on it. Signing bonus cleared, and the crew\'s got your back now. But so does their heat.`,
              },
            ],
          }),
        },
        {
          label: 'Stay solo',
          apply: () => ({
            reputationDelta: 3,
            logEntries: [
              {
                id: crypto.randomUUID(),
                day: state.day,
                type: 'info',
                text: `You told them you fly alone. They respected it. Word got around — you\'re your own man.`,
              },
            ],
          }),
        },
      ],
    });
  }

  if (state.reputation >= 20) {
    pool.push({
      id: 'snitch',
      title: 'Someone\'s Snitching',
      description:
        'Your boy Trey says a CI has been feeding info to the feds. The crew is paranoid. You\'ve got a name.',
      choices: [
        {
          label: 'Confront the snitch',
          apply: () => {
            if (chance(0.5)) {
              return {
                heatDelta: -15,
                reputationDelta: 8,
                logEntries: [
                  {
                    id: crypto.randomUUID(),
                    day: state.day,
                    type: 'event',
                    text: `You cornered the snitch. He promised to feed the cops garbage from now on. Heat -15, rep +8.`,
                  },
                ],
              };
            }
            return {
              heatDelta: 10,
              reputationDelta: -5,
              logEntries: [
                {
                  id: crypto.randomUUID(),
                  day: state.day,
                  type: 'danger',
                  text: `The "snitch" was a real friend. Now the crew thinks YOU'RE the rat. Heat +10, rep -5.`,
                },
              ],
            };
          },
        },
        {
          label: 'Just lay low',
          apply: () => ({
            heatDelta: -5,
            logEntries: [
              {
                id: crypto.randomUUID(),
                day: state.day,
                type: 'event',
                text: `You went quiet for a few days. Whatever it was blew over. Heat -5.`,
              },
            ],
          }),
        },
      ],
    });
  }

  // ---- DRUG SHORTAGE / GLUT ----
  if (state.skills.drugs.level >= 2) {
    pool.push({
      id: 'drug_drought',
      title: 'Citywide Weed Drought',
      description:
        'A major bust dried up the city\'s supply. Your plug is out. Prices are 4x normal. You\'ve got a small stash left.',
      choices: [
        {
          label: 'Sell the stash at a premium',
          apply: (s) => {
            const profit = randInt(1500, 4000);
            return {
              moneyDelta: profit,
              heatDelta: 8,
              logEntries: [
                {
                  id: crypto.randomUUID(),
                  day: state.day,
                  type: 'money',
                  text: `You scalped your last 2 ounces for +$${profit}. Desperate customers, easy marks.`,
                },
              ],
            };
          },
        },
        {
          label: 'Hold the stash — wait for the market',
          apply: () => ({
            logEntries: [
              {
                id: crypto.randomUUID(),
                day: state.day,
                type: 'info',
                text: `You sat on the stash. Prices normalized in a week. Modest profit later, no extra heat.`,
              },
            ],
          }),
        },
      ],
    });
  }

  // ---- IRS ----
  if (state.taxSetup) {
    pool.push({
      id: 'irs_audit',
      title: 'IRS Audit Notice',
      description:
        'A letter from the IRS arrived. "Your 2024 return has been selected for examination." Your "creative accountant" is suddenly unreachable.',
      choices: [
        {
          label: 'Hire a real tax attorney ($8,000)',
          apply: (s) => {
            if (s.money >= 8000) {
              return {
                moneyDelta: -8000,
                heatDelta: -20,
                logEntries: [
                  {
                    id: crypto.randomUUID(),
                    day: state.day,
                    type: 'event',
                    text: `The attorney stalled, settled for pennies on the dollar. The audit is closed. Heat -20, $8k gone.`,
                  },
                ],
              };
            }
            return {
              heatDelta: 25,
              logEntries: [
                {
                  id: crypto.randomUUID(),
                  day: state.day,
                  type: 'danger',
                  text: `Couldn't afford the attorney. You represent yourself and incriminate yourself. Heat +25. Criminal referral incoming.`,
                },
              ],
            };
          },
        },
        {
          label: 'Skip town for a few weeks',
          apply: () => ({
            heatDelta: -10,
            actionsLeft: 0,
            logEntries: [
              {
                id: crypto.randomUUID(),
                day: state.day,
                type: 'event',
                text: `You took a bus to your cousin\'s place in another state. Audit notice went unanswered. Heat -10 but you lost a day.`,
              },
            ],
          }),
        },
      ],
    });
  }

  // ---- FAMILY / LIFE ----
  pool.push({
    id: 'mom_call',
    title: 'Mom Needs $500',
    description:
      'Mom called. Her car broke down. She\'s crying. She doesn\'t know what you\'re up to — she thinks you\'re "between jobs."',
    choices: [
      {
        label: 'Send the $500',
        apply: (s) => {
          if (s.money >= 500) {
            return {
              moneyDelta: -500,
              heatDelta: -3,
              logEntries: [
                {
                  id: crypto.randomUUID(),
                  day: state.day,
                  type: 'event',
                  text: `You sent the money. Mom said she\'s proud of you. You felt something. Heat -3.`,
                },
              ],
            };
          }
          return {
            reputationDelta: -2,
            logEntries: [
              {
                id: crypto.randomUUID(),
                day: state.day,
                type: 'danger',
                text: `You had to tell her you couldn\'t. She hung up. Rep -2.`,
              },
            ],
          };
        },
      },
      {
        label: 'Pretend you didn\'t see the call',
        apply: () => ({
          reputationDelta: -1,
          logEntries: [
            {
              id: crypto.randomUUID(),
              day: state.day,
              type: 'info',
              text: `You let it go to voicemail. Again. The guilt is a small price to pay for the dream.`,
            },
          ],
        }),
      },
    ],
  });

  pool.push({
    id: 'mugging',
    title: 'You Got Mugged',
    description:
      'Walking home from a deal, two guys jumped you in an alley. They got your wallet and your phone. Your cash is gone.',
    choices: [
      {
        label: 'Take the loss',
        apply: (s) => {
          const lost = Math.min(s.money, randInt(200, 800));
          return {
            moneyDelta: -lost,
            logEntries: [
              {
                id: crypto.randomUUID(),
                day: state.day,
                type: 'danger',
                text: `They took $${lost} and your cracked iPhone 11. You walked home fuming.`,
              },
            ],
          };
        },
      },
      {
        label: 'Fight back',
        apply: (s) => {
          if (chance(0.35 + s.skills.robbery.level * 0.04)) {
            const kept = randInt(500, 1500);
            return {
              moneyDelta: kept,
              heatDelta: 4,
              reputationDelta: 3,
              logEntries: [
                {
                  id: crypto.randomUUID(),
                  day: state.day,
                  type: 'money',
                  text: `You dropped the bigger one with a liver shot. They ran. You picked up the cash they dropped: +$${kept}.`,
                },
              ],
            };
          }
          const lost = Math.min(s.money, randInt(400, 1500));
          return {
            moneyDelta: -lost,
            heatDelta: 8,
            logEntries: [
              {
                id: crypto.randomUUID(),
                day: state.day,
                type: 'danger',
                text: `They beat the brakes off you. Hospital bill will come later. Lost $${lost}.`,
              },
            ],
          };
        },
      },
    ],
  });

  return pool;
}
