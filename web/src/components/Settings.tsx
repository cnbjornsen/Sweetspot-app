import { useState } from 'react';
import { AppStateHookResult } from '../hooks/useAppState';
import { kgToLb, lbToKg, STANDARD_DRINK_PRESETS, WEIGHT_BOUNDS } from '../core/locale';

export function Settings({ app }: { app: AppStateHookResult }) {
  const profile = app.state.profile!;
  const [confirmClear, setConfirmClear] = useState(false);

  return (
    <div className="screen">
      <h1 className="title">Settings</h1>

      <div className="card" style={{ marginTop: 16 }}>
        <div className="h3">Profile</div>
        <div className="spread"><span>Weight</span><span className="mono">
          {profile.unitSystem === 'metric'
            ? `${profile.weightKg.toFixed(0)} kg`
            : `${kgToLb(profile.weightKg).toFixed(0)} lb`}
        </span></div>
        <div className="field" style={{ marginTop: 8 }}>
          <input type="range"
                 min={profile.unitSystem === 'metric' ? WEIGHT_BOUNDS.minKg : WEIGHT_BOUNDS.minLb}
                 max={profile.unitSystem === 'metric' ? WEIGHT_BOUNDS.maxKg : WEIGHT_BOUNDS.maxLb}
                 step={1}
                 value={Math.round(profile.unitSystem === 'metric'
                   ? profile.weightKg
                   : kgToLb(profile.weightKg))}
                 onChange={(e) => {
                   const n = Number(e.target.value);
                   app.upsertProfile((p) => ({
                     ...p,
                     weightKg: p.unitSystem === 'metric' ? n : lbToKg(n),
                   }));
                 }} />
        </div>
        <div className="spread"><span>Sex</span><span>
          <button className="chip" onClick={() =>
            app.upsertProfile((p) => ({ ...p, sex: p.sex === 'male' ? 'female' : 'male' }))}>
            {profile.sex === 'male' ? 'Male' : 'Female'}
          </button>
        </span></div>
        <div className="spread" style={{ marginTop: 8 }}>
          <span>Units</span>
          <div className="segmented" style={{ width: 'auto' }}>
            <button className={profile.unitSystem === 'metric' ? 'active' : ''}
                    onClick={() => app.upsertProfile((p) => ({ ...p, unitSystem: 'metric' }))}>
              kg
            </button>
            <button className={profile.unitSystem === 'imperial' ? 'active' : ''}
                    onClick={() => app.upsertProfile((p) => ({ ...p, unitSystem: 'imperial' }))}>
              lb
            </button>
          </div>
        </div>
        <div className="spread" style={{ marginTop: 8 }}>
          <span>1 drink =</span>
          <select value={profile.standardDrinkGrams}
                  onChange={(e) => app.upsertProfile((p) => ({
                    ...p, standardDrinkGrams: Number(e.target.value),
                  }))}
                  style={{
                    background: 'rgba(0,0,0,0.25)',
                    border: '1px solid rgba(255,255,255,0.18)',
                    borderRadius: 8,
                    padding: '6px 10px',
                  }}>
            {STANDARD_DRINK_PRESETS.map((g) => (
              <option key={g} value={g}>{g} g</option>
            ))}
          </select>
        </div>
      </div>

      <div className="card">
        <div className="h3">Festive</div>
        <Toggle label="Fanfare sound" value={profile.fanfareEnabled}
                onChange={(v) => app.upsertProfile((p) => ({ ...p, fanfareEnabled: v }))} />
        <Toggle label="Quotes" value={profile.quotesEnabled}
                onChange={(v) => app.upsertProfile((p) => ({ ...p, quotesEnabled: v }))} />
      </div>

      <div className="card">
        <div className="h3">Sessions</div>
        <div className="spread">
          <span>Mid-interval check</span>
          <select value={profile.midIntervalCheckMinutes}
                  onChange={(e) => app.upsertProfile((p) => ({
                    ...p, midIntervalCheckMinutes: Number(e.target.value),
                  }))}
                  style={{
                    background: 'rgba(0,0,0,0.25)',
                    border: '1px solid rgba(255,255,255,0.18)',
                    borderRadius: 8,
                    padding: '6px 10px',
                  }}>
            <option value={0}>Off</option>
            <option value={15}>Every 15 min</option>
            <option value={25}>Every 25 min</option>
            <option value={45}>Every 45 min</option>
          </select>
        </div>
      </div>

      <div className="card">
        <div className="h3">About</div>
        <p className="subtitle" style={{ fontSize: 13 }}>
          BAC estimates are approximations based on the Widmark formula. Real BAC depends on food,
          sleep, medications, and individual physiology. Sweet Spot is not medical or legal advice.
          Don't drive after drinking.
        </p>
        <p className="subtitle" style={{ fontSize: 13, marginTop: 8 }}>
          <strong>Privacy:</strong> All data stays in this browser's local storage. No analytics, no
          network calls, no third-party services.
        </p>
      </div>

      <button className="btn danger full" style={{ marginTop: 16 }}
              onClick={() => setConfirmClear(true)}>
        Delete all data
      </button>

      {confirmClear && (
        <div className="modal-backdrop" onClick={() => setConfirmClear(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <h2 className="h2">Delete everything?</h2>
            <p className="subtitle">
              Profile, occasions, sessions, and drinks will be permanently removed from this browser.
            </p>
            <div className="row" style={{ gap: 8 }}>
              <button className="btn ghost" style={{ flex: 1 }}
                      onClick={() => setConfirmClear(false)}>Cancel</button>
              <button className="btn danger" style={{ flex: 1 }}
                      onClick={() => { app.clearAllData(); setConfirmClear(false); }}>
                Delete
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function Toggle({ label, value, onChange }: {
  label: string;
  value: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <div className="spread" style={{ marginTop: 8 }}>
      <span>{label}</span>
      <button className={`chip ${value ? 'active' : ''}`}
              onClick={() => onChange(!value)}>
        {value ? 'On' : 'Off'}
      </button>
    </div>
  );
}
