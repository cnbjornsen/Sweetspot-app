export type QuoteMood = 'encouraging' | 'cautionary' | 'fanfare' | 'stat' | 'onboarding';

interface Quote {
  id: string;
  text: string;
  mood: QuoteMood;
  weight?: number;
}

const QUOTES: Quote[] = [
  { id: 'on-1', text: "Welcome to Sweet Spot. Let's find your zone.", mood: 'onboarding' },
  { id: 'on-2', text: 'The sweet spot is the buzz before the regret.', mood: 'onboarding' },

  { id: 'en-1', text: "You're nailing it. Keep the rhythm.", mood: 'encouraging', weight: 2 },
  { id: 'en-2', text: 'Sip, don\'t gulp.', mood: 'encouraging', weight: 2 },
  { id: 'en-3', text: 'Hydration is a power move. 💧', mood: 'encouraging', weight: 2 },
  { id: 'en-4', text: 'Slow and steady wins the night.', mood: 'encouraging' },
  { id: 'en-5', text: 'Pace = poise.', mood: 'encouraging' },
  { id: 'en-6', text: "You're in the band. Stay there.", mood: 'encouraging', weight: 2 },
  { id: 'en-7', text: 'Future-you is sending love.', mood: 'encouraging' },
  { id: 'en-8', text: 'Look at you, being a grown-up about it.', mood: 'encouraging' },
  { id: 'en-9', text: 'Tonight is going to be a good one.', mood: 'encouraging' },
  { id: 'en-10', text: 'Smooth sailing.', mood: 'encouraging' },
  { id: 'en-11', text: 'Every minute in the band is a win.', mood: 'encouraging' },
  { id: 'en-12', text: 'You came here to enjoy it, not survive it.', mood: 'encouraging' },

  { id: 'cau-1', text: 'Be honest — your morning self will thank you.', mood: 'cautionary', weight: 2 },
  { id: 'cau-2', text: 'Did anything sneak in? It\'s ok, just log it.', mood: 'cautionary', weight: 2 },
  { id: 'cau-3', text: 'Hangovers compound. So does honesty.', mood: 'cautionary' },
  { id: 'cau-4', text: 'Counting to one is harder than it looks.', mood: 'cautionary' },
  { id: 'cau-5', text: 'A glass of water now buys two hours later.', mood: 'cautionary', weight: 2 },
  { id: 'cau-6', text: 'Tell the truth. The math has receipts.', mood: 'cautionary' },
  { id: 'cau-7', text: 'Not driving tonight, right? Right.', mood: 'cautionary', weight: 2 },

  { id: 'fan-1', text: 'Cheers! Time for the next one. 🎉', mood: 'fanfare', weight: 2 },
  { id: 'fan-2', text: 'Confetti time. You earned it.', mood: 'fanfare', weight: 2 },
  { id: 'fan-3', text: 'Ding ding ding. 🍻', mood: 'fanfare' },
  { id: 'fan-4', text: 'Sweet spot delivery, hot and fresh.', mood: 'fanfare' },
  { id: 'fan-5', text: 'Permission granted. Sip responsibly.', mood: 'fanfare', weight: 2 },
  { id: 'fan-6', text: '🥂 Right on schedule.', mood: 'fanfare', weight: 2 },

  { id: 'stat-1', text: "Numbers don't lie. Memories do.", mood: 'stat', weight: 2 },
  { id: 'stat-2', text: 'Time in the band is a flex.', mood: 'stat' },
  { id: 'stat-3', text: 'Honest extras > pretend perfection.', mood: 'stat' },
  { id: 'stat-4', text: 'Look at that curve. Beautiful.', mood: 'stat' },
];

const recent: string[] = [];
const RECENT_CAPACITY = 20;

export function randomQuote(mood: QuoteMood): Quote | undefined {
  const pool = QUOTES.filter((q) => q.mood === mood && !recent.includes(q.id));
  const candidates = pool.length > 0 ? pool : QUOTES.filter((q) => q.mood === mood);
  if (candidates.length === 0) return undefined;
  const total = candidates.reduce((acc, q) => acc + Math.max(1, q.weight ?? 1), 0);
  let roll = Math.random() * total;
  for (const q of candidates) {
    roll -= Math.max(1, q.weight ?? 1);
    if (roll <= 0) {
      remember(q.id);
      return q;
    }
  }
  remember(candidates[candidates.length - 1].id);
  return candidates[candidates.length - 1];
}

export function dailyQuote(mood: QuoteMood, date: Date = new Date()): Quote | undefined {
  const pool = QUOTES.filter((q) => q.mood === mood);
  if (pool.length === 0) return undefined;
  const day = Math.floor(date.getTime() / (1000 * 60 * 60 * 24));
  return pool[day % pool.length];
}

export function resetQuoteMemory() {
  recent.length = 0;
}

function remember(id: string) {
  recent.push(id);
  if (recent.length > RECENT_CAPACITY) recent.shift();
}

export const OCCASION_TEMPLATES = [
  { id: 'occ-friday', name: 'Friday night', emoji: '🌙' },
  { id: 'occ-date', name: 'Date night', emoji: '💘' },
  { id: 'occ-wedding', name: 'Wedding', emoji: '💍' },
  { id: 'occ-concert', name: 'Concert', emoji: '🎤' },
  { id: 'occ-birthday', name: 'Birthday', emoji: '🎂' },
  { id: 'occ-gameday', name: 'Game day', emoji: '🏈' },
  { id: 'occ-brunch', name: 'Brunch', emoji: '🥞' },
  { id: 'occ-holiday', name: 'Holiday party', emoji: '🎄' },
];
