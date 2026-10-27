/**
 * Mystery Blind Match Module for SparkQuest
 * Experience personality-first matchmaking with blurred photo reveal, 3-question icebreaker duel, and confetti.
 */

import AudioFX from './audio-fx.js';
import confetti from 'canvas-confetti';

class MysteryMatch {
  constructor() {
    this.modalId = 'mystery-match-modal';
    this.currentStep = 0;
    this.score = 0;
    this.activeProfile = null;

    this.profilesPool = [
      { name: 'Sophia', age: 24, occupation: 'Photographer', photo: 'img/sophia.png', matchPct: 94, tags: ['🎨 Art', '🏔️ Hiking', '☕ Coffee'] },
      { name: 'Maya', age: 25, occupation: 'Yoga Instructor', photo: 'img/maya.png', matchPct: 88, tags: ['🧘 Yoga', '🌱 Vegan', '✈️ Travel'] },
      { name: 'Jordan', age: 28, occupation: 'Music Producer', photo: 'img/jordan.png', matchPct: 96, tags: ['🎵 Music', '🎬 Film', '🍷 Wine'] },
      { name: 'Taylor', age: 26, occupation: 'Designer', photo: 'img/taylor.png', matchPct: 91, tags: ['🎨 Design', '☕ Coffee', '🎸 Guitar'] },
    ];

    this.questions = [
      {
        q: 'It is Friday at 11:00 PM. What is the plan?',
        optA: '🌮 Spontaneous midnight taco crawl & city drive',
        optB: '🛋️ Cozy blanket cocoon, tea & anime binge',
        matchPick: 'optA'
      },
      {
        q: 'First live date venue preference?',
        optA: '🍸 Hidden speakeasy with live jazz',
        optB: '🕹️ Retro arcade bar & competitive air hockey',
        matchPick: 'optB'
      },
      {
        q: 'Dream weekend getaway destination?',
        optA: '🌲 Secluded forest cabin with star views',
        optB: '🏖️ Sun-drenched beach with surfboards',
        matchPick: 'optA'
      }
    ];
  }

  init() {
    this._injectModal();
  }

  _injectModal() {
    if (document.getElementById(this.modalId)) return;

    const modal = document.createElement('div');
    modal.id = this.modalId;
    modal.className = 'modal-overlay';
    modal.style.cssText = 'display:none; z-index:10006; align-items:center; justify-content:center; background:rgba(11,15,26,0.92); backdrop-filter:blur(10px);';

    modal.innerHTML = `
      <div class="modal-card" style="background:#111827; border:1px solid rgba(123,47,255,0.4); border-radius:24px; max-width:380px; width:92%; padding:24px; text-align:center; box-shadow:0 0 35px rgba(123,47,255,0.3); position:relative;">
        <button onclick="MysteryMatchInstance.close()" style="position:absolute; top:16px; right:16px; background:none; border:none; color:#94A3B8; font-size:1.4rem; cursor:pointer;">&times;</button>
        
        <div style="display:inline-flex; align-items:center; gap:6px; background:rgba(123,47,255,0.18); padding:4px 12px; border-radius:20px; border:1px solid rgba(123,47,255,0.4); margin-bottom:12px;">
          <span style="font-size:0.85rem;">🔮</span>
          <span style="font-size:0.75rem; color:#00E5FF; font-weight:bold; letter-spacing:1px;">MYSTERY BLIND MATCH</span>
        </div>

        <!-- Silhouette / Blurred Photo Box -->
        <div style="position:relative; width:160px; height:160px; margin:0 auto 16px auto; border-radius:24px; overflow:hidden; border:2px solid #7B2FFF; box-shadow:0 0 20px rgba(123,47,255,0.4);">
          <img id="mystery-avatar-img" src="" style="width:100%; height:100%; object-fit:cover; filter:blur(24px) brightness(0.6); transition:filter 1.2s cubic-bezier(0.16, 1, 0.3, 1);">
          <div id="mystery-silhouette-badge" style="position:absolute; inset:0; display:flex; align-items:center; justify-content:center; font-size:3.5rem; background:rgba(11,15,26,0.4);">
            🎭
          </div>
        </div>

        <div id="mystery-profile-title" style="font-family:'Outfit',sans-serif; font-size:1.25rem; font-weight:bold; color:#F1F5F9; margin-bottom:4px;">Mystery Explorer</div>
        <div id="mystery-vibe-pct" style="font-size:0.85rem; color:#94A3B8; margin-bottom:18px;">Vibe Alignment: 0%</div>

        <!-- Question Container -->
        <div id="mystery-question-box" style="text-align:left; background:#1A2235; padding:16px; border-radius:16px; border:1px solid rgba(255,255,255,0.06); margin-bottom:18px;">
          <div id="mystery-q-title" style="font-size:0.92rem; font-weight:bold; color:#F1F5F9; margin-bottom:12px;">Loading question...</div>
          <button id="btn-mystery-opt-a" onclick="MysteryMatchInstance.answer('optA')" style="width:100%; text-align:left; padding:10px 14px; margin-bottom:8px; border-radius:12px; background:#1E293B; border:1px solid rgba(0,229,255,0.25); color:#F1F5F9; font-size:0.85rem; cursor:pointer;">Option A</button>
          <button id="btn-mystery-opt-b" onclick="MysteryMatchInstance.answer('optB')" style="width:100%; text-align:left; padding:10px 14px; border-radius:12px; background:#1E293B; border:1px solid rgba(255,63,108,0.25); color:#F1F5F9; font-size:0.85rem; cursor:pointer;">Option B</button>
        </div>

        <!-- Reveal CTA (Initially Hidden) -->
        <div id="mystery-revealed-actions" style="display:none; gap:10px;">
          <button onclick="MysteryMatchInstance.startChat()" class="btn-primary" style="flex:1; padding:12px; border-radius:14px; font-weight:bold; background:linear-gradient(90deg, #FF3F6C, #00E5FF); border:none; cursor:pointer;">
            💬 Say Hi
          </button>
          <button onclick="MysteryMatchInstance.restart()" class="btn-outline" style="flex:1; padding:12px; border-radius:14px; font-weight:bold; border:1px solid #94A3B8; color:#F1F5F9; background:transparent; cursor:pointer;">
            Next Blind Match ➜
          </button>
        </div>
      </div>
    `;

    document.body.appendChild(modal);
  }

