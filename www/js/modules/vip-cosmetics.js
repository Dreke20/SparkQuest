/**
 * VIP Gold Subscription & Profile Cosmetics Module for SparkQuest
 * Features tier management, unlimited rewinds, see-who-liked-you, and animated avatar frames.
 */

import AudioFX from './audio-fx.js';
import confetti from 'canvas-confetti';

class VIPCosmetics {
  constructor() {
    this.vipModalId = 'vip-upgrade-modal';
    this.cosmeticsModalId = 'profile-cosmetics-modal';

    this.frames = [
      { id: 'default', name: 'Standard Sleek', css: 'border: 2px solid #00E5FF;', unlocked: true },
      { id: 'cyber_cyan', name: '⚡ Cyberpunk Ring', css: 'border: 3px solid #00E5FF; box-shadow: 0 0 15px #00E5FF, inset 0 0 8px #00E5FF;', unlocked: true },
      { id: 'phoenix_flame', name: '🔥 Phoenix Flame', css: 'border: 3px solid #FF3F6C; box-shadow: 0 0 18px #FF3F6C, 0 0 30px rgba(255,63,108,0.5);', unlocked: true },
      { id: 'galactic_violet', name: '🌌 Galactic Aura', css: 'border: 3px solid #7B2FFF; box-shadow: 0 0 20px #7B2FFF, inset 0 0 10px #00E5FF;', unlocked: false, cost: 200 },
      { id: 'neon_crown', name: '👑 Neon Crown Legend', css: 'border: 3px solid #FFB800; box-shadow: 0 0 25px #FFB800, 0 0 15px #FF3F6C;', unlocked: false, cost: 500 },
    ];
  }

  init() {
    this._injectModals();
    this.applyActiveFrame();
  }

  getActiveFrameId() {
    return localStorage.getItem('sparkquest_active_avatar_frame') || 'cyber_cyan';
  }

  applyActiveFrame() {
    const activeId = this.getActiveFrameId();
    const frame = this.frames.find(f => f.id === activeId) || this.frames[1];
    
    // Apply styling to all profile avatar elements
    const avatars = document.querySelectorAll('.profile-avatar, #profile-avatar, .user-avatar-img, .profile-img-main');
    avatars.forEach(el => {
      el.style.cssText += frame.css;
    });
  }

  _injectModals() {
    if (!document.getElementById(this.vipModalId)) {
      const vipModal = document.createElement('div');
      vipModal.id = this.vipModalId;
      vipModal.className = 'modal-overlay';
      vipModal.style.cssText = 'display:none; z-index:10009; align-items:center; justify-content:center; background:rgba(11,15,26,0.92); backdrop-filter:blur(10px);';

      vipModal.innerHTML = `
        <div class="modal-card" style="background:#111827; border:1px solid rgba(255,184,0,0.5); border-radius:24px; max-width:390px; width:92%; padding:24px; text-align:center; box-shadow:0 0 40px rgba(255,184,0,0.3); position:relative;">
          <button onclick="VIPCosmeticsInstance.closeVIP()" style="position:absolute; top:16px; right:16px; background:none; border:none; color:#94A3B8; font-size:1.4rem; cursor:pointer;">&times;</button>
          
          <div style="font-size:2.4rem; margin-bottom:6px;">👑</div>
          <h2 style="margin:0 0 6px 0; color:#F1F5F9; font-family:'Outfit',sans-serif; font-size:1.6rem; letter-spacing:1px;">SPARKQUEST GOLD</h2>
          <p style="color:#94A3B8; font-size:0.85rem; margin-bottom:18px;">Unlock the ultimate explorer privileges and supercharge your dating quests.</p>

          <div style="display:flex; flex-direction:column; gap:10px; text-align:left; margin-bottom:20px;">
            <div style="display:flex; align-items:center; gap:10px; background:#1A2235; padding:10px 14px; border-radius:12px;">
              <span style="font-size:1.2rem;">⏪</span>
              <div style="font-size:0.85rem; color:#F1F5F9;"><strong>Unlimited Rewinds</strong> – Never lose a passed match accidentally</div>
            </div>
            <div style="display:flex; align-items:center; gap:10px; background:#1A2235; padding:10px 14px; border-radius:12px;">
              <span style="font-size:1.2rem;">👁️</span>
              <div style="font-size:0.85rem; color:#F1F5F9;"><strong>See Who Liked You</strong> – Instant matches on demand</div>
            </div>
            <div style="display:flex; align-items:center; gap:10px; background:#1A2235; padding:10px 14px; border-radius:12px;">
              <span style="font-size:1.2rem;">✦</span>
              <div style="font-size:0.85rem; color:#F1F5F9;"><strong>2x Embers & Drops</strong> – Double streak and quest bonuses</div>
            </div>
            <div style="display:flex; align-items:center; gap:10px; background:#1A2235; padding:10px 14px; border-radius:12px;">
              <span style="font-size:1.2rem;">⚡</span>
              <div style="font-size:0.85rem; color:#F1F5F9;"><strong>Weekly Spotlight Boost</strong> – 10x profile visibility</div>
            </div>
          </div>

          <button onclick="VIPCosmeticsInstance.subscribeGold()" class="btn-primary" style="width:100%; padding:14px; font-size:1.05rem; border-radius:14px; font-weight:bold; background:linear-gradient(90deg, #FFB800, #FF3F6C); border:none; box-shadow:0 4px 20px rgba(255,184,0,0.4); cursor:pointer;">
            JOIN GOLD (500 ✦ EMBERS / MO)
          </button>
        </div>
      `;
      document.body.appendChild(vipModal);
    }

    if (!document.getElementById(this.cosmeticsModalId)) {
      const cosmModal = document.createElement('div');
      cosmModal.id = this.cosmeticsModalId;
      cosmModal.className = 'modal-overlay';
      cosmModal.style.cssText = 'display:none; z-index:10009; align-items:center; justify-content:center; background:rgba(11,15,26,0.92); backdrop-filter:blur(10px);';

      cosmModal.innerHTML = `
        <div class="modal-card" style="background:#111827; border:1px solid rgba(0,229,255,0.4); border-radius:24px; max-width:380px; width:92%; padding:24px; text-align:center; box-shadow:0 0 35px rgba(0,229,255,0.25); position:relative;">
          <button onclick="VIPCosmeticsInstance.closeCosmetics()" style="position:absolute; top:16px; right:16px; background:none; border:none; color:#94A3B8; font-size:1.4rem; cursor:pointer;">&times;</button>
          
          <div style="font-size:2rem; margin-bottom:4px;">✨</div>
          <h2 style="margin:0 0 6px 0; color:#F1F5F9; font-family:'Outfit',sans-serif; font-size:1.45rem; letter-spacing:1px;">AVATAR COSMETICS</h2>
          <p style="color:#94A3B8; font-size:0.85rem; margin-bottom:18px;">Equip glowing cyberpunk borders for your profile and chat cards.</p>

          <div id="cosmetics-frames-list" style="display:flex; flex-direction:column; gap:10px; margin-bottom:18px;">
            <!-- Frames injected dynamically -->
          </div>

          <button onclick="VIPCosmeticsInstance.closeCosmetics()" class="btn-outline" style="width:100%; padding:12px; border-radius:14px; font-weight:bold; border:1px solid #94A3B8; color:#F1F5F9; background:transparent; cursor:pointer;">
            Done
          </button>
        </div>
      `;
      document.body.appendChild(cosmModal);
    }
  }

