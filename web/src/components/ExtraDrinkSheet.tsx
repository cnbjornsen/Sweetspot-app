import { useState } from 'react';
import { AppStateHookResult } from '../hooks/useAppState';
import { DRINK_TYPE_LABELS, DrinkType } from '../core/types';

const ALCOHOLIC: DrinkType[] = ['beer12oz', 'wine5oz', 'shot15oz', 'cocktailStandard', 'custom'];

export function ExtraDrinkSheet({ app, onClose }: {
  app: AppStateHookResult;
  onClose: () => void;
}) {
  const [type, setType] = useState<DrinkType>('shot15oz');
  const [mult, setMult] = useState(1);
  const [customGrams, setCustomGrams] = useState(14);

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <h2 className="h2">Extra drink</h2>
        <div className="col" style={{ gap: 6 }}>
          {ALCOHOLIC.map((t) => (
            <button
              key={t}
              className={`chip ${type === t ? 'active' : ''}`}
              onClick={() => setType(t)}
              style={{ justifyContent: 'flex-start', padding: '12px 16px' }}>
              <span>{DRINK_TYPE_LABELS[t].emoji}</span>
              <span>{DRINK_TYPE_LABELS[t].name}</span>
            </button>
          ))}
        </div>
        <div className="field">
          <label>Pour size: ×{mult.toFixed(2)}</label>
          <input type="range" min={0.5} max={3} step={0.25}
                 value={mult} onChange={(e) => setMult(Number(e.target.value))} />
        </div>
        {type === 'custom' && (
          <div className="field">
            <label>Ethanol grams</label>
            <input type="number" value={customGrams}
                   onChange={(e) => setCustomGrams(Number(e.target.value))}
                   min={1} max={60} />
          </div>
        )}
        <div className="row" style={{ gap: 8 }}>
          <button className="btn ghost" style={{ flex: 1 }} onClick={onClose}>Cancel</button>
          <button className="btn" style={{ flex: 1 }} onClick={() => {
            app.logExtraDrink(type, mult, type === 'custom' ? customGrams : undefined);
            onClose();
          }}>
            Log it
          </button>
        </div>
      </div>
    </div>
  );
}
