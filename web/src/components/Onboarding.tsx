import { useState } from 'react';
import { AppStateHookResult } from '../hooks/useAppState';
import { defaultProfile } from '../store/store';
import { kgToLb, lbToKg, WEIGHT_BOUNDS } from '../core/locale';

type Step = 'age' | 'disclaimer' | 'units' | 'weight' | 'sex' | 'notifications';

export function Onboarding({ app }: { app: AppStateHookResult }) {
  const [step, setStep] = useState<Step>('age');
  const [draft, setDraft] = useState(() => app.state.profile ?? defaultProfile());

  function commit() {
    app.upsertProfile(() => ({
      ...draft,
      ageGateConfirmedAt: draft.ageGateConfirmedAt ?? Date.now(),
      disclaimerAcknowledgedAt: draft.disclaimerAcknowledgedAt ?? Date.now(),
    }));
  }

  return (
    <div className="app-shell bg-festive">
      <div className="screen">
        {step === 'age' && (
          <Step title="Quick check" icon="🪪"
            sub="Are you of legal drinking age in your jurisdiction?">
            <div className="col" style={{ gap: 8 }}>
              <button className="btn full" onClick={() => {
                setDraft({ ...draft, ageGateConfirmedAt: Date.now() });
                setStep('disclaimer');
              }}>Yes, I am</button>
              <button className="btn secondary full" onClick={() => alert(
                'Sweet Spot is for adults of legal drinking age. Come back when you can.')}>
                Not yet
              </button>
            </div>
          </Step>
        )}
        {step === 'disclaimer' && (
          <Step title="A few honest words" icon="🛡️">
            <ul className="disclaimer-list">
              <li>BAC estimates are approximations. Real BAC depends on food, sleep, meds, and more.</li>
              <li>Sweet Spot is not medical or legal advice. Don't drive after drinking.</li>
              <li>Some people should not drink at all. Listen to your doctor over us.</li>
              <li>Your data lives only on this device. No server, no account.</li>
            </ul>
            <button className="btn full" onClick={() => {
              setDraft({ ...draft, disclaimerAcknowledgedAt: Date.now() });
              setStep('units');
            }}>I understand</button>
          </Step>
        )}
        {step === 'units' && (
          <Step title="Units" icon="📐" sub="You can change later.">
            <div className="segmented">
              <button className={draft.unitSystem === 'metric' ? 'active' : ''}
                      onClick={() => setDraft({ ...draft, unitSystem: 'metric' })}>
                Metric (kg)
              </button>
              <button className={draft.unitSystem === 'imperial' ? 'active' : ''}
                      onClick={() => setDraft({ ...draft, unitSystem: 'imperial' })}>
                Imperial (lb)
              </button>
            </div>
            <button className="btn full" onClick={() => setStep('weight')}>Continue</button>
          </Step>
        )}
        {step === 'weight' && (
          <Step title="Your weight" icon="🏋️"
            sub="The only number that drives the BAC math. Stays on this device.">
            <WeightInput
              weightKg={draft.weightKg}
              unitSystem={draft.unitSystem}
              onChange={(kg) => setDraft({ ...draft, weightKg: kg })}
            />
            <button className="btn full" onClick={() => setStep('sex')}
                    disabled={!withinBounds(draft.weightKg, draft.unitSystem)}>
              Continue
            </button>
          </Step>
        )}
        {step === 'sex' && (
          <Step title="Biological sex" icon="👥"
            sub="The Widmark formula uses different distribution ratios for men and women.">
            <div className="segmented">
              <button className={draft.sex === 'male' ? 'active' : ''}
                      onClick={() => setDraft({ ...draft, sex: 'male' })}>Male</button>
              <button className={draft.sex === 'female' ? 'active' : ''}
                      onClick={() => setDraft({ ...draft, sex: 'female' })}>Female</button>
            </div>
            <button className="btn full" onClick={() => setStep('notifications')}>Continue</button>
          </Step>
        )}
        {step === 'notifications' && (
          <Step title="Stay in the band" icon="🔔"
            sub="We'll only ping you when your next drink is due. No marketing, no nags.">
            <button className="btn full" onClick={async () => {
              if (typeof Notification !== 'undefined') {
                try { await Notification.requestPermission(); } catch { /* noop */ }
              }
              commit();
            }}>Enable notifications</button>
            <button className="btn secondary full" onClick={() => commit()}>
              Skip for now
            </button>
            <p className="subtitle" style={{ fontSize: 12 }}>
              On iOS Safari, add Sweet Spot to your home screen for notifications to work.
            </p>
          </Step>
        )}
      </div>
    </div>
  );
}

function Step({ title, icon, sub, children }: {
  title: string;
  icon: string;
  sub?: string;
  children: React.ReactNode;
}) {
  return (
    <div className="col" style={{ gap: 18, marginTop: 24 }}>
      <div style={{ fontSize: 56, textAlign: 'center' }}>{icon}</div>
      <h1 className="title center">{title}</h1>
      {sub && <p className="subtitle center">{sub}</p>}
      <div style={{ marginTop: 12 }}>{children}</div>
    </div>
  );
}

function WeightInput({ weightKg, unitSystem, onChange }: {
  weightKg: number;
  unitSystem: 'metric' | 'imperial';
  onChange: (kg: number) => void;
}) {
  const display = unitSystem === 'metric'
    ? `${weightKg.toFixed(0)} kg`
    : `${kgToLb(weightKg).toFixed(0)} lb`;
  const min = unitSystem === 'metric' ? WEIGHT_BOUNDS.minKg : WEIGHT_BOUNDS.minLb;
  const max = unitSystem === 'metric' ? WEIGHT_BOUNDS.maxKg : WEIGHT_BOUNDS.maxLb;
  const value = unitSystem === 'metric' ? weightKg : kgToLb(weightKg);

  return (
    <div className="card" style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
      <div className="title center mono">{display}</div>
      <input
        type="range"
        min={min}
        max={max}
        step={1}
        value={Math.round(value)}
        onChange={(e) => {
          const n = Number(e.target.value);
          onChange(unitSystem === 'metric' ? n : lbToKg(n));
        }}
      />
    </div>
  );
}

function withinBounds(weightKg: number, unit: 'metric' | 'imperial'): boolean {
  if (unit === 'metric') {
    return weightKg >= WEIGHT_BOUNDS.minKg && weightKg <= WEIGHT_BOUNDS.maxKg;
  }
  const lb = kgToLb(weightKg);
  return lb >= WEIGHT_BOUNDS.minLb && lb <= WEIGHT_BOUNDS.maxLb;
}
