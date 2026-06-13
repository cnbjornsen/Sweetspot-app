import {
  BACProfile,
  Drink,
  SessionMode,
  widmarkR,
  contributesToBAC,
} from './types';
import { BACTimeline, DEFAULT_BETA } from './widmark';

export interface ScheduledDrink {
  id: string;
  scheduledAt: number;
  standardDrinks: number;
}

export interface PlannerInput {
  profile: BACProfile;
  mode: SessionMode;
  now: number;
  alreadyConsumed: Drink[];
  target?: number;
  epsilon?: number;
  beta?: number;
}

const TARGET_DEFAULT = 0.05;
const EPSILON_DEFAULT = 0.001;

export function planSchedule(input: PlannerInput): ScheduledDrink[] {
  const target = input.target ?? TARGET_DEFAULT;
  const epsilon = input.epsilon ?? EPSILON_DEFAULT;
  const beta = input.beta ?? DEFAULT_BETA;

  switch (input.mode.kind) {
    case 'evenlyPaced':
      return scheduleEven(input, input.mode.start, input.mode.end, target, epsilon, beta);
    case 'peakThenMaintain':
      return schedulePeak(
        input,
        input.mode.start,
        input.mode.peak,
        input.mode.end,
        target,
        epsilon,
        beta,
      );
  }
}

function scheduleEven(
  input: PlannerInput,
  start: number,
  end: number,
  target: number,
  epsilon: number,
  beta: number,
): ScheduledDrink[] {
  if (end <= start) return [];
  const timeline = new BACTimeline(input.alreadyConsumed, input.profile, beta);
  const standardGrams = input.profile.standardDrinkGrams;
  const effectiveStart = Math.max(input.now, start);
  if (effectiveStart >= end) {
    return maintenanceTail(input, effectiveStart, end, timeline, target, epsilon, beta);
  }
  const firstSlot = nextSafeSlot(input, effectiveStart, standardGrams, timeline, target, epsilon);
  if (firstSlot === undefined || firstSlot >= end) return [];

  const maxN = upperBoundForN(input.profile, firstSlot, end, target, beta);
  const chosen = bisectMaxN(0, maxN, input, firstSlot, end, timeline, target, epsilon, beta);
  if (chosen <= 0) {
    return maintenanceTail(input, firstSlot, end, timeline, target, epsilon, beta);
  }

  const window = end - firstSlot;
  const spacing = chosen === 1 ? 0 : window / chosen;
  const out: ScheduledDrink[] = [];
  for (let i = 0; i < chosen; i++) {
    out.push({
      id: cryptoRandomId(),
      scheduledAt: firstSlot + spacing * i,
      standardDrinks: 1,
    });
  }
  return out;
}

function schedulePeak(
  input: PlannerInput,
  start: number,
  peak: number,
  end: number,
  target: number,
  epsilon: number,
  beta: number,
): ScheduledDrink[] {
  if (peak <= start || end < peak) return [];
  const timeline = new BACTimeline(input.alreadyConsumed, input.profile, beta);
  const standardGrams = input.profile.standardDrinkGrams;
  const effectiveStart = Math.max(input.now, start);
  const out: ScheduledDrink[] = [];

  if (effectiveStart < peak) {
    const firstSlot = nextSafeSlot(input, effectiveStart, standardGrams, timeline, target, epsilon);
    if (firstSlot !== undefined && firstSlot < peak) {
      const maxN = upperBoundForN(input.profile, firstSlot, peak, target, beta);
      const ramp = bisectMaxN(0, maxN, input, firstSlot, peak, timeline, target, epsilon, beta);
      if (ramp > 0) {
        const window = peak - firstSlot;
        const spacing = ramp === 1 ? 0 : window / ramp;
        for (let i = 0; i < ramp; i++) {
          out.push({
            id: cryptoRandomId(),
            scheduledAt: firstSlot + spacing * i,
            standardDrinks: 1,
          });
        }
      }
    }
  }

  const lastRampAt = out.length > 0 ? out[out.length - 1].scheduledAt : peak;
  const maintenanceStart = Math.max(lastRampAt, peak);
  const tail = maintenanceTail(input, maintenanceStart, end, timeline, target, epsilon, beta);
  out.push(...tail);
  return out;
}

