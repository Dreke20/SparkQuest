import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js/+esm';

// TODO: Replace these with your actual Supabase project URL and anon key
const supabaseUrl = 'https://xawlzthaqwaiclvpkfzw.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhhd2x6dGhhcXdhaWNsdnBrZnp3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEyNjM1ODksImV4cCI6MjEwNjgzOTU4OX0.3qtPp540OY3XJmkzfm-EcbDBsFhOPASswLSdyBSMQuQ';


export const supabase = createClient(supabaseUrl, supabaseAnonKey);
