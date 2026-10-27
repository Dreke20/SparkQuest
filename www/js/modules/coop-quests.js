/**
 * CoopQuests & StreakManager for SparkQuest
 * Features:
 * 1. Two-player Cooperative Quests inside matches for shared progression.
 * 2. Daily Ember Streak Multiplier to drive high day-over-day retention.
 */

import AudioFX from './audio-fx.js';
import confetti from 'canvas-confetti';

class CoopQuestsEngine {
  constructor() {
    this.milestones = [
      { id: 'msgs', title: 'First Spark', desc: 'Exchange 5 messages', reward: 25, icon: '💬', target: 5 },
      { id: 'minigame', title: 'Playful Vibe', desc: 'Play a mini-game together', reward: 50, icon: '🎮', target: 1 },
      { id: 'itinerary', title: 'Quest Blueprint', desc: 'Generate a date itinerary', reward: 75, icon: '🗺️', target: 1 },
      { id: 'rendezvous', title: 'Rendezvous', desc: 'Check in at a map waypoint', reward: 150, icon: '📍', target: 1 }
    ];
  }

  // Get shared quest state for a match
  getMatchQuestState(matchId) {
    const raw = localStorage.getItem(`sparkquest_coop_${matchId}`);
    if (raw) {
      try {
        return JSON.parse(raw);
      } catch (e) {}
    }
    return {
      msgs: { current: 3, claimed: false },
      minigame: { current: 1, claimed: true },
      itinerary: { current: 0, claimed: false },
      rendezvous: { current: 0, claimed: false }
    };
  }

  saveMatchQuestState(matchId, state) {
    localStorage.setItem(`sparkquest_coop_${matchId}`, JSON.stringify(state));
  }

  // Increment coop progress
  incrementProgress(matchId, milestoneKey, amount = 1) {
    const state = this.getMatchQuestState(matchId);
    if (state[milestoneKey]) {
      state[milestoneKey].current += amount;
      this.saveMatchQuestState(matchId, state);
      this.refreshBanner(matchId);
    }
  }

  // Render Co-Op Quest bar inside Chat Detail
  renderCoopBar(match) {
    const state = this.getMatchQuestState(match.id);
    return `
      <div class="coop-quest-banner" id="coop-banner-${match.id}">
        <div class="coop-header">
          <div class="coop-title-row">
            <span class="coop-badge"><i class="fas fa-handshake-angle"></i> Co-Op Quest</span>
            <span class="coop-subtitle">Earn shared embers together!</span>
          </div>
          <button class="coop-toggle-btn" onclick="window.CoopQuests.toggleDrawer('${match.id}')">
            <i class="fas fa-chevron-down" id="coop-chevron-${match.id}"></i>
          </button>
        </div>
        <div class="coop-milestones-row" id="coop-drawer-${match.id}">
          ${this.milestones.map(m => {
            const current = state[m.id]?.current || 0;
            const claimed = state[m.id]?.claimed || false;
            const completed = current >= m.target;
            return `
              <div class="coop-milestone-pill ${completed ? 'completed' : ''} ${claimed ? 'claimed' : ''}">
                <div class="milestone-icon">${m.icon}</div>
                <div class="milestone-meta">
                  <div class="milestone-name">${m.title}</div>
                  <div class="milestone-progress">${current}/${m.target}</div>
                </div>
                ${completed && !claimed ? `
                  <button class="milestone-claim-btn" onclick="window.CoopQuests.claimMilestone('${match.id}', '${m.id}', ${m.reward})">
                    +${m.reward}🔥
                  </button>
                ` : claimed ? `
                  <span class="milestone-claimed-tag"><i class="fas fa-check"></i></span>
                ` : `
                  <span class="milestone-locked-tag">+${m.reward}</span>
                `}
              </div>
            `;
          }).join('')}
        </div>
      </div>
    `;
  }

  toggleDrawer(matchId) {
    AudioFX.playPop();
    const drawer = document.getElementById(`coop-drawer-${matchId}`);
    const chevron = document.getElementById(`coop-chevron-${matchId}`);
    if (drawer) {
      const isHidden = drawer.style.display === 'none';
      drawer.style.display = isHidden ? 'flex' : 'none';
      if (chevron) {
        chevron.style.transform = isHidden ? 'rotate(0deg)' : 'rotate(180deg)';
      }
    }
  }

  claimMilestone(matchId, milestoneKey, reward) {
    AudioFX.playLevelUp();
    const state = this.getMatchQuestState(matchId);
    if (state[milestoneKey]) {
      state[milestoneKey].claimed = true;
      this.saveMatchQuestState(matchId, state);
    }

    if (typeof window.embers === 'number') {
      window.embers += reward;
      AudioFX.playEmberClaim();
      if (window.DB_Service && window.currentUserUid) {
        window.DB_Service.updateUserStats(window.currentUserUid, { embers: window.embers });
      }
    }

    confetti({
      particleCount: 50,
      spread: 60,
      origin: { y: 0.4 },
      colors: ['#FFB800', '#FF3F6C', '#00E5FF']
    });

    this.refreshBanner(matchId);
  }

  refreshBanner(matchId) {
    const banner = document.getElementById(`coop-banner-${matchId}`);
    if (banner) {
      const parent = banner.parentElement;
      if (parent) {
        banner.outerHTML = this.renderCoopBar({ id: matchId });
      }
    }
  }

