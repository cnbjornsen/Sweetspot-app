import { useMemo, useState } from 'react';
import { AppStateHookResult } from '../hooks/useAppState';
import { Session } from '../core/types';
import { SessionDetail } from './SessionDetail';

export function History({ app }: { app: AppStateHookResult }) {
  const [detailId, setDetailId] = useState<string | null>(null);
  const ended = useMemo(
    () => app.state.sessions
      .filter((s) => s.endedAt !== undefined)
      .sort((a, b) => (b.endedAt ?? 0) - (a.endedAt ?? 0)),
    [app.state.sessions],
  );

  if (detailId) {
    const session = app.state.sessions.find((s) => s.id === detailId);
    if (session) {
      return <SessionDetail app={app} session={session} onBack={() => setDetailId(null)} />;
    }
  }

  return (
    <div className="screen">
      <h1 className="title">History</h1>
      {ended.length === 0 ? (
        <div className="empty-state">
          <div className="big">🥂</div>
          <h2 className="h2">No sessions yet</h2>
          <p>Your first occasion awaits 🍾</p>
        </div>
      ) : (
        <div className="card" style={{ marginTop: 16 }}>
          {ended.map((s) => (
            <Row key={s.id} session={s} app={app}
                 onClick={() => setDetailId(s.id)} />
          ))}
        </div>
      )}
    </div>
  );
}

function Row({ session, app, onClick }: {
  session: Session;
  app: AppStateHookResult;
  onClick: () => void;
}) {
  const occasion = app.state.occasions.find((o) => o.id === session.occasionId);
  return (
    <button className="list-row" style={{ width: '100%', textAlign: 'left' }}
            onClick={onClick}>
      <div style={{ flex: 1 }}>
        <div className="h3">{occasion?.emoji ?? '🎉'} {occasion?.name ?? 'Session'}</div>
        <div className="subtitle" style={{ fontSize: 12 }}>
          {new Date(session.startedAt).toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' })}
        </div>
      </div>
      <div style={{ textAlign: 'right' }}>
        <div className="mono">Peak {session.peakBAC.toFixed(3)}</div>
        <div className="subtitle" style={{ fontSize: 12 }}>
          {session.minutesInSweetSpot} min in band
        </div>
      </div>
    </button>
  );
}
