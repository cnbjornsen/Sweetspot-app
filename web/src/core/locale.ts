export function localeStandardDrinkGrams(): number {
  if (typeof navigator === 'undefined') return 14;
  const region =
    new Intl.Locale(navigator.language).maximize().region ?? '';
  switch (region.toUpperCase()) {
    case 'GB':
    case 'IE':
      return 8;
    case 'AU':
    case 'NZ':
    case 'AT':
    case 'BE':
    case 'CZ':
    case 'DE':
    case 'DK':
    case 'ES':
    case 'FI':
    case 'FR':
    case 'GR':
    case 'HU':
    case 'IS':
    case 'IT':
    case 'LU':
    case 'NL':
    case 'NO':
    case 'PL':
    case 'PT':
    case 'SE':
    case 'SI':
    case 'SK':
    case 'CH':
      return 10;
    case 'JP':
      return 20;
    case 'CA':
      return 13.6;
    default:
      return 14;
  }
}

export const STANDARD_DRINK_PRESETS = [8, 10, 12, 13.6, 14, 16, 20];

export const KG_PER_LB = 0.45359237;
export const LB_PER_KG = 1 / KG_PER_LB;

export function kgToLb(kg: number): number {
  return kg * LB_PER_KG;
}
export function lbToKg(lb: number): number {
  return lb * KG_PER_LB;
}

export const WEIGHT_BOUNDS = {
  minKg: 35,
  maxKg: 250,
  minLb: 80,
  maxLb: 550,
};

export const defaultUnitSystem = (): 'metric' | 'imperial' => {
  if (typeof navigator === 'undefined') return 'metric';
  const region =
    new Intl.Locale(navigator.language).maximize().region ?? '';
  return ['US', 'LR', 'MM'].includes(region.toUpperCase()) ? 'imperial' : 'metric';
};
