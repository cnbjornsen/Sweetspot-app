import { useState } from 'react';
import { AppStateHookResult } from '../hooks/useAppState';
import { SessionMode } from '../core/types';
import { dailyQuote } from '../core/quotes';

type ModeKind = 'evenlyPaced' | 'peakThenMaintain';

export function NewSession({ app }: { app: AppStateHookResult }) {
  const [occasionId, setOccasionId] = useState<string | undefined>(undefined);
  const [modeKind, setModeKind] = useState<ModeKind>('evenlyPaced');
  const [durationHours, setDurationHours] = useState(4);
  const [peakHours, setPeakHours] = useState(2);
  const [newOccasionName, setNewOccasionName] = useState('');
  const quote = dailyQuote('onboarding');

  const orderedOccasions = [...app.state.occasions].sort((a, b) => {
    if (a.isFavorite !== b.isFavorite) return a.isFavorite ? -1 : 1;
    return b.lastUsedAt - a.lastUsedAt;
  });

  function startNow() {
    if (!occasionId) return;
    const start = Date.now();
    const end = start + durationHours * 3_600_000;
    const mode: SessionMode = modeKind === 'evenlyPaced'
      ? { kind: 'evenlyPaced', start, end }
      : {
          kind: 'peakThenMaintain',
          start,
          peak: start + peakHours * 3_600_000,
          end,
        };
    app.startSession(occasionId, mode);
  }

  return (
    <div className="screen">
      <h1 className="title">Sweet Spot</h1>
      {quote && <p className="subtitle">{quote.text}</p>}

      <div className="card" style={{ marginTop: 16 }}>
        <div className="h3">Occasion</div>
        <div className="chip-row" style={{ marginTop: 8 }}>
          {orderedOccasions.map((o) => (
            <button key={o.id}
                    className={`chip ${occasionId === o.id ? 'active' : ''}`}
                    onClick={() => setOccasionId(o.id)}>
              <span>{o.emoji ?? '🎉'}</span>
              <span>{o.name}</span>
            </button>
          ))}
        </div>
        <div className="row" style={{ marginTop: 12 }}>
          <input
            className="field"
            placeholder="New occasion…"
            value={newOccasionName}
            onChange={(e) => setNewOccasionName(e.target.value)}
            style={{
              background: 'rgba(0,0,0,0.25)',
              border: '1px solid rgba(255,255,255,0.18)',
              borderRadius: 10,
              padding: '10px 12px',
              outline: 'none',
              fontSize: 16,
              flex: 1,
            }}
          />
          <button className="btn secondary" onClick={() => {
            const name = newOccasionName.trim();
            if (!name) return;
            const occ = app.addOccasion(name);
            setOccasionId(occ.id);
            setNewOccasionName('');
          }}>Add</button>
        </div>
      </div>

      <div className="card">
        <div className="h3">Pace strategy</div>
        <div className="segmented" style={{ marginTop: 8 }}>
          <button className={modeKind === 'evenlyPaced' ? 'active' : ''}
                  onClick={() => setModeKind('evenlyPaced')}>Even</button>
          <button className={modeKind === 'peakThenMaintain' ? 'active' : ''}
                  onClick={() => setModeKind('peakThenMaintain')}>Ramp + maintain</button>
        </div>
        <p className="subtitle" style={{ fontSize: 13, marginTop: 8 }}>
          {modeKind === 'evenlyPaced'
            ? 'Spread drinks evenly across the whole window.'
            : 'Ramp up to a peak, then coast at one drink an hour.'}
        </p>
      </div>

      <div className="card">
        <div className="h3">Times</div>
        <div className="field" style={{ marginTop: 8 }}>
          <label>Session length: {durationHours} h</label>
          <input type="range" min={1} max={8} step={0.5}
                 value={durationHours}
                 onChange={(e) => setDurationHours(Number(e.target.value))} />
        </div>
        {modeKind === 'peakThenMaintain' && (
          <div className="field">
            <label>Peak at: {peakHours} h in</label>
            <input type="range" min={0.5} max={Math.max(0.5, durationHours - 0.5)} step={0.5}
                   value={Math.min(peakHours, durationHours - 0.5)}
                   onChange={(e) => setPeakHours(Number(e.target.value))} />
          </div>
        )}
      </div>

      <button className="btn full" style={{ marginTop: 16 }}
              disabled={!occasionId}
              onClick={startNow}>
        ▶ Start session
      </button>
    </div>
  );
}
