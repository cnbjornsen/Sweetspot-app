interface Props {
  bac: number;
  target?: number;
}

export function BACRing({ bac, target = 0.05 }: Props) {
  const zone = bacZone(bac);
  const fill = Math.min(1, Math.max(0, bac / (target * 1.6)));
  const radius = 96;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference * (1 - fill);

  return (
    <div className="ring-wrap" role="img"
         aria-label={`Current blood alcohol ${bac.toFixed(3)}, ${zone.label}`}>
      <svg className="ring-svg" viewBox="0 0 220 220">
        <circle cx="110" cy="110" r={radius} fill="none"
                stroke="rgba(255,255,255,0.15)" strokeWidth="14" />
        <circle cx="110" cy="110" r={radius} fill="none"
                stroke={zone.color} strokeWidth="14" strokeLinecap="round"
                strokeDasharray={circumference}
                strokeDashoffset={offset} />
      </svg>
      <div className="ring-center">
        <span className="ring-symbol" style={{ color: zone.color }}>{zone.symbol}</span>
        <span className="ring-value mono">{bac.toFixed(3)}</span>
        <span className="ring-zone">{zone.label}</span>
      </div>
    </div>
  );
}

export function bacZone(bac: number) {
  if (bac < 0.005) {
    return { label: 'Sober', symbol: '🌙', color: 'var(--blue)' };
  }
  if (bac < 0.05) {
    return { label: 'Sweet spot', symbol: '✅', color: 'var(--green)' };
  }
  if (bac < 0.08) {
    return { label: 'Above the band', symbol: '⚠️', color: 'var(--amber)' };
  }
  return { label: 'Risk zone — slow down', symbol: '🛑', color: 'var(--red)' };
}
