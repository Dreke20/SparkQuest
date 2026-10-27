/**
 * Daily Fortune Spin Wheel Module for SparkQuest
 * Features physics-based deceleration, audio ticks, confetti, and Ember/inventory rewards.
 */

import AudioFX from './audio-fx.js';
import confetti from 'canvas-confetti';

class DailySpinWheel {
  constructor() {
    this.modalId = 'daily-spin-modal';
    this.canvasId = 'daily-spin-canvas';
    this.isSpinning = false;
    this.currentRotation = 0;
    this.lastTickSegment = -1;

    this.slices = [
      { id: 'embers_50', label: '✦ 50 Embers', icon: '✦', color: '#1E293B', reward: { type: 'embers', val: 50 } },
      { id: 'boost_30m', label: '🔥 30m Boost', icon: '🔥', color: '#FF3F6C', reward: { type: 'inventory', key: 'boost', val: 1 } },
      { id: 'embers_150', label: '💎 150 Embers', icon: '💎', color: '#00E5FF', reward: { type: 'embers', val: 150 } },
      { id: 'superlike', label: '⭐ 2x Superlikes', icon: '⭐', color: '#FFB800', reward: { type: 'inventory', key: 'superlike', val: 2 } },
      { id: 'shield_charm', label: '🛡️ Date Shield Pass', icon: '🛡️', color: '#7B2FFF', reward: { type: 'inventory', key: 'shieldPass', val: 1 } },
      { id: 'embers_100', label: '✦ 100 Embers', icon: '✦', color: '#10B981', reward: { type: 'embers', val: 100 } },
      { id: 'streak_2x', label: '🎁 2x Multiplier', icon: '🎁', color: '#E11D48', reward: { type: 'streak_multiplier', val: 2 } },
      { id: 'legendary_frame', label: '👑 Neon Crown Frame', icon: '👑', color: '#F59E0B', reward: { type: 'cosmetic', id: 'neon_crown' } }
    ];
  }

  init() {
    this._injectModal();
    this._drawWheel();
  }

  _injectModal() {
    if (document.getElementById(this.modalId)) return;

    const modal = document.createElement('div');
    modal.id = this.modalId;
    modal.className = 'modal-overlay';
    modal.style.cssText = 'display:none; z-index:10005; align-items:center; justify-content:center; background:rgba(11,15,26,0.88); backdrop-filter:blur(8px);';

    modal.innerHTML = `
      <div class="modal-card" style="background:#111827; border:1px solid rgba(0,229,255,0.4); border-radius:24px; max-width:380px; width:92%; padding:24px; text-align:center; box-shadow:0 0 35px rgba(0,229,255,0.25); position:relative;">
        <button onclick="DailySpinWheelInstance.close()" style="position:absolute; top:16px; right:16px; background:none; border:none; color:#94A3B8; font-size:1.4rem; cursor:pointer;">&times;</button>
        <div style="font-size:2rem; margin-bottom:4px;">🎡</div>
        <h2 style="margin:0 0 4px 0; color:#F1F5F9; font-family:'Outfit',sans-serif; font-size:1.5rem; letter-spacing:1px;">DAILY FORTUNE WHEEL</h2>
        <p style="color:#94A3B8; font-size:0.85rem; margin-bottom:18px;">Spin daily to win free Embers, Boosts, and Legendary Frames!</p>

        <!-- Wheel Canvas Container -->
        <div style="position:relative; width:280px; height:280px; margin:0 auto 18px auto;">
          <!-- Pointer -->
          <div style="position:absolute; top:-12px; left:50%; transform:translateX(-50%); width:0; height:0; border-left:14px solid transparent; border-right:14px solid transparent; border-top:22px solid #FF3F6C; z-index:10; filter:drop-shadow(0 2px 6px rgba(255,63,108,0.8));"></div>
          
          <canvas id="${this.canvasId}" width="280" height="280" style="border-radius:50%; box-shadow:0 0 20px rgba(0,229,255,0.3);"></canvas>
          
          <!-- Center Cap -->
          <div style="position:absolute; top:50%; left:50%; transform:translate(-50%, -50%); width:46px; height:46px; border-radius:50%; background:linear-gradient(135deg, #FF3F6C, #00E5FF); box-shadow:0 0 15px #00E5FF; border:3px solid #111827; display:flex; align-items:center; justify-content:center; font-weight:bold; color:white; font-size:0.8rem;">✦</div>
        </div>

        <div id="daily-spin-status" style="font-size:0.85rem; color:#00E5FF; margin-bottom:14px; min-height:20px;">Free Spin Available!</div>

        <button id="btn-spin-wheel" onclick="DailySpinWheelInstance.spin()" class="btn-primary" style="width:100%; padding:14px; font-size:1.05rem; border-radius:14px; font-weight:bold; background:linear-gradient(90deg, #FF3F6C, #7B2FFF); border:none; box-shadow:0 4px 15px rgba(255,63,108,0.4); cursor:pointer;">
          SPIN FOR FREE 🎯
        </button>
      </div>
    `;

    document.body.appendChild(modal);
  }

