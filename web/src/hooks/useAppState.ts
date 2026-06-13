import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import confetti from 'canvas-confetti';
import {
  Drink,
  DrinkType,
  Occasion,
  Session,
  SessionMode,
  UserProfile,
  profileBACProfile,
  ethanolGramsFor,
  SnapshotState,
} from '../core/types';
import { BACTimeline, soberTime } from '../core/widmark';
import { planSchedule, ScheduledDrink } from '../core/planner';
import { AppState, defaultProfile, loadState, saveState } from '../store/store';
import { playFanfare } from '../core/sound';

const NEXT_DRINK_NOTIFICATION_TAG = 'sweetspot.next-drink';

export interface DerivedState {
  schedule: ScheduledDrink[];
  nextDrinkAt: number | undefined;
  currentBAC: number;
  peakBAC: number;
  soberAt: number | undefined;
  snapshotState: SnapshotState;
  fanfarePending: boolean;
}

export interface AppStateHookResult {
  state: AppState;
  derived: DerivedState;
  activeSession: Session | undefined;
  // Mutations
  upsertProfile: (mutate: (p: UserProfile) => UserProfile) => void;
  startSession: (occasionId: string | undefined, mode: SessionMode) => void;
  endSession: () => void;
  logScheduledDrink: (type?: DrinkType, multiplier?: number) => void;
  logExtraDrink: (type: DrinkType, multiplier?: number, customGrams?: number) => void;
  logWater: () => void;
  undoLastDrink: () => void;
  deleteDrink: (id: string) => void;
  addOccasion: (name: string, emoji?: string) => Occasion;
  deleteOccasion: (id: string) => void;
  toggleFavoriteOccasion: (id: string) => void;
  clearAllData: () => void;
  midIntervalCheckDue: boolean;
  dismissMidIntervalCheck: (snoozeForSession: boolean) => void;
  // Helpers
  bacAt: (t: number) => number;
}

