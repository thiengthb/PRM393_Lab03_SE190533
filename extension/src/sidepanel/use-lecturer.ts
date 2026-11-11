import { useCallback, useEffect, useState } from 'react';

import {
  isBackendEnabled,
  isGoogleSignInEnabled,
  loadSession,
  signIn as signInRequest,
  signInWithGoogle as googleRequest,
  signOut as signOutRequest,
  type LecturerSession,
} from '@/lib/sources/backend';

export function useLecturer() {
  const enabled = isBackendEnabled();
  const [session, setSession] = useState<LecturerSession | null>(null);
  const [restoring, setRestoring] = useState(enabled);

  useEffect(() => {
    if (!enabled) return;
    let alive = true;
    void loadSession()
      .then((value) => alive && setSession(value))
      .finally(() => alive && setRestoring(false));
    return () => {
      alive = false;
    };
  }, [enabled]);

  const signIn = useCallback(async (email: string, password: string) => {
    setSession(await signInRequest(email, password));
  }, []);

  const signInWithGoogle = useCallback(async () => {
    setSession(await googleRequest());
  }, []);

  const signOut = useCallback(async () => {
    await signOutRequest();
    setSession(null);
  }, []);

  return {
    enabled,
    googleEnabled: isGoogleSignInEnabled(),
    session,
    restoring,
    signIn,
    signInWithGoogle,
    signOut,
  };
}

export type Lecturer = ReturnType<typeof useLecturer>;
