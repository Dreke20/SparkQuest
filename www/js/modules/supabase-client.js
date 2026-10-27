/**
 * SparkQuest Supabase Client Service
 * Project Ref: kqvjntbiagzywstijtsz
 * Real-time REST & PostgREST Client for Live Profiles, Matches, Quests & Messages.
 */

const SUPABASE_CONFIG = {
  url: 'https://kqvjntbiagzywstijtsz.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtxdmpudGJpYWd6eXdzdGlqdHN6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMxMjMzNzIsImV4cCI6MjEwODY5OTM3Mn0.Hwh0Rkdiu1SuZXmsyxshnbkwAviG46PM-yT8kbvp62E',
  projectRef: 'kqvjntbiagzywstijtsz'
};

export const SupabaseClient = {
  config: SUPABASE_CONFIG,
  isConnected: false,
  cachedProfiles: [],

  async init() {
    console.log('[Supabase] Initializing client for project:', this.config.projectRef);
    try {
      const res = await this.get('profiles?select=count');
      this.isConnected = true;
      console.log('[Supabase] Connected successfully to kqvjntbiagzywstijtsz');
      this.updateStatusBadge(true);
    } catch (e) {
      console.warn('[Supabase] Connection test fallback:', e);
      this.isConnected = false;
      this.updateStatusBadge(false);
    }
  },

  getHeaders() {
    return {
      'apikey': this.config.anonKey,
      'Authorization': `Bearer ${this.config.anonKey}`,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation'
    };
  },

  async get(endpoint) {
    const response = await fetch(`${this.config.url}/rest/v1/${endpoint}`, {
      method: 'GET',
      headers: this.getHeaders()
    });
    if (!response.ok) {
      throw new Error(`Supabase GET error: ${response.status} ${response.statusText}`);
    }
    return await response.json();
  },

  async post(endpoint, data) {
    const response = await fetch(`${this.config.url}/rest/v1/${endpoint}`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify(data)
    });
    if (!response.ok) {
      throw new Error(`Supabase POST error: ${response.status} ${response.statusText}`);
    }
    return await response.json();
  },

  async patch(endpoint, data) {
    const response = await fetch(`${this.config.url}/rest/v1/${endpoint}`, {
      method: 'PATCH',
      headers: this.getHeaders(),
      body: JSON.stringify(data)
    });
    if (!response.ok) {
      throw new Error(`Supabase PATCH error: ${response.status} ${response.statusText}`);
    }
    return await response.json();
  },

  // --- Profile Queries ---
  async fetchProfiles() {
    try {
      const data = await this.get('profiles?select=*&order=created_at.desc');
      if (Array.isArray(data) && data.length > 0) {
        this.cachedProfiles = data;
        return data;
      }
    } catch (e) {
      console.warn('[Supabase] fetchProfiles fallback to local cache:', e);
    }
    return this.cachedProfiles;
  },

  async updateVerification(userId, isVerified) {
    try {
      return await this.patch(`profiles?user_id=eq.${userId}`, { is_verified: isVerified });
    } catch (e) {
      console.warn('[Supabase] updateVerification local fallback:', e);
    }
  },

  async updateVip(userId, isVip) {
    try {
      return await this.patch(`profiles?user_id=eq.${userId}`, { is_vip: isVip });
    } catch (e) {
      console.warn('[Supabase] updateVip local fallback:', e);
    }
  },

  // --- Matches & Messages ---
  async fetchMatches() {
    try {
      return await this.get('matches?select=*&order=created_at.desc');
    } catch (e) {
      console.warn('[Supabase] fetchMatches fallback:', e);
      return [];
    }
  },

  async fetchMessages(matchId) {
    try {
      return await this.get(`messages?match_id=eq.${matchId}&order=created_at.asc`);
    } catch (e) {
      console.warn('[Supabase] fetchMessages fallback:', e);
      return [];
    }
  },

  async sendMessage(matchId, senderId, content, isVoice = false, durationSec = 0) {
    try {
      return await this.post('messages', {
        match_id: matchId,
        sender_id: senderId,
        content: content,
        is_voice: isVoice,
        duration_sec: durationSec
      });
    } catch (e) {
      console.warn('[Supabase] sendMessage local fallback:', e);
      return null;
    }
  },

  // --- Co-Op Quests ---
  async fetchCoopQuests(matchId) {
    try {
      return await this.get(`coop_quests?match_id=eq.${matchId}`);
    } catch (e) {
      console.warn('[Supabase] fetchCoopQuests fallback:', e);
      return [];
    }
  },

  // --- Spark Pass Tiers ---
  async fetchSparkPassTiers() {
    try {
      return await this.get('spark_pass_tiers?select=*&order=tier.asc');
    } catch (e) {
      console.warn('[Supabase] fetchSparkPassTiers fallback:', e);
      return [];
    }
  },

  // --- Live Status UI Badge ---
  updateStatusBadge(isOnline) {
    const badge = document.getElementById('supabase-status-badge');
    if (badge) {
      badge.innerHTML = isOnline
        ? `<span style="color:#10b981;">●</span> Supabase Cloud`
        : `<span style="color:#f59e0b;">●</span> Supabase Local`;
      badge.title = `Project: ${this.config.projectRef}`;
    }
  }
};

export default SupabaseClient;
