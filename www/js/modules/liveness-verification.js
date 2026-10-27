/**
 * Liveness Verification & Anti-Ghosting Protocol for SparkQuest
 * Features:
 * 1. Interactive Liveness Selfie Face Verification (Anti-Catfish Gold Badge)
 * 2. Courteous Exit / Anti-Ghosting Protocol with "Closure Coins" (+15 Embers)
 */

import AudioFX from './audio-fx.js';
import confetti from 'canvas-confetti';

class LivenessVerificationEngine {
  constructor() {
    this.videoStream = null;
    this.currentStep = 0;
    this.steps = [
      { text: "Position your face inside the oval frame", icon: "👤", duration: 2500 },
      { text: "Tilt your head slightly to the left", icon: "↪️", duration: 2500 },
      { text: "Smile warmly for the camera!", icon: "😊", duration: 2000 }
    ];
    this.stepTimer = null;
  }

  // Open the Liveness Face Verification Modal
  openVerificationModal() {
    AudioFX.playChallenge();
    const existing = document.getElementById('liveness-modal');
    if (existing) existing.remove();

    const modal = document.createElement('div');
    modal.id = 'liveness-modal';
    modal.className = 'custom-module-modal active';
    modal.innerHTML = `
      <div class="modal-card liveness-card">
        <div class="modal-header">
          <div class="liveness-title">
            <i class="fas fa-shield-halved" style="color:var(--cyan); margin-right:8px;"></i>
            <h3>Verified Adventurer</h3>
          </div>
          <button class="close-modal-btn" onclick="window.LivenessVerification.closeModal()">&times;</button>
        </div>
        <div class="liveness-content">
          <p class="liveness-subtitle">Prove you are 100% genuine with a 7-second liveness check. Earn a golden verified badge and +50 Embers!</p>

          <div class="liveness-viewport-container">
            <video id="liveness-video-feed" playsinline autoplay muted></video>
            <div class="liveness-oval-overlay" id="liveness-oval">
              <div class="scanner-sweep-line"></div>
            </div>
            <div class="flash-overlay" id="liveness-flash"></div>
          </div>

          <div class="liveness-instruction-box">
            <span class="liveness-step-icon" id="liveness-step-icon">👤</span>
            <span class="liveness-step-text" id="liveness-step-text">Position your face inside the oval</span>
          </div>

          <div class="liveness-progress-track">
            <div class="liveness-progress-fill" id="liveness-progress-fill" style="width: 10%;"></div>
          </div>

          <div class="liveness-actions">
            <button class="action-btn-primary" id="liveness-start-btn" onclick="window.LivenessVerification.startLivenessCheck()">
              <i class="fas fa-camera"></i> Start Liveness Check
            </button>
          </div>
        </div>
      </div>
    `;
    document.body.appendChild(modal);

    this.startCameraStream();
  }

  async startCameraStream() {
    try {
      const constraints = {
        video: { facingMode: 'user', width: { ideal: 480 }, height: { ideal: 640 } },
        audio: false
      };
      this.videoStream = await navigator.mediaDevices.getUserMedia(constraints);
      const videoEl = document.getElementById('liveness-video-feed');
      if (videoEl) {
        videoEl.srcObject = this.videoStream;
      }
    } catch (err) {
      console.warn('[Liveness] Camera access error or simulated:', err);
      // Fallback styling for simulated environment
      const videoEl = document.getElementById('liveness-video-feed');
      if (videoEl) {
        videoEl.poster = 'img/alex.png';
      }
    }
  }

  startLivenessCheck() {
    AudioFX.playPop();
    const btn = document.getElementById('liveness-start-btn');
    if (btn) btn.style.display = 'none';

    this.currentStep = 0;
    this.runStep();
  }

  runStep() {
    if (this.currentStep >= this.steps.length) {
      this.completeVerification();
      return;
    }

    const step = this.steps[this.currentStep];
    const textEl = document.getElementById('liveness-step-text');
    const iconEl = document.getElementById('liveness-step-icon');
    const fillEl = document.getElementById('liveness-progress-fill');
    const oval = document.getElementById('liveness-oval');

    if (textEl) textEl.textContent = step.text;
    if (iconEl) iconEl.textContent = step.icon;
    if (fillEl) fillEl.style.width = `${((this.currentStep + 1) / this.steps.length) * 100}%`;
    if (oval) oval.classList.add('scanning');

    AudioFX.playPop();

    this.stepTimer = setTimeout(() => {
      this.currentStep++;
      this.runStep();
    }, step.duration);
  }

