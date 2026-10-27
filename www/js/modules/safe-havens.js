/**
 * Safe Haven Partner Venues & Proximity Beacon Module for SparkQuest
 * Features verified safety date spots, 15% discount perks, and nearby explorer proximity alerts.
 */

import AudioFX from './audio-fx.js';

class SafeHavens {
  constructor() {
    this.modalId = 'safe-haven-venue-modal';
    this.activeVenue = null;

    this.venues = [
      {
        id: 'venue_skyline',
        name: 'The Skyline Lounge [Safe Haven]',
        category: '🍸 Cocktail & Rooftop Lounge',
        address: '240 High Street, 14th Floor',
        distance: '0.4 mi away',
        discount: '15% Off Total Bill (Code: SPARK15)',
        safetyFeatures: ['Trained Angel Shot Staff', 'Private Corner Booths', 'Security Escort Available'],
        icon: '🍸'
      },
      {
        id: 'venue_boathouse',
        name: 'The Boathouse Cafe [Safe Haven]',
        category: '☕ Artisan Coffee & Bakery',
        address: '88 Waterfront Esplanade',
        distance: '0.2 mi away',
        discount: 'Buy 1 Specialty Latte, Get 1 Free',
        safetyFeatures: ['Well-Lit Open Patio', 'Direct Transit Access', 'Discrete Check-out System'],
        icon: '☕'
      },
      {
        id: 'venue_retro_arcade',
        name: 'Neon Pixel Arcade [Safe Haven]',
        category: '🕹️ Retro Gaming & Taproom',
        address: '512 Cyber Lane',
        distance: '0.8 mi away',
        discount: 'Free 20 Game Tokens for First Dates',
        safetyFeatures: ['Public High-Energy Space', 'All-Gender Single Restrooms', 'Friendly Host Desk'],
        icon: '🕹️'
      }
    ];

    this.simulatedBeacons = [
      { name: 'Maya', age: 25, compatPct: 92, venue: 'The Boathouse Cafe', distanceFt: 280, photo: 'img/maya.png' },
      { name: 'Sophia', age: 24, compatPct: 95, venue: 'The Skyline Lounge', distanceFt: 350, photo: 'img/sophia.png' }
    ];
  }

  init() {
    this._injectModal();
    this._startProximityCheck();
  }

  _injectModal() {
    if (document.getElementById(this.modalId)) return;

    const modal = document.createElement('div');
    modal.id = this.modalId;
    modal.className = 'modal-overlay';
    modal.style.cssText = 'display:none; z-index:10008; align-items:center; justify-content:center; background:rgba(11,15,26,0.9); backdrop-filter:blur(8px);';

    modal.innerHTML = `
      <div class="modal-card" style="background:#111827; border:1px solid rgba(255,184,0,0.5); border-radius:24px; max-width:380px; width:92%; padding:24px; text-align:left; box-shadow:0 0 35px rgba(255,184,0,0.25); position:relative;">
        <button onclick="SafeHavensInstance.close()" style="position:absolute; top:16px; right:16px; background:none; border:none; color:#94A3B8; font-size:1.4rem; cursor:pointer;">&times;</button>
        
        <div style="display:flex; align-items:center; gap:8px; margin-bottom:12px;">
          <div style="padding:8px; border-radius:12px; background:rgba(255,184,0,0.15); font-size:1.5rem;">🛡️</div>
          <div>
            <div style="font-size:0.75rem; color:#FFB800; font-weight:bold; letter-spacing:1px;">VERIFIED DATE SHIELD PARTNER</div>
            <h3 id="sh-venue-name" style="margin:0; color:#F1F5F9; font-size:1.25rem; font-family:'Outfit',sans-serif;">Venue Name</h3>
          </div>
        </div>

        <div id="sh-venue-cat" style="font-size:0.85rem; color:#94A3B8; margin-bottom:14px;">Cocktails • 0.3 mi away</div>

        <!-- Perk Box -->
        <div style="background:rgba(255,184,0,0.1); border:1px dashed #FFB800; border-radius:14px; padding:12px; margin-bottom:14px;">
          <div style="font-size:0.75rem; color:#FFB800; font-weight:bold;">🎁 SPARKQUEST DATE PERK</div>
          <div id="sh-venue-discount" style="font-size:0.9rem; font-weight:bold; color:#F1F5F9; margin-top:2px;">15% Off Total Bill (Code: SPARK15)</div>
        </div>

        <!-- Safety Features -->
        <div style="font-size:0.75rem; color:#00E5FF; font-weight:bold; letter-spacing:1px; margin-bottom:8px;">ON-SITE SAFETY AMENITIES</div>
        <div id="sh-venue-amenities" style="margin-bottom:18px; display:flex; flex-direction:column; gap:6px;">
          <!-- Amenity items -->
        </div>

        <div style="display:flex; gap:10px;">
          <button onclick="SafeHavensInstance.inviteToVenue()" class="btn-primary" style="flex:1; padding:12px; border-radius:14px; font-weight:bold; background:linear-gradient(90deg, #FFB800, #FF3F6C); border:none; cursor:pointer;">
            📍 Meet Here
          </button>
          <button onclick="SafeHavensInstance.close()" class="btn-outline" style="padding:12px 18px; border-radius:14px; font-weight:bold; border:1px solid #94A3B8; color:#F1F5F9; background:transparent; cursor:pointer;">
            Close
          </button>
        </div>
      </div>
    `;

    document.body.appendChild(modal);
  }

