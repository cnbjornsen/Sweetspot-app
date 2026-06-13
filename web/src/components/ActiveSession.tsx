import { useMemo, useState } from 'react';
import { AppStateHookResult } from '../hooks/useAppState';
import { BACRing } from './BACRing';
import { Countdown } from './Countdown';
import { ExtraDrinkSheet } from './ExtraDrinkSheet';
import { randomQuote } from '../core/quotes';

export function ActiveSession({ app }: { app: AppStateHookResult }) {
  const session = app.activeSession!;
  const occasion = app.state.occasions.find((o) => o.id === session.occasionId);
  const [showExtra, setShowExtra] = useState(false);
  const [confirmEnd, setConfirmEnd] = useState(false);

  const alcoholicCount = useMemo(
    () => session.drinks.filter((d) => d.type !== 'water').length,
    [session.drinks],
  );
  const waterCount = useMemo(
    () => session.drinks.filter((d) => d.type === 'water').length,
    [session.drinks],
  );

  // Quote re-pulled on every render but stays stable across drinks via key trick:
  const quote = useMemo(() => randomQuote('encouraging')?.text, [alcoholicCount]);

  return (
    <div className="screen">
      <div className="center">
        <div className="h2">{occasion?.emoji ?? '🎉'} {occasion?.name ?? 'Sweet Spot'}</div>
      </div>

      <div style={{ margin: '20px 0' }}>
        <BACRing bac={app.derived.currentBAC} />
      </div>

      <CountdownBlock app={app} />

      <Banner app={app} />

      {quote && <div className="quote">{quote}</div>}

      <div className="col" style={{ gap: 8, marginTop: 16 }}>
        <button className="btn full" onClick={() => app.logScheduledDrink()}>
          🥂 I had one
        </button>
        <div className="row" style={{ gap: 8 }}>
          <button className="btn secondary" style={{ flex: 1 }}
                  onClick={() => setShowExtra(true)}>
            ➕ Had extra
          </button>
          <button className="btn secondary" style={{ flex: 1 }}
                  onClick={() => app.logWater()}>
            💧 Water
          </button>
        </div>
        <button className="btn ghost full" onClick={() => app.undoLastDrink()}>
          Undo last
        </button>
      </div>

      <div className="card" style={{ marginTop: 16 }}>
        <div className="spread">
          <span>🥂 Drinks</span>
          <strong className="mono">{alcoholicCount}</strong>
        </div>
        <div className="spread">
          <span>💧 Water</span>
          <strong className="mono">{waterCount}</strong>
        </div>
        {app.derived.soberAt && (
          <div className="spread">
            <span>🌙 Sober at</span>
            <strong className="mono">
              {new Date(app.derived.soberAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
            </strong>
          </div>
        )}
      </div>

      <button className="btn ghost full" style={{ marginTop: 16 }}
              onClick={() => setConfirmEnd(true)}>
        End session
      </button>

      {showExtra && (
        <ExtraDrinkSheet app={app} onClose={() => setShowExtra(false)} />
      )}

      {confirmEnd && (
        <div className="modal-backdrop" onClick={() => setConfirmEnd(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <h2 className="h2">End session?</h2>
            <p className="subtitle">We'll save your stats and stop the countdown.</p>
            <div className="row" style={{ gap: 8 }}>
              <button className="btn ghost" style={{ flex: 1 }}
                      onClick={() => setConfirmEnd(false)}>Cancel</button>
              <button className="btn danger" style={{ flex: 1 }}
                      onClick={() => { app.endSession(); setConfirmEnd(false); }}>
                End
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function CountdownBlock({ app }: { app: AppStateHookResult }) {
  const next = app.derived.nextDrinkAt;
  if (next && next > Date.now()) {
    return (
      <div>
        <div className="timer-caption">Next sip in</div>
        <Countdown target={next} />
      </div>
    );
  }
  if (app.derived.fanfarePending) {
    return <div className="timer-big center">🎉 Time for the next one</div>;
  }
  if (app.derived.snapshotState === 'coastingHome') {
    return <div className="h2 center">🏠 Coast home</div>;
  }
  return <div className="timer-big center" style={{ opacity: 0.4 }}>—</div>;
}

function Banner({ app }: { app: AppStateHookResult }) {
  const { snapshotState, soberAt } = app.derived;
  if (snapshotState === 'maintenance') {
    return (
      <div className="banner" style={{ marginTop: 12 }}>
        <span className="symbol">🔁</span>
        <div>
          <div className="title">Maintenance mode</div>
          <div className="msg">You're at the top of the band. About one drink an hour keeps you steady.</div>
        </div>
      </div>
    );
  }
  if (snapshotState === 'coastingHome') {
    return (
      <div className="banner" style={{ marginTop: 12 }}>
        <span className="symbol">🏠</span>
        <div>
          <div className="title">Coast home</div>
          <div className="msg">
            {soberAt
              ? `Estimated 0.00 BAC at ${new Date(soberAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}.`
              : 'Session over. Drink water and head home.'}
          </div>
        </div>
      </div>
    );
  }
  return null;
}
