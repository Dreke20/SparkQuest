/**
 * SparkPass Module for SparkQuest
 * 30-Tier Seasonal Quest Progression Pass with XP Tracking, Daily Quests & VIP Rewards.
 */

import AudioFX from './audio-fx.js';
import confetti from 'canvas-confetti';

export const SparkPass = {
  currentXP: 450,
  currentLevel: 4,
  isVipUnlocked: false,
  claimedTiers: [1, 2, 3],

  tiers: [
    { tier: 1, title: 'Novice Wanderer', reqXP: 0, reward: '50 Embers', icon: '🔥', type: 'embers', vip: false },
    { tier: 2, title: 'Matchmaker Initiate', reqXP: 100, reward: '100 Embers', icon: '🔥', type: 'embers', vip: false },
    { tier: 3, title: 'Cyberpunk Glow', reqXP: 250, reward: '⚡ Cyberpunk Ring', icon: '⚡', type: 'frame', vip: false },
    { tier: 4, title: 'Explorer Keen', reqXP: 450, reward: '2x Ember Booster (1h)', icon: '🚀', type: 'booster', vip: false },
    { tier: 5, title: 'Phoenix Rising', reqXP: 700, reward: '🔥 Phoenix Flame', icon: '🔥', type: 'frame', vip: false },
    { tier: 6, title: 'Quest Veteran', reqXP: 1000, reward: '250 Embers', icon: '🔥', type: 'embers', vip: false },
    { tier: 7, title: 'Golden Spotlight', reqXP: 1400, reward: 'Profile Spotlight (30m)', icon: '🌟', type: 'booster', vip: true },
    { tier: 8, title: 'Galactic Aura', reqXP: 1900, reward: '🌌 Galactic Aura', icon: '🌌', type: 'frame', vip: false },
    { tier: 9, title: 'Urban Legend', reqXP: 2500, reward: '500 Embers', icon: '🔥', type: 'embers', vip: false },
    { tier: 10, title: 'Neon Sovereign', reqXP: 3200, reward: '👑 Neon Crown', icon: '👑', type: 'frame', vip: true },
    { tier: 11, title: 'Night Scout', reqXP: 4000, reward: '150 Embers', icon: '🔥', type: 'embers', vip: false },
    { tier: 12, title: 'Prism Mirage', reqXP: 4900, reward: '💎 Diamond Badge', icon: '💎', type: 'badge', vip: false },
    { tier: 13, title: 'Date Maestro', reqXP: 5900, reward: '3x Super Sparks', icon: '✨', type: 'booster', vip: true },
    { tier: 14, title: 'Cosmic Voyager', reqXP: 7000, reward: '350 Embers', icon: '🔥', type: 'embers', vip: false },
    { tier: 15, title: 'Celestial Spark', reqXP: 8200, reward: '✨ Stardust Frame', icon: '✨', type: 'frame', vip: true },
    { tier: 16, title: 'Vibe Master', reqXP: 9500, reward: '200 Embers', icon: '🔥', type: 'embers', vip: false },
    { tier: 17, title: 'Double Rainbow', reqXP: 11000, reward: '5x Rewinds', icon: '⏪', type: 'booster', vip: false },
    { tier: 18, title: 'Midnight Legend', reqXP: 12600, reward: '600 Embers', icon: '🔥', type: 'embers', vip: false },
    { tier: 19, title: 'Solar Flare', reqXP: 14300, reward: '☀️ Solar Flame Frame', icon: '☀️', type: 'frame', vip: true },
    { tier: 20, title: 'Grandmaster Seeker', reqXP: 16100, reward: '1,000 Embers + Title', icon: '🏆', type: 'badge', vip: false },
    { tier: 21, title: 'Neon Phantom', reqXP: 18000, reward: '300 Embers', icon: '🔥', type: 'embers', vip: false },
    { tier: 22, title: 'Chronos Shifter', reqXP: 20000, reward: 'Unlimited Rewinds (24h)', icon: '⏳', type: 'booster', vip: true },
    { tier: 23, title: 'Aurora Borealis', reqXP: 22200, reward: '🌈 Aurora Aura Frame', icon: '🌈', type: 'frame', vip: false },
    { tier: 24, title: 'High Roller', reqXP: 24500, reward: '500 Embers', icon: '🔥', type: 'embers', vip: false },
    { tier: 25, title: 'Quantum Spark', reqXP: 27000, reward: '⚛️ Quantum Particle Ring', icon: '⚛️', type: 'frame', vip: true },
    { tier: 26, title: 'Elite Trailblazer', reqXP: 29600, reward: '750 Embers', icon: '🔥', type: 'embers', vip: false },
    { tier: 27, title: 'Heartstring Harmonizer', reqXP: 32400, reward: '10x Super Sparks', icon: '💖', type: 'booster', vip: true },
    { tier: 28, title: 'Mythic Ranger', reqXP: 35300, reward: '1,200 Embers', icon: '🔥', type: 'embers', vip: false },
    { tier: 29, title: 'Stellar Ascension', reqXP: 38400, reward: '🌠 Shooting Star Trail', icon: '🌠', type: 'frame', vip: true },
    { tier: 30, title: 'SparkQuest Godtier', reqXP: 42000, reward: '👑 Ascendant Deity Crown & 2,500 Embers', icon: '🔱', type: 'badge', vip: true }
  ],

  dailyMissions: [
    { id: 'm1', title: 'Spin the Daily Fortune Wheel', xp: 50, done: true },
    { id: 'm2', title: 'Send 3 chat messages to a match', xp: 75, done: true },
    { id: 'm3', title: 'Check in at a Safe Haven venue', xp: 125, done: false },
    { id: 'm4', title: 'Complete a Mystery Blind Match duel', xp: 150, done: false }
  ],

  openModal() {
    try {
      AudioFX.playChallenge();
    } catch (e) {}

    const existing = document.getElementById('spark-pass-modal');
    if (existing) existing.remove();

    const modal = document.createElement('div');
    modal.id = 'spark-pass-modal';
    modal.className = 'custom-module-modal active';
    modal.innerHTML = `
      <div class="modal-card" style="max-width:540px; max-height:88vh; display:flex; flex-direction:column; background: linear-gradient(145deg, #12162a, #1a1f38); border: 1px solid rgba(139,92,246,0.3); border-radius:24px; box-shadow: 0 25px 60px rgba(0,0,0,0.8); overflow:hidden;">
        <!-- Header -->
        <div style="padding:18px 22px; background: linear-gradient(90deg, rgba(139,92,246,0.25), rgba(236,72,153,0.25)); border-bottom:1px solid rgba(255,255,255,0.08); display:flex; align-items:center; justify-content:space-between;">
          <div style="display:flex; align-items:center; gap:12px;">
            <div style="width:42px; height:42px; border-radius:12px; background:linear-gradient(135deg, #ec4899, #8b5cf6); display:flex; align-items:center; justify-content:center; font-size:20px; box-shadow: 0 0 15px rgba(236,72,153,0.5);">
              ⭐
            </div>
            <div>
              <div style="font-size:17px; font-weight:800; color:#fff; letter-spacing:0.3px;">Season 1: Spark Pass</div>
              <div style="font-size:12px; color:rgba(255,255,255,0.65);">Level ${this.currentLevel} • ${this.currentXP} XP</div>
            </div>
          </div>
          <button onclick="window.SparkPass.closeModal()" style="background:rgba(255,255,255,0.1); border:none; color:#fff; width:34px; height:34px; border-radius:50%; font-size:18px; cursor:pointer; display:flex; align-items:center; justify-content:center;">&times;</button>
        </div>

        <!-- Scrollable Content -->
        <div style="padding:20px; overflow-y:auto; flex:1;">
          <!-- Progress Bar -->
          <div style="background:rgba(255,255,255,0.04); border:1px solid rgba(255,255,255,0.08); border-radius:16px; padding:16px; margin-bottom:18px;">
            <div style="display:flex; justify-content:space-between; font-size:13px; font-weight:700; margin-bottom:8px;">
              <span style="color:#a78bfa;">Level ${this.currentLevel}: Explorer Keen</span>
              <span style="color:#ec4899;">Next: Tier 5 (700 XP)</span>
            </div>
            <div style="height:10px; background:rgba(255,255,255,0.1); border-radius:5px; overflow:hidden;">
              <div style="width:${Math.min(100, Math.round((this.currentXP / 700) * 100))}%; height:100%; background:linear-gradient(90deg, #8b5cf6, #ec4899); border-radius:5px; transition:width 0.4s ease;"></div>
            </div>
            <div style="display:flex; justify-content:space-between; margin-top:8px; font-size:11px; color:rgba(255,255,255,0.5);">
              <span>${this.currentXP} XP</span>
              <span>700 XP needed</span>
            </div>
          </div>

          <!-- Daily Quests Section -->
          <div style="margin-bottom:20px;">
            <div style="font-size:14px; font-weight:700; color:#fff; margin-bottom:10px; display:flex; align-items:center; gap:6px;">
              <span>🎯</span> Daily XP Missions (Refreshes in 8h)
            </div>
            <div style="display:flex; flex-direction:column; gap:8px;">
              ${this.dailyMissions.map(m => `
                <div style="background:rgba(255,255,255,0.03); border:1px solid ${m.done ? 'rgba(16,185,129,0.3)' : 'rgba(255,255,255,0.08)'}; border-radius:12px; padding:10px 14px; display:flex; align-items:center; justify-content:space-between;">
                  <div style="display:flex; align-items:center; gap:10px;">
                    <span style="color:${m.done ? '#10b981' : '#94a3b8'}; font-size:15px;">${m.done ? '✓' : '○'}</span>
                    <span style="font-size:13px; color:${m.done ? 'rgba(255,255,255,0.6)' : '#fff'}; ${m.done ? 'text-decoration:line-through;' : ''}">${m.title}</span>
                  </div>
                  <span style="font-size:12px; font-weight:700; color:#a78bfa; background:rgba(139,92,246,0.15); padding:3px 8px; border-radius:8px;">+${m.xp} XP</span>
                </div>
              `).join('')}
            </div>
          </div>

          <!-- 30 Tier Track -->
          <div style="font-size:14px; font-weight:700; color:#fff; margin-bottom:12px; display:flex; align-items:center; justify-content:space-between;">
            <div style="display:flex; align-items:center; gap:6px;">
              <span>🏆</span> Season Track (30 Tiers)
            </div>
            <span style="font-size:11px; color:#ec4899; background:rgba(236,72,153,0.15); padding:2px 8px; border-radius:6px; font-weight:700;">VIP Gold Multiplier Active</span>
          </div>

          <div style="display:flex; flex-direction:column; gap:10px;">
            ${this.tiers.map(t => {
              const isUnlocked = this.currentXP >= t.reqXP;
              const isClaimed = this.claimedTiers.includes(t.tier);
              return `
                <div style="background:${isUnlocked ? 'linear-gradient(90deg, rgba(139,92,246,0.1), rgba(236,72,153,0.05))' : 'rgba(255,255,255,0.02)'}; border:1px solid ${isUnlocked ? 'rgba(139,92,246,0.3)' : 'rgba(255,255,255,0.06)'}; border-radius:14px; padding:12px 14px; display:flex; align-items:center; justify-content:space-between; ${!isUnlocked ? 'opacity:0.6;' : ''}">
                  <div style="display:flex; align-items:center; gap:12px;">
                    <div style="width:34px; height:34px; border-radius:10px; background:${isUnlocked ? 'rgba(139,92,246,0.25)' : 'rgba(255,255,255,0.05)'}; display:flex; align-items:center; justify-content:center; font-size:16px;">
                      ${t.icon}
                    </div>
                    <div>
                      <div style="font-size:13px; font-weight:700; color:#fff; display:flex; align-items:center; gap:6px;">
                        <span>Tier ${t.tier}: ${t.title}</span>
                        ${t.vip ? '<span style="font-size:9px; background:linear-gradient(135deg, #f59e0b, #ec4899); color:#fff; padding:1px 5px; border-radius:4px; font-weight:800;">VIP</span>' : ''}
                      </div>
                      <div style="font-size:11px; color:#a78bfa;">${t.reward} • ${t.reqXP} XP</div>
                    </div>
                  </div>

                  <div>
                    ${isClaimed ? `
                      <span style="font-size:12px; font-weight:700; color:#10b981; background:rgba(16,185,129,0.15); padding:6px 12px; border-radius:10px;">Claimed ✓</span>
                    ` : isUnlocked ? `
                      <button onclick="window.SparkPass.claimTier(${t.tier})" style="background:linear-gradient(135deg, #8b5cf6, #ec4899); border:none; color:#fff; font-size:12px; font-weight:700; padding:6px 14px; border-radius:10px; cursor:pointer; box-shadow:0 4px 12px rgba(139,92,246,0.4);">Claim</button>
                    ` : `
                      <span style="font-size:11px; color:rgba(255,255,255,0.4); background:rgba(255,255,255,0.05); padding:6px 10px; border-radius:10px;">🔒 Locked</span>
                    `}
                  </div>
                </div>
              `;
            }).join('')}
          </div>
        </div>
      </div>
    `;

    document.body.appendChild(modal);
  },

  claimTier(tierNum) {
    const tier = this.tiers.find(t => t.tier === tierNum);
    if (!tier) return;

    if (!this.claimedTiers.includes(tierNum)) {
      this.claimedTiers.push(tierNum);
    }

    try {
      AudioFX.playReward();
      confetti({ particleCount: 70, spread: 60, origin: { y: 0.6 } });
    } catch (e) {}

    if (tier.type === 'embers') {
      const amt = parseInt(tier.reward) || 100;
      if (typeof window.embers === 'number') {
        window.embers += amt;
        const el = document.getElementById('ember-count');
        if (el) el.textContent = window.embers;
      }
    }

    if (typeof window.showToast === 'function') {
      window.showToast(`🎉 Unlocked Tier ${tierNum}: ${tier.reward}!`, 'success');
    }

    this.openModal();
  },

  closeModal() {
    const modal = document.getElementById('spark-pass-modal');
    if (modal) modal.remove();
  }
};

export default SparkPass;
