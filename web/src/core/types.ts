export type BiologicalSex = 'male' | 'female';
export type UnitSystem = 'metric' | 'imperial';

export const widmarkR = (sex: BiologicalSex): number =>
  sex === 'male' ? 0.68 : 0.55;

export interface BACProfile {
  weightKg: number;
  sex: BiologicalSex;
  standardDrinkGrams: number;
}

export type DrinkType =
  | 'beer12oz'
  | 'wine5oz'
  | 'shot15oz'
  | 'cocktailStandard'
  | 'custom'
  | 'water';

export const DRINK_TYPE_LABELS: Record<DrinkType, { name: string; emoji: string }> = {
  beer12oz: { name: 'Beer', emoji: '🍺' },
  wine5oz: { name: 'Wine', emoji: '🍷' },
  shot15oz: { name: 'Shot', emoji: '🥃' },
  cocktailStandard: { name: 'Cocktail', emoji: '🍸' },
  custom: { name: 'Custom', emoji: '🍹' },
  water: { name: 'Water', emoji: '💧' },
};

export interface DrinkSizeOverride {
  multiplier: number;
  customEthanolGrams?: number;
}

export const baseStandardDrinks = (type: DrinkType): number => {
  switch (type) {
    case 'beer12oz':
    case 'wine5oz':
    case 'shot15oz':
    case 'cocktailStandard':
      return 1;
    case 'custom':
    case 'water':
      return 0;
  }
};

export const ethanolGramsFor = (
  type: DrinkType,
  profile: BACProfile,
  override: DrinkSizeOverride = { multiplier: 1 },
): number => {
  if (type === 'water') return 0;
  if (type === 'custom') {
    return (override.customEthanolGrams ?? 0) * override.multiplier;
  }
  return baseStandardDrinks(type) * profile.standardDrinkGrams * override.multiplier;
};

export type SessionMode =
  | { kind: 'evenlyPaced'; start: number; end: number }
  | { kind: 'peakThenMaintain'; start: number; peak: number; end: number };

export const sessionModeEnd = (mode: SessionMode): number => mode.end;
export const sessionModeStart = (mode: SessionMode): number => mode.start;
export const sessionModePeak = (mode: SessionMode): number | undefined =>
  mode.kind === 'peakThenMaintain' ? mode.peak : undefined;

export interface Drink {
  id: string;
  timestamp: number; // epoch ms
  type: DrinkType;
  ethanolGrams: number;
  sizeMultiplier: number;
  wasScheduled: boolean;
}

export const contributesToBAC = (d: Drink): boolean => d.ethanolGrams > 0;

export interface Occasion {
  id: string;
  name: string;
  emoji?: string;
  lastUsedAt: number;
  isFavorite: boolean;
  isTemplate: boolean;
}

export interface Session {
  id: string;
  occasionId?: string;
  startedAt: number;
  endedAt?: number;
  mode: SessionMode;
  drinks: Drink[];
  peakBAC: number;
  minutesInSweetSpot: number;
  unscheduledExtrasCount: number;
  waterCount: number;
  soberAt?: number;
  autoEnded?: boolean;
  endReason?: 'user' | 'auto';
}

export interface UserProfile {
  weightKg: number;
  sex: BiologicalSex;
  unitSystem: UnitSystem;
  standardDrinkGrams: number;
  ageGateConfirmedAt?: number;
  disclaimerAcknowledgedAt?: number;
  fanfareEnabled: boolean;
  quotesEnabled: boolean;
  midIntervalCheckMinutes: number;
  watchdogGraceHours: number;
}

export const profileBACProfile = (p: UserProfile): BACProfile => ({
  weightKg: p.weightKg,
  sex: p.sex,
  standardDrinkGrams: p.standardDrinkGrams,
});

export const profileHasCompletedOnboarding = (p: UserProfile): boolean =>
  !!p.ageGateConfirmedAt && !!p.disclaimerAcknowledgedAt;

export type SnapshotState =
  | 'idle'
  | 'waiting'
  | 'readyForDrink'
  | 'maintenance'
  | 'coastingHome'
  | 'ended';