  _drawWheel(rotationOffset = 0) {
    const canvas = document.getElementById(this.canvasId);
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const numSlices = this.slices.length;
    const sliceAngle = (2 * Math.PI) / numSlices;
    const radius = canvas.width / 2;

    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.save();
    ctx.translate(radius, radius);
    ctx.rotate(rotationOffset);

    for (let i = 0; i < numSlices; i++) {
      const slice = this.slices[i];
      const startAngle = i * sliceAngle;
      const endAngle = startAngle + sliceAngle;

      ctx.beginPath();
      ctx.moveTo(0, 0);
      ctx.arc(0, 0, radius, startAngle, endAngle);
      ctx.fillStyle = slice.color;
      ctx.fill();
      ctx.strokeStyle = '#111827';
      ctx.lineWidth = 2.5;
      ctx.stroke();

      // Text / Label
      ctx.save();
      ctx.rotate(startAngle + sliceAngle / 2);
      ctx.textAlign = 'right';
      ctx.fillStyle = '#FFFFFF';
      ctx.font = 'bold 11px Outfit, sans-serif';
      ctx.shadowColor = 'rgba(0,0,0,0.8)';
      ctx.shadowBlur = 4;
      ctx.fillText(slice.label, radius - 18, 4);
      ctx.restore();
    }

    ctx.restore();
  }

  open() {
    this._injectModal();
    const modal = document.getElementById(this.modalId);
    if (modal) {
      modal.style.display = 'flex';
      this._updateStatusText();
      this._drawWheel(this.currentRotation);
      AudioFX.playChime();
    }
  }

  close() {
    const modal = document.getElementById(this.modalId);
    if (modal) modal.style.display = 'none';
  }

  _canSpinFree() {
    const lastSpin = localStorage.getItem('sparkquest_last_spin_time');
    if (!lastSpin) return true;
    const elapsed = Date.now() - parseInt(lastSpin, 10);
    return elapsed >= 24 * 60 * 60 * 1000;
  }

  _updateStatusText() {
    const statusEl = document.getElementById('daily-spin-status');
    const btn = document.getElementById('btn-spin-wheel');
    if (!statusEl || !btn) return;

    if (this._canSpinFree()) {
      statusEl.textContent = '✨ Free Daily Spin Available!';
      statusEl.style.color = '#00E5FF';
      btn.textContent = 'SPIN FOR FREE 🎯';
    } else {
      const lastSpin = parseInt(localStorage.getItem('sparkquest_last_spin_time'), 10);
      const remainingMs = 24 * 60 * 60 * 1000 - (Date.now() - lastSpin);
      const hours = Math.floor(remainingMs / (1000 * 60 * 60));
      const mins = Math.floor((remainingMs % (1000 * 60 * 60)) / (1000 * 60));
      statusEl.textContent = `Next free spin in ${hours}h ${mins}m (or 25 ✦ Embers)`;
      statusEl.style.color = '#94A3B8';
      btn.textContent = 'SPIN (25 ✦ EMBERS)';
    }
  }

