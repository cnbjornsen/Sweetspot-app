import { useState } from 'react';
import { AppStateHookResult } from '../hooks/useAppState';
import { defaultProfile } from '../store/store';
import { kgToLb, lbToKg, WEIGHT_BOUNDS } from '../core/locale';
import { BiologicalSex } from '../core/types';

type Step = 'age' | 'disclaimer' | 'units' | 'weight' | 'sex' | 'notifications';

export function Onboarding({ app }: { app: AppStateHookResult }) {
  const [step, setStep] = useState<Step>('age');
  const [draft, setDraft] = useState(() => app.state.profile ?? defaultProfile());
  // Track whether the user has explicitly set these — so they can't sleepwalk
  // past the screens with defaults.
  const [weightTouched, setWeightTouched] = useState(false);
  const [sexChoice, setSexChoice] = useState<BiologicalSex | null>(null);

  function commit() {
    app.upsertProfile(() => ({
      ...draft,
      sex: sexChoice ?? draft.sex,
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
            sub="The single number that drives the BAC math. Type it in.">
            <WeightInput
              weightKg={draft.weightKg}
              unitSystem={draft.unitSystem}
              touched={weightTouched}
              onChange={(kg) => { setDraft({ ...draft, weightKg: kg }); setWeightTouched(true); }}
            />
            {!weightTouched && (
              <p className="notice">Please confirm your weight — defaults are just placeholders.</p>
            )}
            <button className="btn full" onClick={() => setStep('sex')}
                    disabled={!weightTouched || !withinBounds(draft.weightKg, draft.unitSystem)}>
              Continue
            </button>
          </Step>
        )}
        {step === 'sex' && (
          <Step title="Biological sex" icon="👥"
            sub="The Widmark formula uses different distribution ratios for men and women. We have to ask.">
            <div className="col" style={{ gap: 10 }}>
              <SexChoiceButton label="Male" emoji="♂️"
                selected={sexChoice === 'male'}
                onClick={() => setSexChoice('male')} />
              <SexChoiceButton label="Female" emoji="♀️"
                selected={sexChoice === 'female'}
                onClick={() => setSexChoice('female')} />
            </div>
            {sexChoice === null && (
              <p className="notice">Pick one to continue.</p>
            )}
            <button className="btn full"
                    disabled={sexChoice === null}
                    onClick={() => {
                      if (sexChoice) setDraft({ ...draft, sex: sexChoice });
                      setStep('notifications');
                    }}>
              Continue
            </button>
          </Step>
        )}
        {step === 'notifications' && (
          <Step title="Stay in the band" icon="🔔"
            sub="We'll only ping you when your next drink is due. No marketing, no nags.">
            <SummaryCard draft={draft} sex={sexChoice ?? draft.sex} />
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

function WeightInput({ weightKg, unitSystem, touched, onChange }: {
  weightKg: number;
  unitSystem: 'metric' | 'imperial';
  touched: boolean;
  onChange: (kg: number) => void;
}) {
  const display = unitSystem === 'metric' ? weightKg : kgToLb(weightKg);
  const min = unitSystem === 'metric' ? WEIGHT_BOUNDS.minKg : WEIGHT_BOUNDS.minLb;
  const max = unitSystem === 'metric' ? WEIGHT_BOUNDS.maxKg : WEIGHT_BOUNDS.maxLb;
  const suffix = unitSystem === 'metric' ? 'kg' : 'lb';

  return (
    <div className="card" style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'center', gap: 8 }}>
        <input
          type="number"
          value={touched ? Math.round(display) : ''}
          placeholder={String(Math.round(display))}
          min={min}
          max={max}
          step={1}
          inputMode="numeric"
          onChange={(e) => {
            const n = Number(e.target.value);
            if (Number.isFinite(n) && n > 0) {
              onChange(unitSystem === 'metric' ? n : lbToKg(n));
            }
          }}
          style={{
            background: 'transparent',
            border: 'none',
            outline: 'none',
            fontSize: 48,
            fontWeight: 800,
            width: 140,
            textAlign: 'right',
            color: touched ? '#fff' : 'rgba(255,255,255,0.45)',
            fontVariantNumeric: 'tabular-nums',
          }}
        />
        <span style={{ fontSize: 20, color: 'rgba(255,255,255,0.7)' }}>{suffix}</span>
      </div>
      <input
        type="range"
        min={min}
        max={max}
        step={1}
        value={Math.round(display)}
        onChange={(e) => {
          const n = Number(e.target.value);
          onChange(unitSystem === 'metric' ? n : lbToKg(n));
        }}
      />
    </div>
  );
}

function SexChoiceButton({ label, emoji, selected, onClick }: {
  label: string;
  emoji: string;
  selected: boolean;
  onClick: () => void;
}) {
  return (
    <button
      onClick={onClick}
      style={{
        padding: '18px 16px',
        borderRadius: 14,
        background: selected ? 'rgba(255,255,255,0.95)' : 'rgba(0,0,0,0.25)',
        color: selected ? '#0e0a1f' : '#fff',
        fontSize: 18,
        fontWeight: 600,
        border: selected ? '2px solid #fff' : '2px solid rgba(255,255,255,0.25)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 10,
      }}>
      <span style={{ fontSize: 22 }}>{emoji}</span>
      <span>{label}</span>
      {selected && <span style={{ marginLeft: 8 }}>✓</span>}
    </button>
  );
}

function SummaryCard({ draft, sex }: {
  draft: { weightKg: number; unitSystem: 'metric' | 'imperial' };
  sex: BiologicalSex;
}) {
  const weightDisplay = draft.unitSystem === 'metric'
    ? `${Math.round(draft.weightKg)} kg`
    : `${Math.round(kgToLb(draft.weightKg))} lb`;
  return (
    <div className="card">
      <div className="h3" style={{ marginBottom: 8 }}>Your numbers</div>
      <div className="spread"><span>Weight</span><strong className="mono">{weightDisplay}</strong></div>
      <div className="spread"><span>Sex</span><strong>{sex === 'male' ? 'Male' : 'Female'}</strong></div>
      <p className="subtitle" style={{ fontSize: 12, marginTop: 8 }}>
        You can change these in Settings any time.
      </p>
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
