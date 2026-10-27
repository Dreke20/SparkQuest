/**
 * Sparky AI Conversation Heatmeter & 6-Axis Compatibility Radar Chart Module
 * Dynamically tracks chat momentum, prompts the optimal date window, and renders personality polygons.
 */

import AudioFX from './audio-fx.js';

class VibeHeatmeter {
  constructor() {
    this.heatmeterContainerId = 'chat-heatmeter-container';
    this.radarModalId = 'compatibility-radar-modal';
    this.currentScore = 35; // Default initial chat warmth
  }

  init() {
    this._injectRadarModal();
  }

  // Update chat heatmeter in chat view
  updateHeat(messagesCount = 3) {
    // Score increases with messages up to 98%
    this.currentScore = Math.min(25 + messagesCount * 14, 98);
    this._renderHeatmeterBadge();

    // Check if golden date invitation threshold hit
    if (this.currentScore >= 75) {
      this._showGoldenMomentAlert();
    }
  }

  _renderHeatmeterBadge() {
    let container = document.getElementById(this.heatmeterContainerId);
    if (!container) {
      const chatHeader = document.querySelector('.chat-header, #chat-header, .chat-view-header');
      if (chatHeader) {
        container = document.createElement('div');
        container.id = this.heatmeterContainerId;
        container.style.cssText = 'width:100%; padding:6px 14px; background:rgba(17,24,39,0.9); border-bottom:1px solid rgba(0,229,255,0.2); display:flex; align-items:center; justify-content:space-between; font-size:0.75rem;';
        chatHeader.parentNode.insertBefore(container, chatHeader.nextSibling);
      }
    }

    if (!container) return;

    let vibeLabel = '🥶 Icebreaker';
    let vibeColor = '#94A3B8';
    if (this.currentScore >= 80) {
      vibeLabel = '⚡ Spark on Fire (Date Ready!)';
      vibeColor = '#00E5FF';
    } else if (this.currentScore >= 55) {
      vibeLabel = '🔥 Chemistry Spiking';
      vibeColor = '#FF3F6C';
    } else if (this.currentScore >= 35) {
      vibeLabel = '😊 Warming Up';
      vibeColor = '#FFB800';
    }

    container.innerHTML = `
      <div style="display:flex; align-items:center; gap:8px;">
        <span style="font-weight:bold; color:${vibeColor};">${vibeLabel}</span>
        <div style="width:80px; height:6px; background:#1E293B; border-radius:3px; overflow:hidden;">
          <div style="width:${this.currentScore}%; height:100%; background:linear-gradient(90deg, #FFB800, #FF3F6C, #00E5FF); border-radius:3px; transition:width 0.4s ease;"></div>
        </div>
        <span style="color:#F1F5F9; font-weight:bold;">${this.currentScore}%</span>
      </div>
      <button onclick="VibeHeatmeterInstance.openRadar()" style="background:none; border:none; color:#00E5FF; font-size:0.75rem; text-decoration:underline; cursor:pointer;">
        📊 Vibe Radar
      </button>
    `;
  }

