import { AppStateHookResult } from '../hooks/useAppState';
import { DRINK_TYPE_LABELS, DrinkType } from '../core/types';
import { randomQuote } from '../core/quotes';

const QUICK: { type: DrinkType; label: string }[] = [
  { type: 'shot15oz', label: 'A shot' },
  { type: 'wine5oz', label: 'A glass of wine' },
  { type: 'beer12oz', label: 'A beer' },
  { type: 'cocktailStandard', label: 'A cocktail' },
  { type: 'water', label: 'Just water 💧' },
];

export function MidIntervalSheet({ app }: { app: AppStateHookResult }) {
  const quote = randomQuote('cautionary')?.text;

  return (
    <div className="modal-backdrop" onClick={() => app.dismissMidIntervalCheck(false)}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <h2 className="h2 center">Honest check</h2>
        {quote && <p className="subtitle center">{quote}</p>}
        <p className="center subtitle">Did anything sneak in since the last drink?</p>
        <div className="col" style={{ gap: 6 }}>
          {QUICK.map((q) => (
            <button
              key={q.type}
              className="chip"
              style={{ justifyContent: 'flex-start', padding: '12px 16px' }}
              onClick={() => {
                if (q.type === 'water') {
                  app.logWater();
                } else {
                  app.logExtraDrink(q.type);
                }
                app.dismissMidIntervalCheck(false);
              }}>
              <span>{DRINK_TYPE_LABELS[q.type].emoji}</span>
              <span>{q.label}</span>
            </button>
          ))}
        </div>
        <div className="row" style={{ gap: 8 }}>
          <button className="btn ghost" style={{ flex: 1 }}
                  onClick={() => app.dismissMidIntervalCheck(false)}>
            Nope, all clean
          </button>
          <button className="btn secondary" style={{ flex: 1 }}
                  onClick={() => app.dismissMidIntervalCheck(true)}>
            Hush this session
          </button>
        </div>
      </div>
    </div>
  );
}