  spin() {
    if (this.isSpinning) return;

    const isFree = this._canSpinFree();
    if (!isFree) {
      if ((window.embers || 0) < 25) {
        AudioFX.playBuzzer();
        alert('You need at least 25 Embers to spin again today!');
        return;
      }
      window.embers -= 25;
      if (typeof window.updateEmbersDisplay === 'function') window.updateEmbersDisplay();
    }

    this.isSpinning = true;
    const btn = document.getElementById('btn-spin-wheel');
    if (btn) btn.disabled = true;

    // Determine winning slice randomly
    const targetSliceIndex = Math.floor(Math.random() * this.slices.length);
    const sliceAngle = (2 * Math.PI) / this.slices.length;
    
    // Pointer is at the top (angle 3*PI/2 or -PI/2)
    // To land targetSliceIndex at top:
    const targetAngle = (3 * Math.PI / 2) - (targetSliceIndex * sliceAngle + sliceAngle / 2);
    const extraRotations = (5 + Math.floor(Math.random() * 3)) * 2 * Math.PI;
    const totalRotation = this.currentRotation + extraRotations + (targetAngle - (this.currentRotation % (2 * Math.PI)));

    const startTime = performance.now();
    const duration = 4000; // 4s animation

    const animate = (now) => {
      const elapsed = now - startTime;
      const progress = Math.min(elapsed / duration, 1);
      // Ease out cubic
      const easeOut = 1 - Math.pow(1 - progress, 3);
      const angle = this.currentRotation + (totalRotation - this.currentRotation) * easeOut;

      // Check tick sound on segment crossing
      const currentSegment = Math.floor((angle / sliceAngle)) % this.slices.length;
      if (currentSegment !== this.lastTickSegment) {
        AudioFX.playClick();
        this.lastTickSegment = currentSegment;
      }

      this._drawWheel(angle);

      if (progress < 1) {
        requestAnimationFrame(animate);
      } else {
        this.currentRotation = totalRotation % (2 * Math.PI);
        this.isSpinning = false;
        if (btn) btn.disabled = false;
        localStorage.setItem('sparkquest_last_spin_time', Date.now().toString());
        this._updateStatusText();
        this._handleReward(this.slices[targetSliceIndex]);
      }
    };

    requestAnimationFrame(animate);
  }

  _handleReward(slice) {
    AudioFX.playMatchCelebration();
    confetti({
      particleCount: 80,
      spread: 70,
      origin: { y: 0.6 }
    });

    const reward = slice.reward;
    let rewardMsg = `🎉 You won ${slice.label}!`;

    if (reward.type === 'embers') {
      window.embers = (window.embers || 0) + reward.val;
      if (typeof window.updateEmbersDisplay === 'function') window.updateEmbersDisplay();
      if (typeof window.showToast === 'function') {
        window.showToast(`+${reward.val} Embers credited! ✦`);
      }
    } else if (reward.type === 'inventory') {
      window.inventory = window.inventory || {};
      window.inventory[reward.key] = (window.inventory[reward.key] || 0) + reward.val;
      if (typeof window.showToast === 'function') {
        window.showToast(`+${reward.val} ${reward.key} added to your bag!`);
      }
    } else if (reward.type === 'cosmetic') {
      localStorage.setItem('sparkquest_active_avatar_frame', reward.id);
      if (typeof window.showToast === 'function') {
        window.showToast(`👑 Unlocked Neon Crown Avatar Frame!`);
      }
    }

    const statusEl = document.getElementById('daily-spin-status');
    if (statusEl) {
      statusEl.innerHTML = `<span style="color:#10B981; font-weight:bold;">${rewardMsg}</span>`;
    }
  }
}

const DailySpinWheelInstance = new DailySpinWheel();
window.DailySpinWheelInstance = DailySpinWheelInstance;
export default DailySpinWheelInstance;
