/**
 * VoiceSparks Module for SparkQuest
 * 15-Second Audio Prompts with Dynamic Waveform Visualizer.
 * Supports native/browser audio recording and procedural playback for seed profiles.
 */

import AudioFX from './audio-fx.js';

class VoiceSparksEngine {
  constructor() {
    this.mediaRecorder = null;
    this.audioChunks = [];
    this.recordingTimer = null;
    this.secondsRemaining = 15;
    this.currentPlayingId = null;
    this.currentAudioObj = null;
    this.animFrameId = null;
    this.audioCtx = null;
    this.synthOsc = null;

    // Seed prompt templates
    this.prompts = [
      { id: 'travel', text: "My most unhinged travel story ✈️", duration: 12 },
      { id: 'pizza', text: "Hot take on pineapple pizza 🍕", duration: 9 },
      { id: 'sleepy', text: "What my voice sounds like at 7 AM ☕", duration: 11 },
      { id: 'talent', text: "My secret, completely useless talent 🪄", duration: 14 },
      { id: 'sunday', text: "My idea of the perfect Sunday morning 🌅", duration: 10 }
    ];

    // Seed profile audio configurations (pitch/vibe mapping)
    this.seedVoiceMap = {
      seed_sophia: { prompt: "My idea of the perfect Sunday morning 🌅", baseFreq: 260, duration: 8 },
      seed_alex: { prompt: "My secret, completely useless talent 🪄", baseFreq: 140, duration: 10 },
      seed_maya: { prompt: "My most unhinged travel story ✈️", baseFreq: 280, duration: 9 },
      seed_jordan: { prompt: "What my voice sounds like at 7 AM ☕", baseFreq: 120, duration: 11 },
      seed_riley: { prompt: "Hot take on pineapple pizza 🍕", baseFreq: 220, duration: 7 },
      seed_taylor: { prompt: "My most unhinged travel story ✈️", baseFreq: 200, duration: 9 }
    };
  }

  getProfilePrompt(profileId) {
    if (this.seedVoiceMap[profileId]) {
      return this.seedVoiceMap[profileId];
    }
    // Check local user recording
    const userPrompt = localStorage.getItem('sparkquest_user_voice');
    if (userPrompt) {
      try {
        return JSON.parse(userPrompt);
      } catch (e) {}
    }
    return { prompt: "My secret, completely useless talent 🪄", duration: 10 };
  }