export function useAppState(): AppStateHookResult {
  const [state, setState] = useState<AppState>(() => loadState());
  const [tick, setTick] = useState(0);
  const lastFanfareSlot = useRef<number | undefined>(undefined);
  const lastMidIntervalAt = useRef<number>(Date.now());
  const [midIntervalCheckDue, setMidIntervalCheckDue] = useState(false);
  const midSnoozedForSession = useRef(false);

  useEffect(() => {
    saveState(state);
  }, [state]);

  // 1Hz tick while a session is active
  useEffect(() => {
    if (!state.activeSessionId) return;
    const handle = window.setInterval(() => setTick((t) => t + 1), 1000);
    return () => window.clearInterval(handle);
  }, [state.activeSessionId]);

  const activeSession = useMemo(
    () => state.sessions.find((s) => s.id === state.activeSessionId),
    [state.sessions, state.activeSessionId],
  );

  const derived = useMemo<DerivedState>(() => {
    if (!activeSession || !state.profile) {
      return {
        schedule: [],
        nextDrinkAt: undefined,
        currentBAC: 0,
        peakBAC: 0,
        soberAt: undefined,
        snapshotState: 'idle',
        fanfarePending: false,
      };
    }
    const now = Date.now();
    void tick; // ensure recompute on each tick
    const bacProfile = profileBACProfile(state.profile);
    const timeline = new BACTimeline(activeSession.drinks, bacProfile);
    const currentBAC = timeline.bacAt(now);
    const peakBAC = Math.max(activeSession.peakBAC, currentBAC);
    const sober = soberTime(timeline, now);
    const schedule = planSchedule({
      profile: bacProfile,
      mode: activeSession.mode,
      now,
      alreadyConsumed: activeSession.drinks,
    });
    const next = schedule[0]?.scheduledAt;
    const snapshotState: SnapshotState = computeState(activeSession, next, now);
    return {
      schedule,
      nextDrinkAt: next,
      currentBAC,
      peakBAC,
      soberAt: sober,
      snapshotState,
      fanfarePending: next !== undefined && next <= now,
    };
  }, [activeSession, state.profile, tick]);

  // Fanfare + confetti + notification when crossing the next slot
  useEffect(() => {
    if (!derived.fanfarePending || derived.nextDrinkAt === undefined) return;
    if (lastFanfareSlot.current === derived.nextDrinkAt) return;
    lastFanfareSlot.current = derived.nextDrinkAt;
    if (state.profile?.fanfareEnabled) {
      playFanfare();
    }
    fireConfetti();
    showNextDrinkNotification();
  }, [derived.fanfarePending, derived.nextDrinkAt, state.profile?.fanfareEnabled]);

  // Mid-interval check timer
  useEffect(() => {
    if (!activeSession || !state.profile) return;
    if (state.profile.midIntervalCheckMinutes <= 0) return;
    midSnoozedForSession.current = false;
    lastMidIntervalAt.current = Date.now();
    const intervalMs = state.profile.midIntervalCheckMinutes * 60_000;
    const handle = window.setInterval(() => {
      if (midSnoozedForSession.current) return;
      if (Date.now() - lastMidIntervalAt.current >= intervalMs) {
        lastMidIntervalAt.current = Date.now();
        setMidIntervalCheckDue(true);
      }
    }, 30_000);
    return () => window.clearInterval(handle);
  }, [activeSession?.id, state.profile?.midIntervalCheckMinutes]);

  const upsertProfile: AppStateHookResult['upsertProfile'] = useCallback((mutate) => {
    setState((prev) => {
      const current = prev.profile ?? defaultProfile();
      return { ...prev, profile: mutate(current) };
    });
  }, []);

  const startSession: AppStateHookResult['startSession'] = useCallback((occasionId, mode) => {
    setState((prev) => {
      const id = makeId();
      const session: Session = {
        id,
        occasionId,
        startedAt: Date.now(),
        mode,
        drinks: [],
        peakBAC: 0,
        minutesInSweetSpot: 0,
        unscheduledExtrasCount: 0,
        waterCount: 0,
      };
      const occasions = prev.occasions.map((o) =>
        o.id === occasionId ? { ...o, lastUsedAt: Date.now() } : o,
      );
      return {
        ...prev,
        sessions: [...prev.sessions, session],
        occasions,
        activeSessionId: id,
      };
    });
    lastFanfareSlot.current = undefined;
    midSnoozedForSession.current = false;
  }, []);

  const endSession: AppStateHookResult['endSession'] = useCallback(() => {
    setState((prev) => {
      if (!prev.activeSessionId || !prev.profile) return prev;
      const now = Date.now();
      const sessions = prev.sessions.map((s) => {
        if (s.id !== prev.activeSessionId) return s;
        const bacProfile = profileBACProfile(prev.profile!);
        const timeline = new BACTimeline(s.drinks, bacProfile);
        const peakBAC = timeline.peakBACIn(s.startedAt, now);
        const minutesInSweetSpot = timeline.minutesAtOrBelow(0.05, s.startedAt, now);
        const waterCount = s.drinks.filter((d) => d.type === 'water').length;
        const unscheduledExtrasCount = s.drinks.filter(
          (d) => !d.wasScheduled && d.type !== 'water',
        ).length;
        const sober = soberTime(timeline, now);
        return {
          ...s,
          endedAt: now,
          peakBAC,
          minutesInSweetSpot,
          unscheduledExtrasCount,
          waterCount,
          soberAt: sober,
          endReason: 'user' as const,
        };
      });
      return { ...prev, sessions, activeSessionId: null };
    });
  }, []);

  const insertDrink = useCallback(
    (type: DrinkType, multiplier: number, customGrams: number | undefined, scheduled: boolean) => {
      setState((prev) => {
        if (!prev.activeSessionId || !prev.profile) return prev;
        const bacProfile = profileBACProfile(prev.profile);
        const ethanolGrams = ethanolGramsFor(type, bacProfile, {
          multiplier,
          customEthanolGrams: customGrams,
        });
        const drink: Drink = {
          id: makeId(),
          timestamp: Date.now(),
          type,
          ethanolGrams,
          sizeMultiplier: multiplier,
          wasScheduled: scheduled,
        };
        const sessions = prev.sessions.map((s) =>
          s.id === prev.activeSessionId ? { ...s, drinks: [...s.drinks, drink] } : s,
        );
        return { ...prev, sessions };
      });
      if (scheduled) {
        fireConfetti();
      }
    },
    [],
  );

  const logScheduledDrink: AppStateHookResult['logScheduledDrink'] = useCallback(
    (type = 'beer12oz', multiplier = 1) => {
      insertDrink(type, multiplier, undefined, true);
      lastFanfareSlot.current = undefined; // allow next slot's fanfare
    },
    [insertDrink],
  );

  const logExtraDrink: AppStateHookResult['logExtraDrink'] = useCallback(
    (type, multiplier = 1, customGrams) => {
      insertDrink(type, multiplier, customGrams, false);
    },
    [insertDrink],
  );

  const logWater: AppStateHookResult['logWater'] = useCallback(() => {
    insertDrink('water', 1, undefined, false);
  }, [insertDrink]);

  const undoLastDrink: AppStateHookResult['undoLastDrink'] = useCallback(() => {
    setState((prev) => {
      if (!prev.activeSessionId) return prev;
      const sessions = prev.sessions.map((s) => {
        if (s.id !== prev.activeSessionId) return s;
        const sorted = [...s.drinks].sort((a, b) => a.timestamp - b.timestamp);
        sorted.pop();
        return { ...s, drinks: sorted };
      });
      return { ...prev, sessions };
    });
  }, []);

  const deleteDrink: AppStateHookResult['deleteDrink'] = useCallback((id) => {
    setState((prev) => {
      const sessions = prev.sessions.map((s) => ({
        ...s,
        drinks: s.drinks.filter((d) => d.id !== id),
      }));
      return { ...prev, sessions };
    });
  }, []);

  const addOccasion: AppStateHookResult['addOccasion'] = useCallback((name, emoji = '🎉') => {
    const occasion: Occasion = {
      id: makeId(),
      name,
      emoji,
      lastUsedAt: Date.now(),
      isFavorite: false,
      isTemplate: false,
    };
    setState((prev) => ({ ...prev, occasions: [...prev.occasions, occasion] }));
    return occasion;
  }, []);

  const deleteOccasion: AppStateHookResult['deleteOccasion'] = useCallback((id) => {
    setState((prev) => ({ ...prev, occasions: prev.occasions.filter((o) => o.id !== id) }));
  }, []);

  const toggleFavoriteOccasion: AppStateHookResult['toggleFavoriteOccasion'] = useCallback((id) => {
    setState((prev) => ({
      ...prev,
      occasions: prev.occasions.map((o) =>
        o.id === id ? { ...o, isFavorite: !o.isFavorite } : o,
      ),
    }));
  }, []);

  const clearAllData: AppStateHookResult['clearAllData'] = useCallback(() => {
    setState({
      profile: null,
      occasions: loadState().occasions, // reseeded templates
      sessions: [],
      activeSessionId: null,
    });
  }, []);

  const dismissMidIntervalCheck: AppStateHookResult['dismissMidIntervalCheck'] = useCallback(
    (snoozeForSession) => {
      if (snoozeForSession) midSnoozedForSession.current = true;
      setMidIntervalCheckDue(false);
    },
    [],
  );

  const bacAt = useCallback(
    (t: number) => {
      if (!activeSession || !state.profile) return 0;
      const timeline = new BACTimeline(activeSession.drinks, profileBACProfile(state.profile));
      return timeline.bacAt(t);
    },
    [activeSession, state.profile],
  );

  return {
    state,
    derived,
    activeSession,
    upsertProfile,
    startSession,
    endSession,
    logScheduledDrink,
    logExtraDrink,
    logWater,
    undoLastDrink,
    deleteDrink,
    addOccasion,
    deleteOccasion,
    toggleFavoriteOccasion,
    clearAllData,
    midIntervalCheckDue,
    dismissMidIntervalCheck,
    bacAt,
  };
}

