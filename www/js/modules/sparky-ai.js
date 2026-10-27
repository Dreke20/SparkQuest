/**
 * Sparky AI: In-Chat Wingman & Smart Date Itinerary Planner for SparkQuest
 * Powered by contextual heuristic intelligence and local vibe synthesis.
 */

import AudioFX from './audio-fx.js';

class SparkyAIEngine {
  constructor() {
    this.itineraryTemplates = {
      creative: [
        { title: "Artisan Coffee & Matcha", time: "4:30 PM", loc: "Blue Velvet Atelier", desc: "Sip iced lavender matcha and break the ice over gallery sketches.", icon: "☕" },
        { title: "Indie Gallery Stroll", time: "5:45 PM", loc: "The District Collective", desc: "Explore local neon photography and pick your favorite art piece.", icon: "🎨" },
        { title: "Rooftop Stargazing & Cider", time: "7:15 PM", loc: "Skyline Pergola", desc: "Panoramic sunset views, heated lanterns, and craft elixirs.", icon: "🍸" }
      ],
      adventure: [
        { title: "Scenic Waterfront Ride", time: "3:00 PM", loc: "Harbor Esplanade", desc: "Rent dual electric scooters and cruise past the docks.", icon: "🛴" },
        { title: "Artisanal Taco Pitstop", time: "4:45 PM", loc: "Fuego Taqueria", desc: "Birria tacos and fresh horchata on the outdoor patio.", icon: "🌮" },
        { title: "Secret Viewpoint Quest", time: "6:15 PM", loc: "Highland Overlook", desc: "A 10-minute walk to the highest lookout in the city.", icon: "🌅" }
      ],
      playful: [
        { title: "Retro Arcade & Pinball Duel", time: "5:00 PM", loc: "Neon 84 Arcade Bar", desc: "Compete in air hockey and vintage Mario Kart for bragging rights.", icon: "🕹️" },
        { title: "Street Food Bites", time: "6:30 PM", loc: "Night Market Alley", desc: "Share dumpling skewers and Korean shaved ice.", icon: "🥟" },
        { title: "Late-Night Vinyl Hunt", time: "7:45 PM", loc: "Spin City Records", desc: "Pick one record for each other based purely on cover art.", icon: "🎵" }
      ]
    };
  }

  // Get 3 contextual wingman suggestions based on match tags
  getWingmanSuggestions(match) {
    const tags = match.tags || [];
    const name = match.name || 'your match';

    const suggestions = [];

    if (tags.some(t => t.includes('Art') || t.includes('Design') || t.includes('Photo'))) {
      suggestions.push(`"If you had to curate a photo gallery of your past year in 3 pictures, what's on the walls?"`);
    }
    if (tags.some(t => t.includes('Coffee') || t.includes('Food') || t.includes('Cooking') || t.includes('Wine'))) {
      suggestions.push(`"Crucial compatibility test: what's your ultimate go-to coffee or comfort meal?"`);
    }
    if (tags.some(t => t.includes('Gaming') || t.includes('Tech'))) {
      suggestions.push(`"Quick question: are we teaming up in co-op mode or having an intense arcade showdown?"`);
    }
    if (tags.some(t => t.includes('Music') || t.includes('Guitar'))) {
      suggestions.push(`"What's one song that instantly resets your brain when you're in a funk?"`);
    }
    if (tags.some(t => t.includes('Travel') || t.includes('Hiking') || t.includes('Adventure'))) {
      suggestions.push(`"What's the most spontaneous detour you've ever taken while traveling?"`);
    }

    // Default witty / warm fallbacks
    if (suggestions.length < 3) {
      suggestions.push(`"I was just looking at your profile and had to ask — what's the story behind your bio?"`);
      suggestions.push(`"SparkQuest gave us high compatibility. Should we test it with a 10-question rapid fire?"`);
      suggestions.push(`"What's one thing you're deeply passionate about that most people find random?"`);
    }

    return suggestions.slice(0, 3);
  }

  // Renders the Wingman prompt chips above chat input
  renderWingmanBar(match) {
    const suggestions = this.getWingmanSuggestions(match);
    return `
      <div class="sparky-wingman-tray" id="sparky-wingman-tray">
        <div class="sparky-tray-header">
          <span><i class="fas fa-wand-magic-sparkles" style="color:var(--gold);"></i> <strong>Sparky Wingman</strong> suggestions:</span>
          <button class="sparky-close-btn" onclick="document.getElementById('sparky-wingman-tray').style.display='none'">&times;</button>
        </div>
        <div class="sparky-suggestions-list">
          ${suggestions.map(s => `
            <button class="sparky-suggestion-pill" onclick="window.SparkyAI.applySuggestion(${JSON.stringify(s)})">
              ${s}
            </button>
          `).join('')}
        </div>
      </div>
    `;
  }

