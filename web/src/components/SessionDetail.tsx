import { AppStateHookResult } from '../hooks/useAppState';
import { Session, profileBACProfile, DRINK_TYPE_LABELS } from '../core/types';
import { BACTimeline } from '../core/widmark';
import { dailyQuote } from '../core/quotes';

export function SessionDetail({ app, session, onBack }: {
  app: AppStateHookResult;
  session: Session;
  onBack: () => void;
}) {
  const occasion = app.state.occasions.find((o) => o.id === session.occasionId);
  const profile = app.state.profile!;
  const end = session.endedAt ?? Date.now();
  const timeline = new BACTimeline(session.drinks, profileBACProfile(profile));
  const path = buildPath(timeline, session.startedAt, end);
  const quote = dailyQuote('stat');

  const alcoholic = session.drinks.filter((d) => d.type !== 'water');

  return (
    <div className="screen">
      <button className="btn ghost" style={{ alignSelf: 'flex-start' }}
              onClick={onBack}>← Back</button>
      <h1 className="title" style={{ marginTop: 8 }}>
        {occasion?.emoji ?? '🎉'} {occasion?.name ?? 'Session'}
      </h1>
      <p className="subtitle">
        {new Date(session.startedAt).toLocaleString([], { dateStyle: 'full', timeStyle: 'short' })}
      </p>

      <div className="card" style={{ marginTop: 16 }}>
        <svg viewBox="0 0 320 160" width="100%" height="180">
          {/* Sweet-spot band */}
          <rect x="0" y={bacToY(0.05)} width="320" height={160 - bacToY(0.05)}
                fill="rgba(76, 217, 122, 0.12)" />
          <line x1="0" y1={bacToY(0.05)} x2="320" y2={bacToY(0.05)}
                stroke="#4cd97a" strokeDasharray="4 4" />
          <text x="316" y={bacToY(0.05) - 4} textAnchor="end"
                fill="#4cd97a" fontSize="10">0.05</text>
          <path d={path} fill="rgba(255,255,255,0.18)" stroke="#fff" strokeWidth="2" />
          {alcoholic.map((d) => {
            const x = ((d.timestamp - session.startedAt) / (end - session.startedAt)) * 320;
            const y = bacToY(timeline.bacAt(d.timestamp));
            return (
              <circle key={d.id} cx={x} cy={y} r="3.5"
                      fill={d.wasScheduled ? '#fff' : '#f8c33b'} />
            );
          })}
        </svg>
      </div>

      <div className="stat-grid" style={{ marginTop: 12 }}>
        <Stat label="Drinks" value={alcoholic.length} />
        <Stat label="Water" value={session.waterCount} />
        <Stat label="Peak BAC" value={session.peakBAC.toFixed(3)} />
        <Stat label="In band" value={`${session.minutesInSweetSpot} min`} />
        <Stat label="Extras" value={session.unscheduledExtrasCount} />
        <Stat label="Sober at"
              value={session.soberAt
                ? new Date(session.soberAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
                : '—'} />
      </div>

      <div className="card" style={{ marginTop: 12 }}>
        <div className="h3">Drinks</div>
        {session.drinks
          .slice()
          .sort((a, b) => a.timestamp - b.timestamp)
          .map((d) => (
            <div key={d.id} className="list-row">
              <span style={{ fontSize: 20 }}>{DRINK_TYPE_LABELS[d.type].emoji}</span>
              <div style={{ flex: 1 }}>
                <div>{DRINK_TYPE_LABELS[d.type].name}</div>
                <div className="subtitle" style={{ fontSize: 12 }}>
                  {new Date(d.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  {!d.wasScheduled && d.type !== 'water' ? ' • extra' : ''}
                </div>
              </div>
              <span className="mono">{d.ethanolGrams.toFixed(0)} g</span>
              <button className="btn ghost" onClick={() => app.deleteDrink(d.id)}>🗑</button>
            </div>
          ))}
      </div>

      {quote && <div className="quote" style={{ marginTop: 12 }}>{quote.text}</div>}
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="stat-card">
      <div className="stat-label">{label}</div>
      <div className="stat-value mono">{value}</div>
    </div>
  );
}

function buildPath(timeline: BACTimeline, start: number, end: number): string {
  if (end <= start) return '';
  const steps = 60;
  const stepMs = (end - start) / steps;
  const pts: [number, number][] = [];
  for (let i = 0; i <= steps; i++) {
    const t = start + i * stepMs;
    const x = (i / steps) * 320;
    const y = bacToY(timeline.bacAt(t));
    pts.push([x, y]);
  }
  // Close to baseline for fill
  const top = pts.map(([x, y]) => `${x.toFixed(1)},${y.toFixed(1)}`).join(' L ');
  return `M 0,160 L ${top} L 320,160 Z`;
}

const MAX_BAC = 0.12;
function bacToY(bac: number): number {
  const clamped = Math.min(MAX_BAC, Math.max(0, bac));
  return 160 - (clamped / MAX_BAC) * 160;
}