  open() {
    this._injectModal();
    this.currentStep = 0;
    this.score = 0;
    // Pick random profile
    this.activeProfile = this.profilesPool[Math.floor(Math.random() * this.profilesPool.length)];

    const avatar = document.getElementById('mystery-avatar-img');
    const badge = document.getElementById('mystery-silhouette-badge');
    const title = document.getElementById('mystery-profile-title');
    const vibe = document.getElementById('mystery-vibe-pct');
    const actions = document.getElementById('mystery-revealed-actions');
    const qBox = document.getElementById('mystery-question-box');

    if (avatar) {
      avatar.src = this.activeProfile.photo;
      avatar.style.filter = 'blur(24px) brightness(0.6)';
    }
    if (badge) badge.style.display = 'flex';
    if (title) title.textContent = 'Mystery Explorer';
    if (vibe) vibe.textContent = 'Vibe Alignment: 0%';
    if (actions) actions.style.display = 'none';
    if (qBox) qBox.style.display = 'block';

    this._renderCurrentQuestion();

    const modal = document.getElementById(this.modalId);
    if (modal) {
      modal.style.display = 'flex';
      AudioFX.playClick();
    }
  }

  close() {
    const modal = document.getElementById(this.modalId);
    if (modal) modal.style.display = 'none';
  }

  restart() {
    this.open();
  }

  _renderCurrentQuestion() {
    const cur = this.questions[this.currentStep];
    const qTitle = document.getElementById('mystery-q-title');
    const btnA = document.getElementById('btn-mystery-opt-a');
    const btnB = document.getElementById('btn-mystery-opt-b');

    if (qTitle) qTitle.textContent = `Q${this.currentStep + 1} of 3: ${cur.q}`;
    if (btnA) {
      btnA.textContent = cur.optA;
      btnA.disabled = false;
      btnA.style.borderColor = 'rgba(0,229,255,0.25)';
    }
    if (btnB) {
      btnB.textContent = cur.optB;
      btnB.disabled = false;
      btnB.style.borderColor = 'rgba(255,63,108,0.25)';
    }
  }

  answer(choice) {
    const cur = this.questions[this.currentStep];
    const isMatch = (choice === cur.matchPick);
    if (isMatch) this.score += 33;

    AudioFX.playPing();

    // Partial unblur based on progress
    const avatar = document.getElementById('mystery-avatar-img');
    const remainingBlur = 24 - (this.currentStep + 1) * 7;
    if (avatar) {
      avatar.style.filter = `blur(${Math.max(remainingBlur, 6)}px) brightness(0.75)`;
    }

    const vibe = document.getElementById('mystery-vibe-pct');
    if (vibe) {
      vibe.innerHTML = isMatch 
        ? `<span style="color:#10B981; font-weight:bold;">⚡ Chemistry Surge! Mutual Choice (+33%)</span>`
        : `<span style="color:#00E5FF;">Complementary Vibe! Next question...</span>`;
    }

    this.currentStep++;

    if (this.currentStep < this.questions.length) {
      setTimeout(() => {
        this._renderCurrentQuestion();
        if (vibe) vibe.textContent = `Vibe Alignment: ${this.score}%`;
      }, 700);
    } else {
      setTimeout(() => this._revealMatch(), 700);
    }
  }

  _revealMatch() {
    const avatar = document.getElementById('mystery-avatar-img');
    const badge = document.getElementById('mystery-silhouette-badge');
    const title = document.getElementById('mystery-profile-title');
    const vibe = document.getElementById('mystery-vibe-pct');
    const actions = document.getElementById('mystery-revealed-actions');
    const qBox = document.getElementById('mystery-question-box');

    if (avatar) avatar.style.filter = 'blur(0px) brightness(1)';
    if (badge) badge.style.display = 'none';

    if (title) {
      title.innerHTML = `${this.activeProfile.name}, ${this.activeProfile.age} <span style="font-size:0.85rem; color:#94A3B8; font-weight:normal;">• ${this.activeProfile.occupation}</span>`;
    }

    if (vibe) {
      vibe.innerHTML = `<span style="color:#00E5FF; font-weight:bold; font-size:1.05rem;">🎉 ${Math.max(this.score, 85)}% Chemistry Match!</span>`;
    }

    if (qBox) qBox.style.display = 'none';
    if (actions) actions.style.display = 'flex';

    AudioFX.playMatchCelebration();
    confetti({
      particleCount: 90,
      spread: 75,
      origin: { y: 0.6 }
    });
  }

  startChat() {
    this.close();
    if (typeof window.navigate === 'function') {
      window.navigate('chat');
    }
    if (typeof window.showToast === 'function') {
      window.showToast(`Conversation started with ${this.activeProfile.name}! 💬`);
    }
  }
}

const MysteryMatchInstance = new MysteryMatch();
window.MysteryMatchInstance = MysteryMatchInstance;
export default MysteryMatchInstance;
