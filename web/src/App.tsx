import { useState } from 'react';
import { useAppState } from './hooks/useAppState';
import { Onboarding } from './components/Onboarding';
import { ActiveSession } from './components/ActiveSession';
import { NewSession } from './components/NewSession';
import { History } from './components/History';
import { Settings } from './components/Settings';
import { MidIntervalSheet } from './components/MidIntervalSheet';
import { profileHasCompletedOnboarding } from './core/types';
import { unlockAudio } from './core/sound';

type Tab = 'session' | 'history' | 'settings';

export function App() {
  const app = useAppState();
  const [tab, setTab] = useState<Tab>('session');

  if (!app.state.profile || !profileHasCompletedOnboarding(app.state.profile)) {
    return <Onboarding app={app} />;
  }

  const inSession = !!app.activeSession;

  return (
    <div className={`app-shell ${inSession ? 'bg-festive' : 'bg-calm'}`}
         onClickCapture={() => unlockAudio()}>
      {tab === 'session' && (inSession ? <ActiveSession app={app} /> : <NewSession app={app} />)}
      {tab === 'history' && <History app={app} />}
      {tab === 'settings' && <Settings app={app} />}
      <nav className="tab-bar">
        <button className={`tab-btn ${tab === 'session' ? 'active' : ''}`}
                onClick={() => setTab('session')}>
          <span className="ico">🥂</span>
          <span>Session</span>
        </button>
        <button className={`tab-btn ${tab === 'history' ? 'active' : ''}`}
                onClick={() => setTab('history')}>
          <span className="ico">📈</span>
          <span>History</span>
        </button>
        <button className={`tab-btn ${tab === 'settings' ? 'active' : ''}`}
                onClick={() => setTab('settings')}>
          <span className="ico">⚙️</span>
          <span>Settings</span>
        </button>
      </nav>
      {app.midIntervalCheckDue && <MidIntervalSheet app={app} />}
    </div>
  );
}