  openVIP() {
    this._injectModals();
    const modal = document.getElementById(this.vipModalId);
    if (modal) {
      modal.style.display = 'flex';
      AudioFX.playClick();
    }
  }

  closeVIP() {
    const modal = document.getElementById(this.vipModalId);
    if (modal) modal.style.display = 'none';
  }

  openCosmetics() {
    this._injectModals();
    this._renderCosmeticsList();
    const modal = document.getElementById(this.cosmeticsModalId);
    if (modal) {
      modal.style.display = 'flex';
      AudioFX.playClick();
    }
  }

  closeCosmetics() {
    const modal = document.getElementById(this.cosmeticsModalId);
    if (modal) modal.style.display = 'none';
  }

  _renderCosmeticsList() {
    const container = document.getElementById('cosmetics-frames-list');
    if (!container) return;

    const activeId = this.getActiveFrameId();

    container.innerHTML = this.frames.map(frame => {
      const isSelected = (frame.id === activeId);
      return `
        <div style="display:flex; align-items:center; justify-content:space-between; background:#1A2235; padding:10px 14px; border-radius:14px; border:${isSelected ? '1px solid #00E5FF' : '1px solid rgba(255,255,255,0.06)'};">
          <div style="display:flex; align-items:center; gap:12px;">
            <div style="width:36px; height:36px; border-radius:50%; background:#111827; display:flex; align-items:center; justify-content:center; ${frame.css}">
              👤
            </div>
            <div style="text-align:left;">
              <div style="font-size:0.85rem; font-weight:bold; color:#F1F5F9;">${frame.name}</div>
              <div style="font-size:0.75rem; color:${isSelected ? '#00E5FF' : '#94A3B8'};">${isSelected ? 'Currently Equipped' : (frame.unlocked ? 'Unlocked' : `${frame.cost} ✦ Embers`)}</div>
            </div>
          </div>
          <button onclick="VIPCosmeticsInstance.equipFrame('${frame.id}')" style="padding:6px 14px; border-radius:10px; font-size:0.8rem; font-weight:bold; background:${isSelected ? '#00E5FF' : '#1E293B'}; color:${isSelected ? '#000000' : '#FFFFFF'}; border:none; cursor:pointer;">
            ${isSelected ? 'Equipped' : 'Equip'}
          </button>
        </div>
      `;
    }).join('');
  }

  equipFrame(id) {
    localStorage.setItem('sparkquest_active_avatar_frame', id);
    this.applyActiveFrame();
    this._renderCosmeticsList();
    AudioFX.playPing();
    if (typeof window.showToast === 'function') {
      window.showToast('Profile frame updated! ✨');
    }
  }

  subscribeGold() {
    if ((window.embers || 0) < 500) {
      AudioFX.playBuzzer();
      alert('You need at least 500 Embers to unlock SparkQuest Gold for a month! Earn more via Quests or Map drops.');
      return;
    }

    window.embers -= 500;
    window.isPremium = true;
    localStorage.setItem('sparkquest_is_premium', 'true');
    if (typeof window.updateEmbersDisplay === 'function') window.updateEmbersDisplay();

    this.closeVIP();
    AudioFX.playMatchCelebration();
    confetti({
      particleCount: 120,
      spread: 90,
      origin: { y: 0.5 }
    });

    if (typeof window.showToast === 'function') {
      window.showToast('👑 Welcome to SparkQuest Gold! Enjoy VIP Explorer status.');
    }
  }
}

const VIPCosmeticsInstance = new VIPCosmetics();
window.VIPCosmeticsInstance = VIPCosmeticsInstance;
export default VIPCosmeticsInstance;
