import { Occasion, Session, UserProfile } from '../core/types';
import { OCCASION_TEMPLATES } from '../core/quotes';
import { defaultUnitSystem, localeStandardDrinkGrams } from '../core/locale';

const KEY = 'sweetspot.state.v2';
const OLD_KEYS = ['sweetspot.state.v1'];

export interface AppState {
  profile: UserProfile | null;
  occasions: Occasion[];
  sessions: Session[];
  activeSessionId: string | null;
}

const defaultState = (): AppState => ({
  profile: null,
  occasions: OCCASION_TEMPLATES.map((t) => ({
    id: t.id,
    name: t.name,
    emoji: t.emoji,
    lastUsedAt: 0,
    isFavorite: false,
    isTemplate: true,
  })),
  sessions: [],
  activeSessionId: null,
});

export function loadState(): AppState {
  if (typeof localStorage === 'undefined') return defaultState();
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return defaultState();
    const parsed = JSON.parse(raw) as Partial<AppState>;
    return {
      profile: parsed.profile ?? null,
      occasions: parsed.occasions ?? defaultState().occasions,
      sessions: parsed.sessions ?? [],
      activeSessionId: parsed.activeSessionId ?? null,
    };
  } catch {
    return defaultState();
  }
}

export function saveState(state: AppState): void {
  if (typeof localStorage === 'undefined') return;
  try {
    localStorage.setItem(KEY, JSON.stringify(state));
  } catch {
    // Storage quota / private browsing — silently ignore.
  }
}

export function clearAll(): void {
  if (typeof localStorage === 'undefined') return;
  localStorage.removeItem(KEY);
  for (const oldKey of OLD_KEYS) localStorage.removeItem(oldKey);
}

export function defaultProfile(): UserProfile {
  return {
    weightKg: 70,
    sex: 'male',
    unitSystem: defaultUnitSystem(),
    standardDrinkGrams: localeStandardDrinkGrams(),
    fanfareEnabled: true,
    quotesEnabled: true,
    midIntervalCheckMinutes: 25,
    watchdogGraceHours: 2,
  };
}