  _showGoldenMomentAlert() {
    if (document.getElementById('golden-moment-banner')) return;

    const banner = document.createElement('div');
    banner.id = 'golden-moment-banner';
    banner.style.cssText = 'background:linear-gradient(90deg, rgba(255,63,108,0.2), rgba(0,229,255,0.2)); border:1px solid rgba(0,229,255,0.5); border-radius:12px; padding:10px 14px; margin:10px; display:flex; flex-direction:column; gap:6px; animation:fadeIn 0.5s ease;';

    banner.innerHTML = `
      <div style="display:flex; align-items:center; justify-content:space-between;">
        <span style="font-weight:bold; font-size:0.8rem; color:#00E5FF;">✨ Sparky AI: Peak Chemistry Detected (${this.currentScore}%)!</span>
        <button onclick="document.getElementById('golden-moment-banner').remove()" style="background:none; border:none; color:#94A3B8; font-size:1rem; cursor:pointer;">&times;</button>
      </div>
      <div style="font-size:0.75rem; color:#F1F5F9;">The conversation momentum is optimal. Suggest a first date now!</div>
      <div style="display:flex; gap:6px; overflow-x:auto; padding-top:4px;">
        <button onclick="VibeHeatmeterInstance.insertInvite('☕ How about grabbing coffee this weekend?')" style="padding:4px 10px; font-size:0.72rem; border-radius:8px; background:#1A2235; border:1px solid #FF3F6C; color:#F1F5F9; white-space:nowrap; cursor:pointer;">☕ Grab Coffee</button>
        <button onclick="VibeHeatmeterInstance.insertInvite('🍸 I know a great speakeasy lounge nearby. Drinks this week?')" style="padding:4px 10px; font-size:0.72rem; border-radius:8px; background:#1A2235; border:1px solid #7B2FFF; color:#F1F5F9; white-space:nowrap; cursor:pointer;">🍸 Speakeasy Drinks</button>
        <button onclick="VibeHeatmeterInstance.insertInvite('🕹️ Arcade bar challenge: loser buys first round?')" style="padding:4px 10px; font-size:0.72rem; border-radius:8px; background:#1A2235; border:1px solid #00E5FF; color:#F1F5F9; white-space:nowrap; cursor:pointer;">🕹️ Arcade Challenge</button>
      </div>
    `;

    const chatBody = document.querySelector('.chat-messages, #chat-messages, .messages-list');
    if (chatBody) {
      chatBody.insertBefore(banner, chatBody.firstChild);
      AudioFX.playPing();
    }
  }

  insertInvite(text) {
    const input = document.getElementById('chat-input') || document.querySelector('.chat-input, input[type="text"]');
    if (input) {
      input.value = text;
      input.focus();
    }
    const banner = document.getElementById('golden-moment-banner');
    if (banner) banner.remove();
  }

  _injectRadarModal() {
    if (document.getElementById(this.radarModalId)) return;

    const modal = document.createElement('div');
    modal.id = this.radarModalId;
    modal.className = 'modal-overlay';
    modal.style.cssText = 'display:none; z-index:10007; align-items:center; justify-content:center; background:rgba(11,15,26,0.9); backdrop-filter:blur(8px);';

    modal.innerHTML = `
      <div class="modal-card" style="background:#111827; border:1px solid rgba(0,229,255,0.4); border-radius:24px; max-width:380px; width:92%; padding:22px; text-align:center; box-shadow:0 0 35px rgba(0,229,255,0.25); position:relative;">
        <button onclick="VibeHeatmeterInstance.closeRadar()" style="position:absolute; top:16px; right:16px; background:none; border:none; color:#94A3B8; font-size:1.4rem; cursor:pointer;">&times;</button>
        
        <div style="font-size:1.8rem; margin-bottom:4px;">📊</div>
        <h2 style="margin:0 0 4px 0; color:#F1F5F9; font-family:'Outfit',sans-serif; font-size:1.35rem; letter-spacing:1px;">6-AXIS VIBE RADAR</h2>
        <p style="color:#94A3B8; font-size:0.8rem; margin-bottom:14px;">Comparing your RPG Explorer attributes with your match.</p>

        <!-- Canvas -->
        <canvas id="vibe-radar-canvas" width="280" height="260" style="margin:0 auto; display:block;"></canvas>

        <!-- Legend -->
        <div style="display:flex; justify-content:center; gap:20px; font-size:0.75rem; margin-top:10px; margin-bottom:14px;">
          <div style="display:flex; align-items:center; gap:6px;">
            <div style="width:12px; height:12px; background:rgba(0,229,255,0.7); border-radius:2px;"></div>
            <span style="color:#00E5FF; font-weight:bold;">You (Alex)</span>
          </div>
          <div style="display:flex; align-items:center; gap:6px;">
            <div style="width:12px; height:12px; background:rgba(255,63,108,0.7); border-radius:2px;"></div>
            <span style="color:#FF3F6C; font-weight:bold;">Match (Sophia)</span>
          </div>
        </div>

        <div style="background:#1A2235; padding:10px 14px; border-radius:12px; font-size:0.8rem; color:#F1F5F9; text-align:left;">
          🔥 <strong>Highest Resonance:</strong> <span style="color:#00E5FF;">Spontaneity (94%)</span> & <span style="color:#FFB800;">Wit (88%)</span>. You two thrive on playful banter and unscripted adventures!
        </div>
      </div>
    `;

    document.body.appendChild(modal);
  }