function computeState(session: Session, nextDrinkAt: number | undefined, now: number): SnapshotState {
  if (session.endedAt) return 'ended';
  if (nextDrinkAt !== undefined && nextDrinkAt <= now) return 'readyForDrink';
  if (session.mode.kind === 'peakThenMaintain' && now > session.mode.peak) {
    if (nextDrinkAt !== undefined && nextDrinkAt > session.mode.peak) return 'maintenance';
  }
  if (now > session.mode.end) return 'coastingHome';
  return 'waiting';
}

function fireConfetti() {
  if (typeof window === 'undefined') return;
  const fire = (particleRatio: number, opts: confetti.Options) => {
    confetti({
      origin: { y: 0.7 },
      ...opts,
      particleCount: Math.floor(200 * particleRatio),
      scalar: 1.2,
    });
  };
  fire(0.25, { spread: 26, startVelocity: 55 });
  fire(0.2, { spread: 60 });
  fire(0.35, { spread: 100, decay: 0.91, scalar: 0.8 });
  fire(0.1, { spread: 120, startVelocity: 25, decay: 0.92, scalar: 1.2 });
  fire(0.1, { spread: 120, startVelocity: 45 });
}

function showNextDrinkNotification() {
  if (typeof Notification === 'undefined') return;
  if (Notification.permission !== 'granted') return;
  try {
    new Notification('Sweet Spot', {
      body: 'Time for your next drink 🍻',
      tag: NEXT_DRINK_NOTIFICATION_TAG,
      requireInteraction: false,
    });
  } catch {
    // Some browsers throw without a service worker — ignore.
  }
}

function makeId(): string {
  if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) return crypto.randomUUID();
  return Math.random().toString(36).slice(2);
}