  applySuggestion(text) {
    AudioFX.playPop();
    const chatInput = document.getElementById('chat-input') || document.querySelector('.chat-input-field');
    if (chatInput) {
      chatInput.value = text.replace(/^"|"$/g, '');
      chatInput.focus();
    }
    const tray = document.getElementById('sparky-wingman-tray');
    if (tray) tray.style.display = 'none';
  }

  // Generate Date Itinerary
  generateDateItinerary(match) {
    const tags = match.tags || [];
    let theme = 'creative';
    if (tags.some(t => t.includes('Gaming') || t.includes('Music') || t.includes('Film'))) {
      theme = 'playful';
    } else if (tags.some(t => t.includes('Hiking') || t.includes('Running') || t.includes('Travel'))) {
      theme = 'adventure';
    }

    const stops = this.itineraryTemplates[theme];
    return {
      theme,
      matchName: match.name || 'Adventurer',
      matchPhoto: match.photo || 'img/alex.png',
      stops,
      estimatedBudget: "$$ (Affordable & Cozy)",
      vibe: "Relaxed · Playful · Memory-Making"
    };
  }

  // Opens the Smart Date Itinerary Modal
  openItineraryModal(match) {
    AudioFX.playChallenge();
    const itinerary = this.generateDateItinerary(match);

    const existing = document.getElementById('date-itinerary-modal');
    if (existing) existing.remove();

    const modal = document.createElement('div');
    modal.id = 'date-itinerary-modal';
    modal.className = 'custom-module-modal active';
    modal.innerHTML = `
      <div class="modal-card date-itinerary-card">
        <div class="modal-header">
          <div class="itinerary-header-meta">
            <span class="itinerary-badge"><i class="fas fa-sparkles"></i> SparkQuest Itinerary</span>
            <h3>Quest With ${itinerary.matchName}</h3>
          </div>
          <button class="close-modal-btn" onclick="document.getElementById('date-itinerary-modal').remove()">&times;</button>
        </div>
        <div class="itinerary-body">
          <div class="itinerary-vibe-banner">
            <div class="vibe-item"><i class="fas fa-compass" style="color:var(--cyan);"></i> <span>${itinerary.vibe}</span></div>
            <div class="vibe-item"><i class="fas fa-coins" style="color:var(--gold);"></i> <span>${itinerary.estimatedBudget}</span></div>
          </div>

          <div class="itinerary-stops-timeline">
            ${itinerary.stops.map((stop, idx) => `
              <div class="timeline-stop-item">
                <div class="stop-badge-icon">${stop.icon}</div>
                <div class="stop-content">
                  <div class="stop-time-tag">${stop.time} · Stop ${idx + 1}</div>
                  <h4 class="stop-title">${stop.title}</h4>
                  <div class="stop-loc"><i class="fas fa-location-dot"></i> ${stop.loc}</div>
                  <p class="stop-desc">${stop.desc}</p>
                </div>
              </div>
            `).join('')}
          </div>

          <div class="itinerary-actions">
            <button class="action-btn-secondary" onclick="window.SparkyAI.dropMapPin('${itinerary.matchName}', '${itinerary.stops[0].loc}')">
              <i class="fas fa-map-pin"></i> View on Map
            </button>
            <button class="action-btn-primary" onclick="window.SparkyAI.sendItineraryToChat('${itinerary.matchName}')">
              <i class="fas fa-paper-plane"></i> Send to Chat
            </button>
          </div>
        </div>
      </div>
    `;
    document.body.appendChild(modal);
  }

  sendItineraryToChat(matchName) {
    AudioFX.playLevelUp();
    const modal = document.getElementById('date-itinerary-modal');
    if (modal) modal.remove();

    const inviteMsg = `✨ I asked Sparky to plan our first quest! Here's the 3-stop itinerary: ☕ Artisan Coffee & Matcha → 🎨 Indie Gallery Stroll → 🍸 Rooftop Sunset Drinks. What do you think?`;

    if (typeof window.sendMessage === 'function') {
      window.sendMessage(inviteMsg);
    } else {
      const chatInput = document.getElementById('chat-input');
      if (chatInput) {
        chatInput.value = inviteMsg;
      }
    }
  }

  dropMapPin(matchName, locName) {
    AudioFX.playPop();
    const modal = document.getElementById('date-itinerary-modal');
    if (modal) modal.remove();

    // Navigate to Map View
    if (typeof window.switchView === 'function') {
      window.switchView('map');
    }
    if (window.MapService && window.MapService.map) {
      const center = window.MapService.map.getCenter();
      window.MapService.addCustomMarker(center.lat + 0.003, center.lng + 0.003, `🌟 Date Quest: ${locName} with ${matchName}`, 'quest');
    }
    alert(`📍 Quest destination added to map: ${locName}`);
  }
}

const SparkyAI = new SparkyAIEngine();
export default SparkyAI;
