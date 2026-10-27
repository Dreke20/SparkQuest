// SparkQuest Date Shield & Safety Escape System
import { Haptics, ImpactStyle } from '@capacitor/haptics';

export const DateShield = {
  isActive: false,
  timerInterval: null,
  remainingSeconds: 0,
  audioContext: null,
  ringtoneInterval: null,

  openShieldModal() {
    const modal = document.getElementById('date-shield-setup-modal');
    if (modal) modal.style.display = 'flex';
  },

  startShield(minutes = 45) {
    this.isActive = true;
    this.remainingSeconds = minutes * 60;
    this.updateShieldUI();

    if (this.timerInterval) clearInterval(this.timerInterval);

    this.timerInterval = setInterval(() => {
      this.remainingSeconds--;
      this.updateShieldUI();

      if (this.remainingSeconds <= 0) {
        clearInterval(this.timerInterval);
        this.triggerCheckIn();
      }
    }, 1000);

    if (typeof window.closeModal === 'function') {
      window.closeModal('date-shield-setup-modal');
    }

    if (typeof window.showToast === 'function') {
      window.showToast(`🛡️ Date Shield activated for ${minutes} minutes. We've got your back!`, 'info');
    }
  },

  updateShieldUI() {
    const banner = document.getElementById('date-shield-banner');
    if (!banner) return;

    if (this.isActive && this.remainingSeconds > 0) {
      banner.style.display = 'flex';
      const m = Math.floor(this.remainingSeconds / 60);
      const s = this.remainingSeconds % 60;
      const timeStr = `${m}:${String(s).padStart(2, '0')}`;
      const timeEl = document.getElementById('shield-timer-display');
      if (timeEl) timeEl.textContent = timeStr;
    } else {
      banner.style.display = 'none';
    }
  },

  triggerCheckIn() {
    this.isActive = false;
    this.updateShieldUI();

    try {
      Haptics.impact({ style: ImpactStyle.Heavy }).catch(() => {});
    } catch (e) {}

    const checkinModal = document.getElementById('date-shield-checkin-modal');
    if (checkinModal) checkinModal.style.display = 'flex';
  },

  extendShield(minutes = 30) {
    this.startShield(minutes);
    if (typeof window.closeModal === 'function') {
      window.closeModal('date-shield-checkin-modal');
    }
    if (typeof window.showToast === 'function') {
      window.showToast(`Shield extended +${minutes} mins. Have fun! ✨`, 'info');
    }
  },

  completeSafely() {
    this.isActive = false;
    if (this.timerInterval) clearInterval(this.timerInterval);
    this.updateShieldUI();

    if (typeof window.closeModal === 'function') {
      window.closeModal('date-shield-checkin-modal');
    }

    if (window.currentUserUid && window.DB_Service) {
      window.DB_Service.updateEmbers(window.currentUserUid, 25);
    } else {
      window.embers = (window.embers || 0) + 25;
      if (typeof window.updateEmberDisplay === 'function') window.updateEmberDisplay();
    }

    if (typeof window.showToast === 'function') {
      window.showToast(`Glad you had a safe date! +25 Embers reward 🔥`, 'earn', '+25');
    }
  },

  // Synthesized Ringtone using Web Audio API (Zero external MP3 dependencies)
  startRingtone() {
    try {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (!AudioCtx) return;
      this.audioContext = new AudioCtx();

      const playChime = () => {
        if (!this.audioContext) return;
        const osc = this.audioContext.createOscillator();
        const gain = this.audioContext.createGain();

        osc.type = 'sine';
        osc.frequency.setValueAtTime(853, this.audioContext.currentTime);
        osc.frequency.exponentialRampToValueAtTime(960, this.audioContext.currentTime + 0.3);

        gain.gain.setValueAtTime(0.2, this.audioContext.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.6);

        osc.connect(gain);
        gain.connect(this.audioContext.destination);

        osc.start();
        osc.stop(this.audioContext.currentTime + 0.6);
      };

      playChime();
      this.ringtoneInterval = setInterval(playChime, 1800);
    } catch (e) {
      console.warn('Audio Context ringtone init failed:', e);
    }
  },

  stopRingtone() {
    if (this.ringtoneInterval) {
      clearInterval(this.ringtoneInterval);
      this.ringtoneInterval = null;
    }
    if (this.audioContext) {
      this.audioContext.close().catch(() => {});
      this.audioContext = null;
    }
  },

  // Fake Incoming Call (Escape Strategy)
  triggerFakeCall(callerName = "Mom") {
    if (typeof window.closeModal === 'function') {
      window.closeModal('date-shield-checkin-modal');
      window.closeModal('date-shield-setup-modal');
    }

    const fakeCallModal = document.getElementById('fake-call-modal');
    if (!fakeCallModal) return;

    document.getElementById('fake-call-name').textContent = callerName;
    document.getElementById('fake-call-ringing-ui').style.display = 'flex';
    document.getElementById('fake-call-connected-ui').style.display = 'none';

    fakeCallModal.style.display = 'flex';
    this.startRingtone();

    try {
      Haptics.impact({ style: ImpactStyle.Heavy }).catch(() => {});
    } catch (e) {}
  },

  acceptFakeCall() {
    this.stopRingtone();
    document.getElementById('fake-call-ringing-ui').style.display = 'none';
    const connectedUi = document.getElementById('fake-call-connected-ui');
    connectedUi.style.display = 'flex';

    let seconds = 0;
    const timerEl = document.getElementById('fake-call-duration');
    const callTimer = setInterval(() => {
      seconds++;
      const m = Math.floor(seconds / 60);
      const s = seconds % 60;
      if (timerEl) timerEl.textContent = `${m}:${String(s).padStart(2, '0')}`;
    }, 1000);

    connectedUi.dataset.intervalId = callTimer;
  },

  endFakeCall() {
    this.stopRingtone();
    const connectedUi = document.getElementById('fake-call-connected-ui');
    if (connectedUi?.dataset.intervalId) {
      clearInterval(parseInt(connectedUi.dataset.intervalId));
    }

    const fakeCallModal = document.getElementById('fake-call-modal');
    if (fakeCallModal) fakeCallModal.style.display = 'none';

    if (typeof window.showToast === 'function') {
      window.showToast('Fake call completed. Polite exit unlocked!', 'info');
    }
  }
};

window.DateShield = DateShield;
export default DateShield;