  openRadar() {
    this._injectRadarModal();
    const modal = document.getElementById(this.radarModalId);
    if (modal) {
      modal.style.display = 'flex';
      this._drawRadar();
      AudioFX.playClick();
    }
  }

  closeRadar() {
    const modal = document.getElementById(this.radarModalId);
    if (modal) modal.style.display = 'none';
  }

  _drawRadar() {
    const canvas = document.getElementById('vibe-radar-canvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const width = canvas.width;
    const height = canvas.height;
    const centerX = width / 2;
    const centerY = height / 2;
    const radius = Math.min(centerX, centerY) - 34;

    ctx.clearRect(0, 0, width, height);

    const axes = [
      { name: '🧗 Adventure', you: 0.85, match: 0.90 },
      { name: '🧠 Wit', you: 0.92, match: 0.88 },
      { name: '🎭 Humor', you: 0.80, match: 0.85 },
      { name: '⚡ Energy', you: 0.75, match: 0.70 },
      { name: '🔮 Spontaneity', you: 0.90, match: 0.94 },
      { name: '💖 Romance', you: 0.78, match: 0.82 },
    ];
    const totalAxes = axes.length;
    const angleStep = (2 * Math.PI) / totalAxes;

    // Concentric Web Rings
    for (let level = 1; level <= 4; level++) {
      const r = (radius / 4) * level;
      ctx.beginPath();
      for (let i = 0; i < totalAxes; i++) {
        const angle = i * angleStep - Math.PI / 2;
        const x = centerX + r * Math.cos(angle);
        const y = centerY + r * Math.sin(angle);
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.closePath();
      ctx.strokeStyle = 'rgba(255,255,255,0.08)';
      ctx.lineWidth = 1;
      ctx.stroke();
    }

    // Spokes and Labels
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.font = 'bold 9px Outfit, sans-serif';

    for (let i = 0; i < totalAxes; i++) {
      const angle = i * angleStep - Math.PI / 2;
      const x = centerX + radius * Math.cos(angle);
      const y = centerY + radius * Math.sin(angle);

      // Spoke
      ctx.beginPath();
      ctx.moveTo(centerX, centerY);
      ctx.lineTo(x, y);
      ctx.strokeStyle = 'rgba(255,255,255,0.1)';
      ctx.stroke();

      // Axis label
      const labelX = centerX + (radius + 20) * Math.cos(angle);
      const labelY = centerY + (radius + 18) * Math.sin(angle);
      ctx.fillStyle = '#94A3B8';
      ctx.fillText(axes[i].name, labelX, labelY);
    }

    // Polygon 1: You (Neon Cyan)
    this._drawPolygon(ctx, centerX, centerY, radius, axes.map(a => a.you), 'rgba(0,229,255,0.3)', '#00E5FF');

    // Polygon 2: Match (Spark Coral)
    this._drawPolygon(ctx, centerX, centerY, radius, axes.map(a => a.match), 'rgba(255,63,108,0.3)', '#FF3F6C');
  }

  _drawPolygon(ctx, cx, cy, maxRadius, values, fillColor, strokeColor) {
    const total = values.length;
    const angleStep = (2 * Math.PI) / total;

    ctx.beginPath();
    for (let i = 0; i < total; i++) {
      const angle = i * angleStep - Math.PI / 2;
      const r = maxRadius * values[i];
      const x = cx + r * Math.cos(angle);
      const y = cy + r * Math.sin(angle);
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    ctx.closePath();
    ctx.fillStyle = fillColor;
    ctx.fill();
    ctx.strokeStyle = strokeColor;
    ctx.lineWidth = 2;
    ctx.stroke();

    // Data points
    for (let i = 0; i < total; i++) {
      const angle = i * angleStep - Math.PI / 2;
      const r = maxRadius * values[i];
      const x = cx + r * Math.cos(angle);
      const y = cy + r * Math.sin(angle);
      ctx.beginPath();
      ctx.arc(x, y, 3, 0, 2 * Math.PI);
      ctx.fillStyle = strokeColor;
      ctx.fill();
    }
  }
}

const VibeHeatmeterInstance = new VibeHeatmeter();
window.VibeHeatmeterInstance = VibeHeatmeterInstance;
export default VibeHeatmeterInstance;