function maintenanceTail(
  input: PlannerInput,
  start: number,
  end: number,
  timeline: BACTimeline,
  target: number,
  epsilon: number,
  beta: number,
): ScheduledDrink[] {
  if (end <= start) return [];
  const standardGrams = input.profile.standardDrinkGrams;
  const r = widmarkR(input.profile.sex);
  const deltaPerDrink =
    (standardGrams / (r * input.profile.weightKg * 1000)) * 100;
  const hoursPerDrink = deltaPerDrink / beta;
  const spacingMs = Math.max(15 * 60_000, hoursPerDrink * 3_600_000);

  const firstSlot = nextSafeSlot(input, start, standardGrams, timeline, target, epsilon);
  if (firstSlot === undefined) return [];
  const out: ScheduledDrink[] = [];
  for (let t = firstSlot; t <= end; t += spacingMs) {
    out.push({
      id: cryptoRandomId(),
      scheduledAt: t,
      standardDrinks: 1,
    });
  }
  return out;
}

function nextSafeSlot(
  input: PlannerInput,
  start: number,
  extraGrams: number,
  timeline: BACTimeline,
  target: number,
  epsilon: number,
): number | undefined {
  const safeTarget = target - epsilon;
  const cap = start + 12 * 3_600_000;
  for (let t = start; t <= cap; t += 60_000) {
    if (timeline.bacIfAdded(extraGrams, t, t) <= safeTarget) return t;
  }
  return undefined;
}

function upperBoundForN(
  profile: BACProfile,
  start: number,
  end: number,
  target: number,
  beta: number,
): number {
  const r = widmarkR(profile.sex);
  const deltaPerDrink =
    (profile.standardDrinkGrams / (r * profile.weightKg * 1000)) * 100;
  if (deltaPerDrink <= 0) return 0;
  const durationHours = Math.max(0, (end - start) / 3_600_000);
  const bunchedCap = (target + beta * durationHours) / deltaPerDrink;
  return Math.max(12, Math.ceil(bunchedCap * 6));
}

function bisectMaxN(
  lo: number,
  hi: number,
  input: PlannerInput,
  start: number,
  end: number,
  timeline: BACTimeline,
  target: number,
  epsilon: number,
  beta: number,
): number {
  let low = lo;
  let high = hi;
  while (low < high) {
    const mid = (low + high + 1) >> 1;
    if (isSafeSchedule(mid, input, start, end, target, epsilon, beta)) {
      low = mid;
    } else {
      high = mid - 1;
    }
  }
  return low;
}

function isSafeSchedule(
  n: number,
  input: PlannerInput,
  start: number,
  end: number,
  target: number,
  epsilon: number,
  beta: number,
): boolean {
  if (n <= 0) return true;
  const window = end - start;
  if (window <= 0) return false;
  const spacing = n === 1 ? 0 : window / n;
  const standardGrams = input.profile.standardDrinkGrams;

  const hypothetical: Drink[] = input.alreadyConsumed.filter(contributesToBAC).slice();
  for (let i = 0; i < n; i++) {
    hypothetical.push({
      id: `hypo-${i}`,
      timestamp: start + spacing * i,
      type: 'beer12oz',
      ethanolGrams: standardGrams,
      sizeMultiplier: 1,
      wasScheduled: true,
    });
  }
  const candidate = new BACTimeline(hypothetical, input.profile, beta);
  const safeTarget = target + epsilon;
  for (let t = start; t <= end; t += 60_000) {
    if (candidate.bacAt(t) > safeTarget) return false;
  }
  return true;
}

function cryptoRandomId(): string {
  if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) {
    return crypto.randomUUID();
  }
  return Math.random().toString(36).slice(2);
}
