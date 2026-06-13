import {
  BACProfile,
  Drink,
  contributesToBAC,
  widmarkR,
} from './types';

export const DEFAULT_BETA = 0.015;

/// BAC% (g/100mL) from a single drink contribution, clamped at 0.
export function widmarkBAC(
  ethanolGrams: number,
  weightKg: number,
  r: number,
  hoursElapsed: number,
  beta: number = DEFAULT_BETA,
): number {
  if (ethanolGrams <= 0 || weightKg <= 0 || r <= 0) return 0;
  const weightGrams = weightKg * 1000;
  const raw = (ethanolGrams / (r * weightGrams)) * 100;
  const elapsed = Math.max(0, hoursElapsed);
  return Math.max(0, raw - beta * elapsed);
}

export function hoursToZero(bac: number, beta: number = DEFAULT_BETA): number {
  if (bac <= 0 || beta <= 0) return 0;
  return bac / beta;
}

export class BACTimeline {
  drinks: Drink[];
  profile: BACProfile;
  beta: number;

  constructor(drinks: Drink[], profile: BACProfile, beta: number = DEFAULT_BETA) {
    this.drinks = drinks
      .filter(contributesToBAC)
      .slice()
      .sort((a, b) => a.timestamp - b.timestamp);
    this.profile = profile;
    this.beta = beta;
  }

  bacAt(t: number): number {
    const r = widmarkR(this.profile.sex);
    let total = 0;
    for (const d of this.drinks) {
      if (d.timestamp > t) continue;
      const hours = (t - d.timestamp) / 3_600_000;
      total += widmarkBAC(d.ethanolGrams, this.profile.weightKg, r, hours, this.beta);
    }
    return total;
  }

  bacIfAdded(extraGrams: number, addedAt: number, evaluatedAt: number): number {
    let total = this.bacAt(evaluatedAt);
    if (addedAt <= evaluatedAt) {
      const r = widmarkR(this.profile.sex);
      const hours = (evaluatedAt - addedAt) / 3_600_000;
      total += widmarkBAC(extraGrams, this.profile.weightKg, r, hours, this.beta);
    }
    return total;
  }

  peakBACIn(start: number, end: number, stepMs: number = 60_000): number {
    let peak = 0;
    for (let t = start; t <= end; t += stepMs) {
      peak = Math.max(peak, this.bacAt(t));
    }
    return peak;
  }

  minutesAtOrBelow(threshold: number, start: number, end: number, stepMs: number = 60_000): number {
    let minutes = 0;
    for (let t = start; t <= end; t += stepMs) {
      if (this.bacAt(t) <= threshold) minutes += 1;
    }
    return minutes;
  }

  crossesDown(target: number, start: number, horizonMs: number = 24 * 3_600_000, stepMs: number = 60_000): number | undefined {
    for (let t = start; t <= start + horizonMs; t += stepMs) {
      if (this.bacAt(t) <= target) return t;
    }
    return undefined;
  }
}

export function soberTime(timeline: BACTimeline, reference: number): number | undefined {
  if (timeline.bacAt(reference) <= 0) return reference;
  return timeline.crossesDown(0, reference);
}
