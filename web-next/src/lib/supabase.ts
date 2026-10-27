import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://xawlzthaqwaiclvpkfzw.supabase.co';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhhd2x6dGhhcXdhaWNsdnBrZnp3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEyNjM1ODksImV4cCI6MjEwNjgzOTU4OX0.3qtPp540OY3XJmkzfm-EcbDBsFhOPASswLSdyBSMQuQ';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