  // Renders the Voice Spark pill directly inside a profile card
  renderVoiceSparkPill(profile) {
    const voiceInfo = this.getProfilePrompt(profile.id);
    const safePrompt = voiceInfo.prompt.replace(/"/g, '&quot;');
    const isPlaying = this.currentPlayingId === profile.id;

    return `
      <div class="voice-spark-pill" id="voice-spark-${profile.id}" onclick="event.stopPropagation(); window.VoiceSparks.togglePlayback('${profile.id}')">
        <button class="voice-play-btn" id="voice-btn-${profile.id}" aria-label="Play Voice Spark">
          <i class="fas ${isPlaying ? 'fa-pause' : 'fa-play'}"></i>
        </button>
        <div class="voice-spark-details">
          <span class="voice-prompt-title">${safePrompt}</span>
          <div class="voice-waveform-container">
            <canvas class="voice-waveform-canvas" id="waveform-${profile.id}" width="160" height="24"></canvas>
            <span class="voice-duration" id="duration-${profile.id}">${isPlaying ? 'Playing...' : voiceInfo.duration + 's'}</span>
          </div>
        </div>
      </div>
    `;
  }

  togglePlayback(profileId) {
    AudioFX.playPop();
    if (this.currentPlayingId === profileId) {
      this.stopPlayback();
      return;
    }

    this.stopPlayback();
    this.currentPlayingId = profileId;
    this.updatePillUI(profileId, true);

    // If local user has custom recorded data URL
    const userVoice = localStorage.getItem('sparkquest_user_voice');
    let customAudioData = null;
    if (profileId === 'user_current' && userVoice) {
      try {
        customAudioData = JSON.parse(userVoice).audioData;
      } catch (e) {}
    }

    if (customAudioData) {
      this.playRecordedAudio(customAudioData, profileId);
    } else {
      this.playSyntheticVoice(profileId);
    }
  }

  // Synthetic speech tone simulation using modulated vocal harmonic formants
  playSyntheticVoice(profileId) {
    const AudioCtx = window.AudioContext || window.webkitAudioContext;
    if (!AudioCtx) return;
    this.audioCtx = new AudioCtx();
    if (this.audioCtx.state === 'suspended') {
      this.audioCtx.resume();
    }

    const voiceInfo = this.seedVoiceMap[profileId] || { baseFreq: 180, duration: 8 };
    const baseFreq = voiceInfo.baseFreq;
    const duration = voiceInfo.duration;

    const osc = this.audioCtx.createOscillator();
    const subOsc = this.audioCtx.createOscillator();
    const gainNode = this.audioCtx.createGain();
    const filter = this.audioCtx.createBiquadFilter();

    osc.type = 'sawtooth';
    subOsc.type = 'sine';

    filter.type = 'bandpass';
    filter.frequency.setValueAtTime(baseFreq * 2.5, this.audioCtx.currentTime);
    filter.Q.setValueAtTime(3.0, this.audioCtx.currentTime);

    // Dynamic pitch modulation simulating conversational cadence
    const now = this.audioCtx.currentTime;
    for (let t = 0; t < duration; t += 0.3) {
      const pitchOffset = (Math.sin(t * 3.5) * 25) + (Math.cos(t * 1.8) * 15);
      osc.frequency.setValueAtTime(baseFreq + pitchOffset, now + t);
      subOsc.frequency.setValueAtTime((baseFreq + pitchOffset) * 0.5, now + t);
    }

    gainNode.gain.setValueAtTime(0.001, now);
    gainNode.gain.linearRampToValueAtTime(0.06, now + 0.1);
    gainNode.gain.setValueAtTime(0.06, now + duration - 0.4);
    gainNode.gain.exponentialRampToValueAtTime(0.001, now + duration);

    osc.connect(filter);
    subOsc.connect(filter);
    filter.connect(gainNode);
    gainNode.connect(this.audioCtx.destination);

    osc.start(now);
    subOsc.start(now);
    osc.stop(now + duration);
    subOsc.stop(now + duration);

    this.synthOsc = osc;
    this.startWaveformAnimation(profileId, duration);

    osc.onended = () => {
      this.stopPlayback();
    };
  }

  playRecordedAudio(dataUrl, profileId) {
    this.currentAudioObj = new Audio(dataUrl);
    this.currentAudioObj.play().catch(e => console.warn(e));
    this.startWaveformAnimation(profileId, this.currentAudioObj.duration || 10);
    this.currentAudioObj.onended = () => {
      this.stopPlayback();
    };
  }

  startWaveformAnimation(profileId, totalDuration) {
    const canvas = document.getElementById(`waveform-${profileId}`);
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const startTime = Date.now();

    const animate = () => {
      if (this.currentPlayingId !== profileId) return;
      const elapsed = (Date.now() - startTime) / 1000;
      const progress = Math.min(1, elapsed / totalDuration);

      ctx.clearRect(0, 0, canvas.width, canvas.height);
      const bars = 24;
      const barWidth = 4;
      const gap = (canvas.width - bars * barWidth) / (bars - 1);

      for (let i = 0; i < bars; i++) {
        const x = i * (barWidth + gap);
        const barProgress = i / bars;
        // Animated height with sine waves
        const wave = Math.sin(elapsed * 8 + i * 0.5) * 0.5 + 0.5;
        const height = Math.max(4, wave * (canvas.height - 4));
        const y = (canvas.height - height) / 2;

        ctx.fillStyle = barProgress <= progress ? '#00E5FF' : 'rgba(255, 255, 255, 0.25)';
        ctx.beginPath();
        ctx.roundRect(x, y, barWidth, height, 2);
        ctx.fill();
      }

      if (progress < 1) {
        this.animFrameId = requestAnimationFrame(animate);
      } else {
        this.stopPlayback();
      }
    };
    animate();
  }

  stopPlayback() {
    if (this.currentAudioObj) {
      this.currentAudioObj.pause();
      this.currentAudioObj = null;
    }
    if (this.synthOsc) {
      try { this.synthOsc.stop(); } catch (e) {}
      this.synthOsc = null;
    }
    if (this.audioCtx) {
      try { this.audioCtx.close(); } catch (e) {}
      this.audioCtx = null;
    }
    if (this.animFrameId) {
      cancelAnimationFrame(this.animFrameId);
      this.animFrameId = null;
    }
    if (this.currentPlayingId) {
      this.updatePillUI(this.currentPlayingId, false);
      this.currentPlayingId = null;
    }
  }

  updatePillUI(profileId, isPlaying) {
    const btn = document.getElementById(`voice-btn-${profileId}`);
    const dur = document.getElementById(`duration-${profileId}`);
    if (btn) {
      btn.innerHTML = `<i class="fas ${isPlaying ? 'fa-pause' : 'fa-play'}"></i>`;
    }
    if (dur && !isPlaying) {
      const voiceInfo = this.getProfilePrompt(profileId);
      dur.textContent = voiceInfo.duration + 's';
    }
  }

  // Record custom voice prompt flow
  openRecorderModal() {
    AudioFX.playPop();
    const existing = document.getElementById('voice-recorder-modal');
    if (existing) existing.remove();

    const randomPrompt = this.prompts[Math.floor(Math.random() * this.prompts.length)];

    const modal = document.createElement('div');
    modal.id = 'voice-recorder-modal';
    modal.className = 'custom-module-modal active';
    modal.innerHTML = `
      <div class="modal-card voice-record-card">
        <div class="modal-header">
          <h3><i class="fas fa-microphone-lines" style="color:var(--cyan); margin-right:8px;"></i>Voice Spark</h3>
          <button class="close-modal-btn" onclick="document.getElementById('voice-recorder-modal').remove()">&times;</button>
        </div>
        <div class="voice-modal-content">
          <p class="voice-subtitle">Record a 15-second voice snippet to reveal your vibe.</p>
          <div class="prompt-selector-box">
            <span class="prompt-badge">Your Prompt</span>
            <h4 id="active-prompt-text">${randomPrompt.text}</h4>
            <button class="shuffle-prompt-btn" onclick="window.VoiceSparks.shufflePrompt()">
              <i class="fas fa-rotate"></i> Change Prompt
            </button>
          </div>
          <div class="record-visualizer-container">
            <div class="record-timer" id="record-timer-display">00:15</div>
            <div class="record-pulse-ring" id="record-pulse-ring"></div>
            <button class="record-trigger-btn" id="record-trigger-btn" onclick="window.VoiceSparks.toggleRecording()">
              <i class="fas fa-microphone"></i>
            </button>
          </div>
          <p class="record-instruction" id="record-instruction-label">Tap microphone to begin</p>
          <div class="record-actions" id="record-actions-panel" style="display:none;">
            <button class="action-btn-secondary" onclick="window.VoiceSparks.resetRecording()"><i class="fas fa-trash"></i> Retake</button>
            <button class="action-btn-primary" onclick="window.VoiceSparks.saveRecording()"><i class="fas fa-check"></i> Save to Profile</button>
          </div>
        </div>
      </div>
    `;
    document.body.appendChild(modal);
  }

  shufflePrompt() {
    AudioFX.playPop();
    const randomPrompt = this.prompts[Math.floor(Math.random() * this.prompts.length)];
    const el = document.getElementById('active-prompt-text');
    if (el) el.textContent = randomPrompt.text;
  }

  async toggleRecording() {
    if (this.mediaRecorder && this.mediaRecorder.state === 'recording') {
      this.stopRecording();
      return;
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      this.audioChunks = [];
      this.mediaRecorder = new MediaRecorder(stream);
      this.mediaRecorder.ondataavailable = (e) => {
        if (e.data.size > 0) this.audioChunks.push(e.data);
      };
      this.mediaRecorder.onstop = () => {
        stream.getTracks().forEach(track => track.stop());
        const audioBlob = new Blob(this.audioChunks, { type: 'audio/webm' });
        const reader = new FileReader();
        reader.onloadend = () => {
          this.recordedDataUrl = reader.result;
          const actions = document.getElementById('record-actions-panel');
          const instr = document.getElementById('record-instruction-label');
          if (actions) actions.style.display = 'flex';
          if (instr) instr.textContent = 'Voice spark recorded! Tap Save to finish.';
        };
        reader.readAsDataURL(audioBlob);
      };

      this.mediaRecorder.start();
      AudioFX.playChallenge();
      this.secondsRemaining = 15;
      const btn = document.getElementById('record-trigger-btn');
      const ring = document.getElementById('record-pulse-ring');
      const instr = document.getElementById('record-instruction-label');
      if (btn) btn.classList.add('recording');
      if (ring) ring.classList.add('active');
      if (instr) instr.textContent = 'Recording... Speak now!';

      this.recordingTimer = setInterval(() => {
        this.secondsRemaining--;
        const timerDisplay = document.getElementById('record-timer-display');
        if (timerDisplay) {
          timerDisplay.textContent = `00:${this.secondsRemaining.toString().padStart(2, '0')}`;
        }
        if (this.secondsRemaining <= 0) {
          this.stopRecording();
        }
      }, 1000);
    } catch (err) {
      console.warn('[VoiceSparks] Mic access error:', err);
      // Fallback simulation if running in WebView or denied permissions
      this.simulateRecording();
    }
  }

  simulateRecording() {
    this.secondsRemaining = 15;
    const btn = document.getElementById('record-trigger-btn');
    const ring = document.getElementById('record-pulse-ring');
    const instr = document.getElementById('record-instruction-label');
    if (btn) btn.classList.add('recording');
    if (ring) ring.classList.add('active');
    if (instr) instr.textContent = 'Recording sample... Speak now!';

    this.recordingTimer = setInterval(() => {
      this.secondsRemaining--;
      const timerDisplay = document.getElementById('record-timer-display');
      if (timerDisplay) {
        timerDisplay.textContent = `00:${this.secondsRemaining.toString().padStart(2, '0')}`;
      }
      if (this.secondsRemaining <= 10) {
        clearInterval(this.recordingTimer);
        if (btn) btn.classList.remove('recording');
        if (ring) ring.classList.remove('active');
        const actions = document.getElementById('record-actions-panel');
        if (actions) actions.style.display = 'flex';
        if (instr) instr.textContent = 'Voice spark captured! Tap Save to finish.';
      }
    }, 1000);
  }

  stopRecording() {
    if (this.recordingTimer) {
      clearInterval(this.recordingTimer);
      this.recordingTimer = null;
    }
    if (this.mediaRecorder && this.mediaRecorder.state === 'recording') {
      this.mediaRecorder.stop();
    }
    const btn = document.getElementById('record-trigger-btn');
    const ring = document.getElementById('record-pulse-ring');
    if (btn) btn.classList.remove('recording');
    if (ring) ring.classList.remove('active');
  }

  resetRecording() {
    AudioFX.playPop();
    this.audioChunks = [];
    this.recordedDataUrl = null;
    const actions = document.getElementById('record-actions-panel');
    const instr = document.getElementById('record-instruction-label');
    const timerDisplay = document.getElementById('record-timer-display');
    if (actions) actions.style.display = 'none';
    if (instr) instr.textContent = 'Tap microphone to begin';
    if (timerDisplay) timerDisplay.textContent = '00:15';
  }

  saveRecording() {
    AudioFX.playLevelUp();
    const promptText = document.getElementById('active-prompt-text')?.textContent || "Voice Spark";
    const voiceData = {
      prompt: promptText,
      duration: 15 - this.secondsRemaining || 12,
      audioData: this.recordedDataUrl || null,
      updatedAt: Date.now()
    };
    localStorage.setItem('sparkquest_user_voice', JSON.stringify(voiceData));

    // Award bonus embers for recording first voice spark
    if (!localStorage.getItem('sparkquest_voice_bonus')) {
      localStorage.setItem('sparkquest_voice_bonus', 'true');
      if (typeof window.embers === 'number') {
        window.embers += 50;
        AudioFX.playEmberClaim();
        if (window.DB_Service && window.currentUserUid) {
          window.DB_Service.updateUserStats(window.currentUserUid, { embers: window.embers });
        }
      }
    }

    const modal = document.getElementById('voice-recorder-modal');
    if (modal) modal.remove();
    alert('🎉 Voice Spark saved! Your profile will now play your voice clip.');
  }
}

const VoiceSparks = new VoiceSparksEngine();
export default VoiceSparks;