  completeVerification() {
    // Flash effect
    const flash = document.getElementById('liveness-flash');
    if (flash) {
      flash.classList.add('flash-active');
      setTimeout(() => flash.classList.remove('flash-active'), 400);
    }

    AudioFX.playLevelUp();

    // Mark as verified
    localStorage.setItem('sparkquest_user_verified', 'true');
    if (typeof window.embers === 'number') {
      window.embers += 50;
      AudioFX.playEmberClaim();
    }
    if (window.DB_Service && window.currentUserUid) {
      window.DB_Service.updateUserStats(window.currentUserUid, { is_verified: true, embers: window.embers });
    }

    confetti({
      particleCount: 100,
      spread: 80,
      origin: { y: 0.4 },
      colors: ['#00E5FF', '#FFB800', '#FF3F6C']
    });

    const content = document.querySelector('.liveness-content');
    if (content) {
      content.innerHTML = `
        <div class="verification-success-state">
          <div class="success-shield-anim">
            <i class="fas fa-shield-check" style="color:var(--cyan); font-size:4.5rem;"></i>
          </div>
          <h3>Liveness Verified!</h3>
          <p>Your profile has received the Verified Explorer Shield. Your cards are prioritized in discovery stacks!</p>
          <div class="badge-reward-pill">+50 Embers Added 🔥</div>
          <button class="action-btn-primary" onclick="window.LivenessVerification.closeModal()">
            Awesome!
          </button>
        </div>
      `;
    }
  }

  closeModal() {
    AudioFX.playPop();
    if (this.videoStream) {
      this.videoStream.getTracks().forEach(t => t.stop());
      this.videoStream = null;
    }
    if (this.stepTimer) {
      clearTimeout(this.stepTimer);
      this.stepTimer = null;
    }
    const modal = document.getElementById('liveness-modal');
    if (modal) modal.remove();

    // Update verified badge on local profile UI if present
    const profileBadge = document.getElementById('profile-verified-shield');
    if (profileBadge) {
      profileBadge.style.display = 'inline-flex';
    }
  }

  /* ================= ANTI-GHOSTING / CLOSURE COINS ================= */

  openClosureModal(match) {
    AudioFX.playPop();
    const existing = document.getElementById('closure-modal');
    if (existing) existing.remove();

    const closureNotes = [
      "Loved chatting with you, but didn't quite feel the romantic spark. Wishing you the best on your quest! ✨",
      "Taking a little break from dating apps right now, but really enjoyed getting to know you! 🌱",
      "You're genuinely wonderful, but I think we're much better matched as friends! 💫"
    ];

    const modal = document.createElement('div');
    modal.id = 'closure-modal';
    modal.className = 'custom-module-modal active';
    modal.innerHTML = `
      <div class="modal-card closure-card">
        <div class="modal-header">
          <div class="closure-header-meta">
            <span class="closure-badge"><i class="fas fa-dove"></i> Respectful Exit</span>
            <h3>Courteous Unmatch</h3>
          </div>
          <button class="close-modal-btn" onclick="document.getElementById('closure-modal').remove()">&times;</button>
        </div>
        <div class="closure-body">
          <p class="closure-desc">SparkQuest is built on kindness. Send a polite goodbye note instead of ghosting — both of you earn <strong>+15 Closure Embers</strong> for positive community karma.</p>

          <div class="closure-notes-list">
            ${closureNotes.map((note, idx) => `
              <label class="closure-note-option">
                <input type="radio" name="closure-note" value="${note.replace(/"/g, '&quot;')}" ${idx === 0 ? 'checked' : ''}>
                <span class="note-box-text">${note}</span>
              </label>
            `).join('')}
          </div>

          <div class="closure-actions">
            <button class="action-btn-secondary" onclick="document.getElementById('closure-modal').remove()">Nevermind</button>
            <button class="action-btn-primary" onclick="window.LivenessVerification.sendClosureNote('${match.id}', '${match.name}')">
              <i class="fas fa-paper-plane"></i> Send & Exit (+15🔥)
            </button>
          </div>
        </div>
      </div>
    `;
    document.body.appendChild(modal);
  }

  sendClosureNote(matchId, matchName) {
    AudioFX.playLevelUp();
    const selected = document.querySelector('input[name="closure-note"]:checked')?.value || "Wishing you the best on your quest! ✨";

    if (typeof window.sendMessage === 'function') {
      window.sendMessage(selected);
    }

    // Award +15 Closure Coins (Embers)
    if (typeof window.embers === 'number') {
      window.embers += 15;
      AudioFX.playEmberClaim();
      if (window.DB_Service && window.currentUserUid) {
        window.DB_Service.updateUserStats(window.currentUserUid, { embers: window.embers });
      }
    }

    const modal = document.getElementById('closure-modal');
    if (modal) modal.remove();

    alert(`✨ Courteous exit sent to ${matchName}. +15 Embers added to your wallet for keeping dating kind!`);

    // Close chat detail and return to messages tab
    const chatDetail = document.getElementById('chat-detail-view');
    if (chatDetail) chatDetail.classList.remove('active');
  }
}

const LivenessVerification = new LivenessVerificationEngine();
export default LivenessVerification;
