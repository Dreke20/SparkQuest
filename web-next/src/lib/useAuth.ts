import { useEffect, useState } from 'react';
import { supabase } from './supabase';
import { User } from '@supabase/supabase-js';

export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  const [userData, setUserData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      if (session?.user) {
        fetchUserData(session.user.id);
      } else {
        setLoading(false);
      }
    });

    // Listen for changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
      if (session?.user) {
        fetchUserData(session.user.id);
      } else {
        setUserData(null);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  const fetchUserData = async (uid: string) => {
    const { data } = await supabase.from('users').select('*').eq('id', uid).single();
    if (data) setUserData(data);
    setLoading(false);
  };

  const loginAnonymously = async () => {
    setLoading(true);
    const { data, error } = await supabase.auth.signInAnonymously();
    if (error) console.error("Login failed:", error);
    // User record is created in Supabase trigger or handled manually later
    return data;
  };

  return { user, userData, loading, loginAnonymously, fetchUserData };
}