  showVenue(venueId) {
    this._injectModal();
    const venue = this.venues.find(v => v.id === venueId) || this.venues[0];
    this.activeVenue = venue;

    const nameEl = document.getElementById('sh-venue-name');
    const catEl = document.getElementById('sh-venue-cat');
    const discEl = document.getElementById('sh-venue-discount');
    const amenEl = document.getElementById('sh-venue-amenities');

    if (nameEl) nameEl.textContent = venue.name;
    if (catEl) catEl.textContent = `${venue.category} • ${venue.address}`;
    if (discEl) discEl.textContent = venue.discount;

    if (amenEl) {
      amenEl.innerHTML = venue.safetyFeatures.map(feat => `
        <div style="display:flex; align-items:center; gap:8px; font-size:0.8rem; color:#F1F5F9;">
          <span style="color:#10B981;">✓</span>
          <span>${feat}</span>
        </div>
      `).join('');
    }

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

  inviteToVenue() {
    this.close();
    if (typeof window.navigate === 'function') {
      window.navigate('chat');
    }
    const input = document.getElementById('chat-input') || document.querySelector('.chat-input, input[type="text"]');
    if (input && this.activeVenue) {
      input.value = `Hey! How about meeting at ${this.activeVenue.name}? SparkQuest has a 15% discount for us there! ☕`;
      input.focus();
    }
    if (typeof window.showToast === 'function') {
      window.showToast(`Venue invitation prepared! 📍`);
    }
  }

  _startProximityCheck() {
    // Periodically trigger a simulated nearby beacon alert
    setTimeout(() => {
      this._triggerNearbyBeacon(this.simulatedBeacons[0]);
    }, 15000);
  }

  _triggerNearbyBeacon(beacon) {
    if (document.getElementById('proximity-beacon-toast')) return;

    const toast = document.createElement('div');
    toast.id = 'proximity-beacon-toast';
    toast.style.cssText = 'position:fixed; top:75px; left:50%; transform:translateX(-50%); width:90%; max-width:380px; background:#111827; border:1px solid #00E5FF; border-radius:18px; padding:14px; box-shadow:0 8px 30px rgba(0,229,255,0.3); z-index:9999; display:flex; align-items:center; gap:12px; animation:slideDown 0.4s ease;';

    toast.innerHTML = `
      <img src="${beacon.photo}" style="width:48px; height:48px; border-radius:50%; object-fit:cover; border:2px solid #00E5FF;">
      <div style="flex:1;">
        <div style="font-size:0.75rem; color:#00E5FF; font-weight:bold; letter-spacing:0.5px;">📡 PROXIMITY BEACON DETECTED</div>
        <div style="font-size:0.85rem; font-weight:bold; color:#F1F5F9;">${beacon.name} (${beacon.compatPct}% Match) is ${beacon.distanceFt} ft away!</div>
        <div style="font-size:0.75rem; color:#94A3B8;">Nearby at ${beacon.venue}</div>
      </div>
      <button onclick="SafeHavensInstance.sendWave('${beacon.name}')" style="background:linear-gradient(135deg, #FF3F6C, #00E5FF); border:none; border-radius:12px; padding:8px 12px; color:white; font-size:0.8rem; font-weight:bold; cursor:pointer;">
        🌊 Wave
      </button>
      <button onclick="document.getElementById('proximity-beacon-toast').remove()" style="background:none; border:none; color:#94A3B8; font-size:1.2rem; cursor:pointer;">&times;</button>
    `;

    document.body.appendChild(toast);
    AudioFX.playSonarPing();
  }

  sendWave(name) {
    const toast = document.getElementById('proximity-beacon-toast');
    if (toast) toast.remove();

    AudioFX.playPing();
    if (typeof window.showToast === 'function') {
      window.showToast(`Anonymous coffee wave sent to ${name}! 🌊`);
    }
  }
}

const SafeHavensInstance = new SafeHavens();
window.SafeHavensInstance = SafeHavensInstance;
export default SafeHavensInstance;