  /* ================= DAILY EMBER STREAK ================= */

  getStreakInfo() {
    const raw = localStorage.getItem('sparkquest_streak_data');
    const now = new Date();
    const todayStr = now.toISOString().split('T')[0];

    let data = { count: 1, lastDate: '', claimedToday: false };
    if (raw) {
      try {
        data = JSON.parse(raw);
      } catch (e) {}
    }

    if (data.lastDate === todayStr) {
      data.claimedToday = true;
    } else {
      // Check if yesterday was skipped
      const yesterday = new Date(now);
      yesterday.setDate(now.getDate() - 1);
      const yesterdayStr = yesterday.toISOString().split('T')[0];

      if (data.lastDate === yesterdayStr) {
        data.claimedToday = false;
      } else if (data.lastDate && data.lastDate !== todayStr) {
        // Streak broken
        data.count = 1;
        data.claimedToday = false;
      }
    }

    // Multiplier calculation
    let multiplier = 1.0;
    if (data.count >= 7) multiplier = 2.0;
    else if (data.count >= 5) multiplier = 1.5;
    else if (data.count >= 3) multiplier = 1.25;
    else if (data.count >= 2) multiplier = 1.1;

    return { ...data, multiplier };
  }

  // Renders small streak fire pill in app top bar
  renderHeaderStreakBadge() {
    const streak = this.getStreakInfo();
    return `
      <div class="header-streak-badge" id="header-streak-pill" onclick="window.CoopQuests.openStreakModal()">
        <span class="streak-fire">🔥</span>
        <span class="streak-count">${streak.count}d</span>
        <span class="streak-mult">${streak.multiplier}x</span>
      </div>
    `;
  }

  openStreakModal() {
    AudioFX.playPop();
    const streak = this.getStreakInfo();
    const baseReward = 20;
    const finalReward = Math.round(baseReward * streak.multiplier);

    const existing = document.getElementById('streak-modal');
    if (existing) existing.remove();

    const modal = document.createElement('div');
    modal.id = 'streak-modal';
    modal.className = 'custom-module-modal active';
    modal.innerHTML = `
      <div class="modal-card streak-card">
        <div class="modal-header">
          <div class="streak-header-title">
            <span class="streak-title-fire">🔥</span>
            <h3>Daily Spark Streak</h3>
          </div>
          <button class="close-modal-btn" onclick="document.getElementById('streak-modal').remove()">&times;</button>
        </div>
        <div class="streak-content">
          <div class="streak-hero-display">
            <div class="streak-hero-count">${streak.count}</div>
            <div class="streak-hero-label">Days in a Row</div>
            <div class="streak-multiplier-badge">${streak.multiplier}x Ember Multiplier Active</div>
          </div>

          <div class="streak-track-row">
            ${[1, 2, 3, 4, 5, 6, 7].map(day => `
              <div class="streak-day-step ${day < streak.count ? 'completed' : day === streak.count ? 'current' : 'upcoming'}">
                <span class="step-num">D${day}</span>
                <span class="step-icon">${day === 7 ? '🎁' : day <= streak.count ? '🔥' : '🔒'}</span>
                <span class="step-bonus">${day === 7 ? '2.0x' : day >= 5 ? '1.5x' : day >= 3 ? '1.2x' : '1.0x'}</span>
              </div>
            `).join('')}
          </div>

          <div class="streak-reward-box">
            <span>Today's Login Reward:</span>
            <strong>+${finalReward} Embers 🔥</strong>
          </div>

          <button class="action-btn-primary streak-claim-action" ${streak.claimedToday ? 'disabled' : ''} onclick="window.CoopQuests.claimDailyStreak(${finalReward})">
            ${streak.claimedToday ? '<i class="fas fa-check"></i> Claimed for Today' : '<i class="fas fa-gift"></i> Claim Today\'s Embers'}
          </button>
        </div>
      </div>
    `;
    document.body.appendChild(modal);
  }

  claimDailyStreak(reward) {
    const streak = this.getStreakInfo();
    if (streak.claimedToday) return;

    AudioFX.playLevelUp();
    const todayStr = new Date().toISOString().split('T')[0];
    const newData = {
      count: streak.count + 1,
      lastDate: todayStr,
      claimedToday: true
    };
    localStorage.setItem('sparkquest_streak_data', JSON.stringify(newData));

    if (typeof window.embers === 'number') {
      window.embers += reward;
      AudioFX.playEmberClaim();
      if (window.DB_Service && window.currentUserUid) {
        window.DB_Service.updateUserStats(window.currentUserUid, { embers: window.embers });
      }
    }

    confetti({
      particleCount: 80,
      spread: 70,
      origin: { y: 0.5 },
      colors: ['#FFB800', '#FF3F6C', '#00E5FF']
    });

    const modal = document.getElementById('streak-modal');
    if (modal) modal.remove();

    // Update header pill
    const headerPill = document.getElementById('header-streak-pill');
    if (headerPill) {
      headerPill.outerHTML = this.renderHeaderStreakBadge();
    }
  }
}

const CoopQuests = new CoopQuestsEngine();
export default CoopQuests;
