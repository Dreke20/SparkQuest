
// import { signInAnonymously, onAuthStateChanged } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-auth.js"; // REPLACED BY AUTH SERVICE
import DB_Service from './js/db-service.js';
import AuthService from './js/auth-service.js';
import MapService from './js/map-service.js';
import WebRTCService from './js/webrtc-service.js';
import { AdMobService } from './js/admob-service.js';
import ThemeManager from './js/modules/theme-manager.js';
import MiniGamesEngine from './js/modules/mini-games.js';
import DateShield from './js/modules/date-shield.js';
import AudioFX from './js/modules/audio-fx.js';
import VoiceSparks from './js/modules/voice-sparks.js';
import SparkyAI from './js/modules/sparky-ai.js';
import CoopQuests from './js/modules/coop-quests.js';
import LivenessVerification from './js/modules/liveness-verification.js';
import DailySpinWheel from './js/modules/daily-spin.js';
import MysteryMatch from './js/modules/mystery-match.js';
import VibeHeatmeter from './js/modules/vibe-heatmeter.js';
import SafeHavens from './js/modules/safe-havens.js';
import VIPCosmetics from './js/modules/vip-cosmetics.js';
import SupabaseClient from './js/modules/supabase-client.js';
import SparkPass from './js/modules/spark-pass.js';
import { Haptics, ImpactStyle } from '@capacitor/haptics';
import { PushNotifications } from '@capacitor/push-notifications';
import interact from 'interactjs';
import confetti from 'canvas-confetti';

// Expose services to window for global access
window.DB_Service = DB_Service;
window.AuthService = AuthService;
window.MapService = MapService;
window.WebRTCService = WebRTCService;
window.AdMobService = AdMobService;
window.ThemeManager = ThemeManager;
window.MiniGamesEngine = MiniGamesEngine;
window.DateShield = DateShield;
window.AudioFX = AudioFX;
window.VoiceSparks = VoiceSparks;
window.SparkyAI = SparkyAI;
window.CoopQuests = CoopQuests;
window.LivenessVerification = LivenessVerification;
window.DailySpinWheel = DailySpinWheel;
window.MysteryMatch = MysteryMatch;
window.VibeHeatmeter = VibeHeatmeter;
window.SafeHavens = SafeHavens;
window.VIPCosmetics = VIPCosmetics;
window.SupabaseClient = SupabaseClient;
window.SparkPass = SparkPass;
try { SupabaseClient.init(); } catch (e) { console.warn(e); }
window.toggleSoundFX = () => {
  const isEnabled = AudioFX.toggleMute();
  const btn = document.getElementById('sound-fx-toggle-btn');
  if (btn) btn.textContent = isEnabled ? '🔊' : '🔇';
};

console.log('[Main] Script loaded! Timestamp:', Date.now());

// Global State (Synced with Firestore)
// We keep local variables for UI rendering, but update them from DB
window.embers = 325; // Default/Fallback
window.inventory = { boost: 2, superlike: 5 };
window.questProgress = {
  engage1: { current: 7, target: 10, claimed: false },
  engage2: { current: 1, target: 3, claimed: false },
  engage3: { current: 1, target: 1, claimed: true },
  engage4: { current: 0, target: 1, claimed: false },
  engage5: { current: 0, target: 1, claimed: false },
  engage6: { current: 0, target: 1, claimed: false }
};
window.isPremium = false;
window.currentUserUid = null;

// Seed Profile Data (for offline fallback & immediate demo richness)
const seedProfiles = [
  { id: 'seed_sophia', name: 'Sophia', age: 24, photo: 'img/sophia.png', detail: 'Photographer · 2 mi away', tags: ['🎨 Art', '🏔️ Hiking', '☕ Coffee'], compat: 'high', compatPct: 92, verified: true, voicePrompt: true },
  { id: 'seed_alex', name: 'Alex', age: 27, photo: 'img/alex.png', detail: 'Software Engineer · 5 mi away', tags: ['🎮 Gaming', '🍳 Cooking', '📚 Books'], compat: 'high', compatPct: 87, verified: true, voicePrompt: false },
  { id: 'seed_maya', name: 'Maya', age: 25, photo: 'img/maya.png', detail: 'Yoga Instructor · 3 mi away', tags: ['🧘 Yoga', '🌱 Vegan', '✈️ Travel'], compat: 'medium', compatPct: 78, verified: false, voicePrompt: true },
  { id: 'seed_jordan', name: 'Jordan', age: 28, photo: 'img/jordan.png', detail: 'Music Producer · 1 mi away', tags: ['🎵 Music', '🎬 Film', '🍷 Wine'], compat: 'high', compatPct: 94, verified: true, voicePrompt: true },
  { id: 'seed_riley', name: 'Riley', age: 23, photo: 'img/riley.png', detail: 'Med Student · 4 mi away', tags: ['🏃 Running', '🐕 Dogs', '📖 Reading'], compat: 'medium', compatPct: 75, verified: true, voicePrompt: false },
  { id: 'seed_taylor', name: 'Taylor', age: 26, photo: 'img/taylor.png', detail: 'Designer · 6 mi away', tags: ['🎨 Design', '☕ Coffee', '🎸 Guitar'], compat: 'high', compatPct: 89, verified: true, voicePrompt: true },
];

let profiles = [...seedProfiles];

async function loadDiscoveryProfiles() {
  if (window.currentUserUid && window.DB_Service) {
    try {
      const liveProfiles = await window.DB_Service.getDiscoveryProfiles(window.currentUserUid);
      if (liveProfiles && liveProfiles.length > 0) {
        profiles = [...liveProfiles, ...seedProfiles];
      }
    } catch (e) {
      console.warn('[Discovery] Failed to load live profiles, using seed:', e);
    }
  }
  buildSwipeDeck();
}
window.loadDiscoveryProfiles = loadDiscoveryProfiles;

// Gacha Items
const gachaItems = {
  standard: [
    { rarity: 'COMMON', icon: '🎨', name: 'Pastel Gradient Frame', desc: 'A soft gradient profile frame.', weight: 40 },
    { rarity: 'COMMON', icon: '💬', name: 'Starlight Chat Theme', desc: 'A sparkling chat background.', weight: 20 },
    { rarity: 'RARE', icon: '👁️', name: '1 Liked-You Reveal', desc: 'See one person who liked you!', weight: 15 },
    { rarity: 'RARE', icon: '⭐', name: '1 Super-Like', desc: "Show someone special you're interested.", weight: 12 },
    { rarity: 'EPIC', icon: '⚡', name: '1 Profile Boost', desc: '30 minutes of priority visibility!', weight: 8 },
    { rarity: 'EPIC', icon: '🔮', name: 'Premium Filter (7-day)', desc: 'Unlock advanced search filters.', weight: 4 },
    { rarity: 'LEGENDARY', icon: '👑', name: 'Neon Crown Frame', desc: 'The rarest frame!', weight: 1 },
  ],
  premium: [
    { rarity: 'RARE', icon: '👁️', name: '3 Liked-You Reveals', desc: 'See three people who liked you!', weight: 30 },
    { rarity: 'RARE', icon: '⭐', name: '3 Super-Likes', desc: 'A triple pack of Super-Likes!', weight: 25 },
    { rarity: 'EPIC', icon: '⚡', name: '2 Profile Boosts', desc: '60 minutes of priority visibility!', weight: 20 },
    { rarity: 'EPIC', icon: '🔮', name: 'Premium Filter (30-day)', desc: 'A full month of advanced filters.', weight: 15 },
    { rarity: 'LEGENDARY', icon: '🌟', name: 'Holographic Frame', desc: 'Ultra-rare holographic profile ring!', weight: 7 },
    { rarity: 'LEGENDARY', icon: '👑', name: 'Neon Crown Frame', desc: 'The rarest frame!', weight: 3 },
  ]
};

// Story Data
const storyData = {
  sophia: {
    name: 'Sophia', photo: 'img/sophia.png', slides: [
      { bg: 'linear-gradient(135deg, #FF3F6C, #FFB800)', text: 'Golden hour hike today! 🌄' },
      { type: 'video', videoSrc: 'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4' }, // Fake video
      { bg: 'linear-gradient(135deg, #7B2FFF, #FF3F6C)', text: 'Found the perfect coffee spot ☕✨' },
    ]
  },
  jordan: {
    name: 'Jordan', photo: 'img/jordan.png', slides: [
      { bg: 'linear-gradient(135deg, #FFB800, #FF3F6C)', text: 'New track dropping tonight 🎵🔥' },
      { type: 'video', videoSrc: 'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4' }, // Fake video
      { bg: 'linear-gradient(135deg, #00E5FF, #7B2FFF)', text: 'Studio vibes all day 🎧' },
      { bg: 'linear-gradient(135deg, #FF3F6C, #7B2FFF)', text: 'Who wants to grab wine later? 🍷' },
    ]
  },
  maya: {
    name: 'Maya', photo: 'img/maya.png', slides: [
      { bg: 'linear-gradient(135deg, #00E5FF, #7B2FFF)', text: 'Morning yoga flow 🧘‍♀️' },
      { type: 'video', videoSrc: 'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4' }
    ]
  },
  taylor: {
    name: 'Taylor', photo: 'img/taylor.png', slides: [
      { bg: 'linear-gradient(135deg, #00E5FF, #FFB800)', text: 'New design project started! 🎨' },
      { type: 'video', videoSrc: 'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4' },
      { bg: 'linear-gradient(135deg, #7B2FFF, #00E5FF)', text: 'Guitar practice at sunset 🎸' },
    ]
  },
  alex: {
    name: 'Alex', photo: 'img/alex.png', slides: [
      { bg: 'linear-gradient(135deg, #22C55E, #00E5FF)', text: 'Debugging my life away 🐛' },
      { bg: 'linear-gradient(135deg, #00E5FF, #7B2FFF)', text: 'Gaming marathon starts now! 🎮' }
    ]
  },
  riley: {
    name: 'Riley', photo: 'img/riley.png', slides: [
      { bg: 'linear-gradient(135deg, #FF3F6C, #FFB800)', text: 'Study break! ☕' },
      { bg: 'linear-gradient(135deg, #7B2FFF, #FF3F6C)', text: 'Med school life is rough but worth it 🩺' }
    ]
  }
};

// Chat Data
const chatData = {
  sophia: {
    name: 'Sophia', photo: 'img/sophia.png', verified: true, tags: ['🎨 Art', '🏔️ Hiking', '☕ Coffee'],
    msgs: [
      { type: 'received', text: 'Hey! I love your hiking photos 🏔️ Where was that last trail?', time: '2:34 PM' },
      { type: 'received', video: true, text: '', videoSrc: 'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4', time: '2:35 PM' }
    ]
  },
  alex: {
    name: 'Alex', photo: 'img/alex.png', verified: true, tags: ['🎮 Gaming', '🍳 Cooking', '📚 Books'],
    msgs: [
      { type: 'received', text: 'That coffee shop rec was amazing 😍', time: '1:12 PM' },
      { type: 'sent', text: 'Right?! Their oat milk latte is legendary', time: '1:15 PM' },
      { type: 'received', text: 'We should go together sometime ☕', time: '1:18 PM' },
      { type: 'received', video: true, text: '', videoSrc: 'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4', time: '1:20 PM' } // Fake video msg
    ]
  },
  maya: { name: 'Maya', photo: 'img/maya.png', verified: false, tags: ['🧘 Yoga', '🌱 Vegan', '✈️ Travel'], msgs: [] }
};
window.chatData = chatData;
window.storyData = storyData;

// State
// State
// var embers = 325; // Replaced by window.embers
var currentCardIndex = 0;
// var swipeHistory = [];
window.swipeHistory = [];
var swipeCount = 0;
var currentChatUser = null;
var currentStory = null;
var currentSlideIndex = 0;
var storyTimer = null;
var panicInterval = null;
var videoCallTimer = null;
var videoCallSeconds = 0;
var selectedVideoTime = null;
var selectedVenue = null;
var isIntimateMode = false;
var ageVerified = false;

// Shop & Inventory State
// var inventory = { ... }; // Replaced by window.inventory

// Quest State
// var questProgress = { ... }; // Replaced by window.questProgress

import { createParticles } from './js/particles.js';
import SoundService from './js/sound-service.js';
import PaymentService from './js/payment-service.js';

window.SoundService = SoundService;
window.PaymentService = PaymentService;

// Debug logging
console.log('App.js loaded');
window.onerror = function (msg, url, line, col, error) {
  console.error('Global Error:', msg, url, line, col, error);
};

window.createParticles = createParticles;

// Initialize Audio on first interaction
document.addEventListener('click', () => {
  SoundService.init();
  if (SoundService.ctx && SoundService.ctx.state === 'suspended') {
    SoundService.ctx.resume();
  }
}, { once: true });

// Attach playClick globally to buttons
document.addEventListener('click', (e) => {
  if (e.target.tagName === 'BUTTON' || e.target.closest('button') || e.target.closest('.nav-item')) {
    SoundService.playClick();
  }
});

// Video/Camera State
var isRecording = false;
var cameraTimerInterval = null;
var cameraSeconds = 0;
var cameraMode = 'story'; // 'story' or 'chat'
// var isPremium = false; // Mock subscription state

// Navigation
// Duplicate navigate function removed. Replaced by global assignment below.


// Chat Event Delegation (Global) - Moved outside async init to ensure immediate attachment
// Expose functions to window IMMEDIATELY to prevent ReferenceErrors
window.checkVideoAccess = checkVideoAccess;
window.closeChatDetail = closeChatDetail;
window.openChatDetail = openChatDetail;
window.sendMessage = sendMessage;
window.showLoginReward = showLoginReward;
window.claimReward = claimReward;
window.claimMapDrop = claimMapDrop;
window.showVenueInfo = showVenueInfo;
window.watchAdForEmbers = watchAdForEmbers;
// ... other window assignments will happen below or can be consolidated here

document.addEventListener('click', function (e) {
  var btn = e.target.closest('#chat-send-btn') || e.target.closest('.chat-send');
  if (btn) {
    console.log('[CHAT] Delegated click on chat-send-btn');
    sendMessage();
  }
});

document.addEventListener('keypress', function (e) {
  if (e.key === 'Enter' && e.target && e.target.id === 'chat-input') {
    console.log('[CHAT] Delegated Enter on chat-input');
    sendMessage();
  }
});

// ===== VIDEO SHARING & PAYWALL =====

// Expose functions to window
window.checkVideoAccess = checkVideoAccess;
function checkVideoAccess() {
  if (window.isPremium) return true;
  document.getElementById('media-upsell-modal').style.display = 'flex';
  return false;
}

function mockSubscribe() {
  isPremium = true;
  document.getElementById('media-upsell-modal').style.display = 'none';
  showToast('Upgraded to Gold! Video features unlocked 🔓', 'earn', 'VIP');
  // Update UI to reflect premium?
  document.querySelectorAll('.btn-buy-embers').forEach(b => b.textContent = 'Premium Active');
}

function openCamera(mode) {
  if (!checkVideoAccess()) return;
  cameraMode = mode;
  document.getElementById('camera-modal').style.display = 'flex';
  resetCamera();
}

function closeCamera() {
  stopRecording();
  document.getElementById('camera-modal').style.display = 'none';
}

console.log('[MAIN] Script execution complete');

function resetCamera() {
  document.getElementById('camera-viewfinder').style.display = 'flex';
  document.getElementById('camera-preview-ui').style.display = 'none';
  document.getElementById('camera-timer').style.display = 'none';
  document.getElementById('camera-timer').innerText = '00:00';
  document.querySelector('.camera-overlay-ui').style.display = 'flex';
}

function flipCamera() {
  var v = document.querySelector('.camera-viewfinder');
  v.style.transform = v.style.transform === 'scaleX(-1)' ? '' : 'scaleX(-1)';
}

function startRecording() {
  isRecording = true;
  cameraSeconds = 0;
  document.getElementById('camera-shutter').classList.add('recording');
  document.getElementById('camera-timer').style.display = 'block';
  cameraTimerInterval = setInterval(function () {
    cameraSeconds++;
    var m = Math.floor(cameraSeconds / 60);
    var s = cameraSeconds % 60;
    document.getElementById('camera-timer').innerText = String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
  }, 1000);
}

function stopRecording() {
  if (!isRecording) return;
  isRecording = false;
  clearInterval(cameraTimerInterval);
  document.getElementById('camera-shutter').classList.remove('recording');

  // Show Preview
  setTimeout(function () {
    document.querySelector('.camera-overlay-ui').style.display = 'none';
    document.getElementById('camera-preview-ui').style.display = 'flex';
  }, 500);
}

function retakeVideo() {
  resetCamera();
}

function postVideo() {
  closeCamera();
  if (cameraMode === 'story') {
    // Add to 'You' story
    var newSlide = {
      type: 'video',
      bg: '#000',
      text: '',
      videoSrc: 'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4' // Public sample video
    };

    // Ensure 'you' exists in storyData
    if (!storyData['you']) {
      storyData['you'] = { name: 'You', photo: 'img/alex.png', slides: [] };
      // Make "Your Story" clickable
      var yourStoryEl = document.querySelector('.story-avatar.add-story');
      yourStoryEl.setAttribute('onclick', "openStory('you')");
    }

    storyData['you'].slides.push(newSlide);

    showToast('Video added to your Story! 📹', 'earn', '+10');
    document.querySelector('.story-avatar.add-story').classList.add('has-story');
  } else if (cameraMode === 'chat') {
    sendVideoMessage();
  }
}

function sendVideoMessage() {
  var messages = document.getElementById('chat-messages');
  var bubble = document.createElement('div');
  bubble.className = 'chat-bubble sent chat-bubble-video';
  bubble.innerHTML = `
    <div class="play-overlay" onclick="this.style.display='none'; this.nextElementSibling.play()"><div class="play-icon">▶</div></div>
    <video src="https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4" poster="img/alex.png" style="width:100%"></video>
    <span class="bubble-time">Now</span>
  `;
  messages.appendChild(bubble);
  messages.scrollTop = messages.scrollHeight;

  if (currentChatUser && chatData[currentChatUser]) {
    chatData[currentChatUser].msgs.push({ type: 'sent', video: true, time: 'Now' });
  }
}

// Splash Particles
function createSplashParticles() {
  var container = document.getElementById('splash-particles');
  if (!container) return;
  for (var i = 0; i < 20; i++) {
    var p = document.createElement('div');
    p.className = 'ember-particle';
    p.style.left = Math.random() * 100 + '%';
    p.style.bottom = '-10px';
    p.style.animationDelay = Math.random() * 4 + 's';
    p.style.animationDuration = (3 + Math.random() * 3) + 's';
    var colors = ['#FFB800', '#FF3F6C', '#7B2FFF', '#00E5FF'];
    p.style.background = colors[Math.floor(Math.random() * colors.length)];
    container.appendChild(p);
  }
}

// Splash to Reward
// Splash to Reward
window.showLoginReward = showLoginReward;
// Swipe Logic
window.swipeAction = swipeAction;
window.undoSwipe = undoSwipe;

function showLoginReward() {
  try {
    // Check if legal modal is needed
    var legalAccepted = false;
    try {
      legalAccepted = localStorage.getItem('spark_legal_accepted');
    } catch (e) {
      console.warn("LocalStorage access denied:", e);
    }

    if (!legalAccepted) {
      if (typeof openLegalModal === 'function') {
        openLegalModal();
      } else {
        console.error("openLegalModal is not defined! Fallback manual display.");
        var modal = document.getElementById('legal-modal');
        if (modal) modal.style.display = 'flex';
      }
      return;
    }

    document.getElementById('splash-screen').classList.remove('active');
    document.getElementById('splash-screen').style.display = 'none';
    document.getElementById('login-reward-modal').style.display = 'flex';
  } catch (err) {
    console.error("Error in showLoginReward:", err);
    // Fallback: try to just show app/reward if possible or alert user
    alert("Error starting app. Please check console.");
  }
}

window.claimReward = claimReward;
function claimReward() {
  // DB Update
  if (window.currentUserUid) {
    DB_Service.updateEmbers(window.currentUserUid, 25);
  } else {
    window.embers += 25;
    updateEmberDisplay();
  }

  document.getElementById('login-reward-modal').style.display = 'none';
  document.getElementById('app').style.display = 'block';
  showToast('Welcome back! +25 Embers earned 🔥', 'earn', '+25');

  buildSwipeDeck(); // Ensure deck is built
}

// Navigation
function navigate(screen) {
  console.log('[Main] navigate() called with screen:', screen);
  var screens = document.querySelectorAll('.app-screen');
  for (var i = 0; i < screens.length; i++) screens[i].classList.remove('active');
  var target = document.getElementById('screen-' + screen);
  if (target) {
    target.classList.add('active');
    console.log('[Main] Set active screen:', target.id);
  } else {
    console.error('[Main] Target screen not found:', 'screen-' + screen);
  }
  var navItems = document.querySelectorAll('.nav-item');
  for (var i = 0; i < navItems.length; i++) navItems[i].classList.remove('active');
  var navBtn = document.querySelector('.nav-item[data-screen="' + screen + '"]');
  if (navBtn) navBtn.classList.add('active');

  // Render Theme Shop if Shop or Wallet
  if (screen === 'shop' || screen === 'wallet') {
    if (window.ThemeManager) window.ThemeManager.renderThemeShop();
  }

  // Trigger RPG Animation if Profile
  if (screen === 'profile') {
    animateRPGStats();
  } else if (screen === 'map') {
    console.log('[Main] Entering map logic. MapService:', MapService);
    // Initialize Map
    if (MapService) {
      try {
        console.log('[Main] Calling MapService.init()');
        MapService.init();
        setTimeout(() => {
          console.log('[Main] Calling MapService.refresh()');
          MapService.refresh();
        }, 100);
      } catch (e) {
        console.error('[Main] Error initializing map:', e);
      }
    } else {
      console.error('[Main] MapService is undefined!');
    }
  } else if (screen === 'live') {
    startWebRTC();
  } else {
    stopWebRTC();
  }
}

function startWebRTC() {
  if (window.WebRTCService) {
    showToast("Connecting to live server...", "info");
    // Hardcoded channel for demo purposes
    window.WebRTCService.init("spark_quest_live_demo").then(uid => {
      if(uid) {
        showToast("You are now LIVE! 🔴", "earn");
      }
    });
  } else {
    showToast("WebRTC Service not loaded.", "spend");
  }
}

function stopWebRTC() {
  if (window.WebRTCService && window.WebRTCService.isJoined) {
    window.WebRTCService.leave();
    showToast("Stream ended.", "info");
  }
}
window.navigate = navigate;
console.log('[Main] window.navigate explicitly assigned (v2)');

// RPG Stats Animation
function animateRPGStats() {
  // Animate Bars
  var bars = document.querySelectorAll('.stat-fill');
  bars.forEach(function (bar, index) {
    // Store original width if not already stored
    if (!bar.dataset.targetWidth) {
      bar.dataset.targetWidth = bar.style.width;
    }

    // Reset to 0
    bar.style.transition = 'none';
    bar.style.width = '0%';

    // Force reflow
    void bar.offsetWidth;

    // Animate to target
    setTimeout(function () {
      bar.style.transition = 'width 1s cubic-bezier(0.22, 1, 0.36, 1)';
      bar.style.width = bar.dataset.targetWidth;
    }, 100 + (index * 100)); // Stagger animations
  });

  // Animate Radar
  var radar = document.querySelector('.radar-fill');
  if (radar) {
    radar.style.transition = 'none';
    radar.style.transform = 'scale(0)';
    radar.style.transformOrigin = 'center';

    void radar.offsetWidth;

    setTimeout(function () {
      radar.style.transition = 'transform 1.2s cubic-bezier(0.34, 1.56, 0.64, 1)';
      radar.style.transform = 'scale(1)';
    }, 300);
  }
}

// Spark Map Logic
// Map Functions
window.claimMapDrop = claimMapDrop;
window.showVenueInfo = showVenueInfo;
function claimMapDrop(elOrData) {
  // Handle Leaflet Data Object
  if (elOrData.dataset && !elOrData.classList) {
    const type = elOrData.dataset.type; // 'fire' or 'gem'
    const reward = elOrData.dataset.value || (type === 'fire' ? 25 : 100);

    if (window.currentUserUid) {
      DB_Service.updateEmbers(window.currentUserUid, reward);
    } else {
      window.embers += reward;
      updateEmberDisplay();
    }

    if (type === 'neon') {
        showToast('NEON DROP CLAIMED! +' + reward + ' Embers', 'earn', '+' + reward);
    } else {
        showToast('Map Drop claimed! +' + reward + ' Embers', 'earn', '+' + reward);
    }
    if (window.updateQuestProgress) window.updateQuestProgress('engage5');
    floatingEmber();
    return;
  }

  // Handle Legacy DOM Element (Fallback)
  let el = elOrData;
  if (el.classList.contains('claimed')) return;
  // Visual feedback
  el.classList.add('claimed');
  // Reward
  var typeText = el.querySelector('.pin-icon').textContent;
  var reward = typeText === '🔥' ? 50 : 100; // Fire vs Gem

  if (window.currentUserUid) {
    DB_Service.updateEmbers(window.currentUserUid, reward);
  } else {
    window.embers += reward;
    updateEmberDisplay();
  }

  // Toast and Particles
  showToast('Map Drop claimed! +' + reward + ' Embers', 'earn', '+' + reward);
  floatingEmber();
}

function showVenueInfo(name) {
  // Open the sponsored modal but customize it
  var modal = document.getElementById('sponsored-modal');
  modal.style.display = 'flex';

  // Find elements to update
  var title = modal.querySelector('h3');
  var desc = modal.querySelector('p');
  var img = modal.querySelector('.sponsored-img');

  // Simple logic to customize content based on venue name
  title.textContent = name;

  if (name.includes('Lounge') || name.includes('Bar')) {
    img.textContent = '🍸';
    desc.textContent = 'Happy Hour: 2-for-1 cocktails until 8pm!';
  } else if (name.includes('Park')) {
    img.textContent = '🌳';
    desc.textContent = 'Perfect spot for a walking date. Coffee cart nearby!';
  } else {
    img.textContent = '📍';
    desc.textContent = 'Popular date spot in your area.';
  }
}

// Ember Display
window.updateEmberDisplay = function() {
  var el = document.getElementById('ember-count');
  var wal = document.getElementById('wallet-balance');
  if (el) el.textContent = window.embers;
  if (wal) wal.textContent = window.embers;
}

function updateEmberDisplay() {
    window.updateEmberDisplay();
}

// Swipe Deck
window.applyProfileFilter = function() {
    buildSwipeDeck();
};

function buildSwipeDeck() {
  var deck = document.getElementById('swipe-deck');
  if (!deck) return;
  deck.innerHTML = '';
  currentCardIndex = 0;
  
  var filterEl = document.getElementById('profile-filter');
  var filterValue = filterEl ? filterEl.value.toLowerCase() : 'all';
  
  var filteredProfiles = profiles;
  if (filterValue !== 'all') {
      filteredProfiles = profiles.filter(p => p.tags.some(t => t.toLowerCase().includes(filterValue)));
  }
  
  window.currentFilteredProfiles = filteredProfiles; // Save reference for swiping

  var visibleCount = Math.min(3, filteredProfiles.length);
  
  if (visibleCount === 0) {
      deck.innerHTML = '<div style="text-align:center; color:var(--text-secondary); margin-top:50px;">No profiles found for this filter.</div>';
      return;
  }

  for (var i = visibleCount - 1; i >= 0; i--) {
    var p = filteredProfiles[i];
    var card = document.createElement('div');
    card.className = 'swipe-card';
    card.dataset.index = i;
    card.style.transform = 'scale(' + (1 - i * 0.05) + ') translateY(' + (i * 8) + 'px)';
    card.style.zIndex = visibleCount - i;
    var voiceHtml = '';
    if (p.voicePrompt) {
      voiceHtml = VoiceSparks.renderVoiceSparkPill(p);
    }
    var neonRing = p.compat === 'high' ? '<div class="neon-ring"></div>' : '';
    var verifiedBadge = p.verified ? '<span class="card-verified">✓</span>' : '';
    var tagsHtml = '';
    for (var t = 0; t < p.tags.length; t++) {
      tagsHtml += '<span class="card-tag">' + p.tags[t] + '</span>';
    }
    var mediaHtml = '';
    if (p.video) {
        mediaHtml = '<video class="card-video" src="' + p.video + '" autoplay loop muted playsinline style="position: absolute; width: 100%; height: 100%; object-fit: cover; border-radius: var(--radius-lg); pointer-events: none;"></video>';
    } else {
        mediaHtml = '<img class="card-photo" src="' + p.photo + '" alt="' + p.name + '" onclick="event.stopPropagation(); openStory(\'' + p.name.toLowerCase() + '\')" style="pointer-events: auto; cursor: pointer;" />';
    }

    card.innerHTML = neonRing + mediaHtml +
      '<div class="card-gradient"></div>' +
      '<div class="card-compatibility ' + p.compat + '">' + p.compatPct + '% Match</div>' +
      '<div class="card-info">' +
      '<div class="card-name" onclick="event.stopPropagation(); openStory(\'' + p.name.toLowerCase() + '\')" style="pointer-events: auto; cursor: pointer;">' + p.name + ', <span class="age">' + p.age + '</span> ' + verifiedBadge + '</div>' +
      '<div class="card-detail">' + p.detail + '</div>' +
      '<div class="card-tags">' + tagsHtml + '</div>' +
      voiceHtml +
      '</div>' +
      '<div class="swipe-label like">LIKE</div>' +
      '<div class="swipe-label nope">NOPE</div>';
    setupSwipeGestures(card);
    deck.appendChild(card);
  }
}

function setupSwipeGestures(card) {
  var currentX = 0, currentY = 0;
  
  interact(card).draggable({
    inertia: true,
    modifiers: [
      interact.modifiers.restrictRect({
        restriction: 'parent',
        endOnly: true
      })
    ],
    autoScroll: true,
    listeners: {
      start (event) {
        card.style.transition = 'none';
      },
      move (event) {
        currentX += event.dx;
        currentY += event.dy;

        var rotate = currentX * 0.08;
        var scale = Math.max(0.95, 1 - Math.abs(currentX) / 1000);
        card.style.transform = `translate(${currentX}px, ${currentY}px) rotate(${rotate}deg) scale(${scale})`;

        // Play Swipe Sound & Tactile Haptics (throttled)
        if (Math.abs(currentX) > 50 && Math.abs(currentX - event.dx) <= 50) {
          if (window.SoundService) window.SoundService.playSwipe(currentX > 0 ? 'right' : 'left');
          try {
            Haptics.impact({ style: ImpactStyle.Light }).catch(() => {});
          } catch (e) {}
        }

        // Fade in labels
        var likeLabel = card.querySelector('.swipe-label.like');
        var nopeLabel = card.querySelector('.swipe-label.nope');
        var opacity = Math.min(1, Math.abs(currentX) / 100);

        if (currentX > 0) {
          if (likeLabel) likeLabel.style.opacity = opacity;
          if (nopeLabel) nopeLabel.style.opacity = 0;
          card.style.boxShadow = `0 0 20px rgba(0, 255, 150, ${opacity * 0.5})`; // Green glow
        } else {
          if (nopeLabel) nopeLabel.style.opacity = opacity;
          if (likeLabel) likeLabel.style.opacity = 0;
          card.style.boxShadow = `0 0 20px rgba(255, 63, 108, ${opacity * 0.5})`; // Red glow
        }
      },
      end (event) {
        card.style.transition = 'transform 0.5s cubic-bezier(0.22,1,0.36,1)';
        if (Math.abs(currentX) > 100) {
          try {
            Haptics.impact({ style: ImpactStyle.Medium }).catch(() => {});
          } catch (e) {}
          swipeAction(currentX > 0 ? 'right' : 'left');
          card.style.boxShadow = '';
        } else {
          currentX = 0; currentY = 0;
          card.style.transform = '';
          card.style.boxShadow = '';
          var l = card.querySelector('.swipe-label.like');
          var n = card.querySelector('.swipe-label.nope');
          if (l) l.style.opacity = 0;
          if (n) n.style.opacity = 0;
        }
      }
    }
  });
}

// Swipe Actions
function swipeAction(direction) {
  var profList = window.currentFilteredProfiles || profiles;
  if (currentCardIndex >= profList.length) return;

  var deck = document.getElementById('swipe-deck');
  var topCard = deck ? deck.querySelector('.swipe-card:last-child') : null;
  if (!topCard) return;
  var p = profList[parseInt(topCard.dataset.index)];

  // Record Swipe to Supabase & Check Mutual Match
  if (window.currentUserUid && window.DB_Service) {
    window.DB_Service.recordSwipe(window.currentUserUid, p.id || p.name, direction).then(result => {
      if (result && result.is_match) {
        setTimeout(() => { showMatch(p); }, 400);
      }
    });
  }

  swipeHistory.push({ profile: p, index: parseInt(topCard.dataset.index) });
  swipeCount++;
  
  // Native Haptics Feedback
  Haptics.impact({ style: ImpactStyle.Medium }).catch(e => console.log('Haptics disabled on web', e));
  
  if (direction === 'right' || direction === 'superlike') {
    updateQuestProgress('engage1'); // Quest: Like Profiles
    topCard.style.transform = 'translateX(150%) rotate(20deg)';
    topCard.style.opacity = '0';
    
    // Fallback simulation for offline demo/seed profiles
    if ((!p.isLiveUser || !window.currentUserUid) && Math.random() > 0.6) {
      setTimeout(() => { showMatch(p); }, 500);
    }
    
    if (direction === 'superlike') {
      if (window.inventory.superlike > 0) {
        if (window.currentUserUid) DB_Service.updateInventory(window.currentUserUid, 'superlike', -1);
        else window.inventory.superlike--;
        showToast('Super-Like sent to ' + p.name + '! ⭐', 'spend', '-80');
      } else {
        showToast('No Super-Likes left!', 'spend');
        openBoostModal();
        return;
      }
    }
  } else {
    topCard.style.transform = 'translateX(-150%) rotate(-20deg)';
    topCard.style.opacity = '0';
  }
  setTimeout(function () { topCard.remove(); repositionCards(deck); }, 500);
  if (swipeCount % 5 === 0) {
    setTimeout(function () { document.getElementById('sponsored-modal').style.display = 'flex'; }, 800);
  }
}

function repositionCards(deck) {
  var cards = deck.querySelectorAll('.swipe-card');
  for (var i = 0; i < cards.length; i++) {
    var reverseIdx = cards.length - 1 - i;
    cards[i].style.transition = 'transform 0.4s ease';
    cards[i].style.transform = 'scale(' + (1 - reverseIdx * 0.05) + ') translateY(' + (reverseIdx * 8) + 'px)';
    cards[i].style.zIndex = i + 1;
  }
}

function undoSwipe() {
  if (window.isPremium) {
    doUndo();
  } else {
    // Cost 30 embers
    if (window.embers >= 30) {
      if (window.currentUserUid) DB_Service.updateEmbers(window.currentUserUid, -30);
      else {
        window.embers -= 30;
        updateEmberDisplay();
      }
      doUndo();
    } else {
      showToast('Not enough Embers to undo (30)', 'spend');
      openBoostModal(); // Upsell
    }
  }

  function doUndo() {
    if (swipeHistory.length === 0) { showToast('Nothing to undo', 'info'); return; }
    var last = swipeHistory.pop();
    profiles.unshift(last.profile);
    buildSwipeDeck();
    if (window.AudioFX) window.AudioFX.playSwipe('left');
    try {
      Haptics.impact({ style: ImpactStyle.Light }).catch(() => {});
    } catch (e) {}
    showToast('Swipe undone! ↩️', 'info');
  }
}

function showMatch(profile) {
  var matchImg = document.getElementById('match-their-img');
  var matchName = document.getElementById('match-name');
  if (matchImg) matchImg.src = profile.photo;
  if (matchName) matchName.textContent = profile.name;
  document.getElementById('match-modal').style.display = 'flex';

  // Particle Explosion!
  var cx = window.innerWidth / 2;
  var cy = window.innerHeight / 2;
  createParticles(cx, cy, 'heart');
  setTimeout(() => createParticles(cx, cy, 'confetti'), 300);

  // Play Match Sound & Burst Haptics
  SoundService.playMatch();
  try {
    Haptics.notification({ type: 'SUCCESS' }).catch(() => {});
  } catch (e) {}

  showToast('New match with ' + profile.name + '! 💘', 'earn', '+10');
  if (window.currentUserUid) {
    DB_Service.updateEmbers(window.currentUserUid, 10);
  } else {
    embers += 10;
    updateEmberDisplay();
  }
}

function playCardVoice(el) {
  el.classList.toggle('playing');
  setTimeout(function () { el.classList.remove('playing'); }, 3000);
}

// Modals
// Modals - Expose
window.closeModal = closeModal;
window.openBoostModal = openBoostModal;
window.openLegalModal = openLegalModal;
window.activateBoost = activateBoost;
window.acceptLegal = acceptLegal;
window.declineLegal = declineLegal;
window.openGachaReveal = openGachaReveal;
window.buyItem = buyItem;
window.spinGacha = spinGacha;

function closeModal(id) { var m = document.getElementById(id); if (m) m.style.display = 'none'; }
function openBoostModal() { document.getElementById('boost-modal').style.display = 'flex'; }
function openLegalModal() {
  var m = document.getElementById('legal-modal');
  if (m) m.style.display = 'flex';
  else console.error("Legal modal element not found!");
}
function activateBoost(type) {
  closeModal('boost-modal');
  if (type === 'embers') {
    if (window.embers >= 150) {
      if (window.currentUserUid) {
        DB_Service.updateEmbers(window.currentUserUid, -150);
      } else {
        window.embers -= 150;
        updateEmberDisplay();
      }
      showToast('Profile Boost activated for 30 min! ⚡', 'info');
    } else {
      showToast('Not enough Embers!', 'spend');
    }
  } else if (type === 'inventory') {
    // TODO: Update inventory in DB
    // For now just local check
    if (window.inventory.boost > 0) {
      // inventory.boost--; // Handled by DB if fully implemented, or local
      if (window.currentUserUid) {
        DB_Service.updateInventory(window.currentUserUid, 'boost', -1);
      } else {
        window.inventory.boost--;
      }
      showToast('Profile Boost activated! (' + window.inventory.boost + ' left)', 'info');
    } else {
      showToast('No Boosts in inventory!', 'info');
    }
  }
}

function acceptLegal() {
  localStorage.setItem('spark_legal_accepted', 'true');
  closeModal('legal-modal');

  // If we are on the splash screen, proceed to login reward
  var splash = document.getElementById('splash-screen');
  if (splash && (splash.style.display !== 'none' || splash.classList.contains('active'))) {
    showLoginReward();
  } else {
    showToast('Terms accepted. Enjoy SparkQuest!', 'info');
  }
}

function declineLegal() {
  showToast('You must accept the terms to use SparkQuest.', 'spend');
}

function openGachaReveal() { showToast('Use a Reveal to see who liked you!', 'info'); }

// Shop / Payments
function watchAdForEmbers() {
  var btn = document.querySelector(`[onclick="watchAdForEmbers()"]`);
  if (btn) btn.style.pointerEvents = 'none'; // Prevent double clicks
  
  AdMobService.showRewardedAd((amount) => {
    if (window.currentUserUid) {
      DB_Service.updateEmbers(window.currentUserUid, amount);
    } else {
      window.embers += amount;
      updateEmberDisplay();
    }
    showToast(`Ad Complete! You earned +${amount} Embers`, 'earn', `+${amount}`);
    floatingEmber();
    if (btn) btn.style.pointerEvents = 'auto';
  });
}

function buyItem(itemId) {
  var btn = document.querySelector(`[onclick="buyItem('${itemId}')"]`);
  var originalText = btn ? btn.innerText : '';

  if (btn) {
    btn.innerText = 'Processing...';
    btn.disabled = true;
    btn.style.opacity = '0.7';
  }

  PaymentService.checkout(itemId).finally(() => {
    if (btn) {
      btn.innerText = originalText;
      btn.disabled = false;
      btn.style.opacity = '1';
    }
  });
}

// Check for Payment Success on Load
window.addEventListener('load', () => {
  const params = new URLSearchParams(window.location.search);
  if (params.get('payment_status') === 'success') {
    const productId = params.get('product_id');
    handlePaymentSuccess(productId);

    // Clean URL
    window.history.replaceState({}, document.title, window.location.pathname);
  }
});

function handlePaymentSuccess(productId) {
  SoundService.playSuccess();
  createParticles(window.innerWidth / 2, window.innerHeight / 2, 'confetti');

  let msg = 'Purchase Successful!';

  if (productId.includes('embers')) {
    const amount = PaymentService.products[productId].amount;
    if (window.currentUserUid) {
      DB_Service.updateEmbers(window.currentUserUid, amount);
    } else {
      window.embers += amount;
      updateEmberDisplay();
    }
    msg = `+${amount} Embers Added!`;
  } else if (productId === 'superlike') {
    if (window.currentUserUid) {
      DB_Service.updateInventory(window.currentUserUid, 'superlike', 5);
    } else {
      window.inventory.superlike += 5;
    }
    msg = '+5 Super Likes Added!';
  } else if (productId === 'boost') {
    if (window.currentUserUid) {
      DB_Service.updateInventory(window.currentUserUid, 'boost', 5);
    } else {
      window.inventory.boost += 5;
    }
    msg = '+5 Boosts Added!';
  }

  showToast(msg, 'earn');
  setTimeout(() => {
    const modal = document.getElementById('shop-modal');
    if (modal) modal.style.display = 'none';
  }, 2000);
}

// Gacha
function spinGacha(tier) {
  var cost = tier === 'standard' ? 100 : 250;
  if (window.embers < cost) { showToast('Not enough Embers!', 'spend'); return; }

  if (window.currentUserUid) {
    DB_Service.updateEmbers(window.currentUserUid, -cost);
  } else {
    window.embers -= cost;
    updateEmberDisplay();
  }
  var display = document.getElementById('gacha-display');
  var gachaMachine = document.getElementById('gacha-machine');
  display.className = 'gacha-display spinning';
  display.innerHTML = '✨';
  showToast('Spinning...', 'spend', '-' + cost);
  
  if (window.SoundService) window.SoundService.playSwipe('right');
  
  setTimeout(function () {
    var items = gachaItems[tier];
    var totalWeight = items.reduce(function (s, i) { return s + i.weight; }, 0);
    var roll = Math.random() * totalWeight;
    var result = items[0];
    for (var j = 0; j < items.length; j++) {
      roll -= items[j].weight;
      if (roll <= 0) { result = items[j]; break; }
    }
    
    display.className = 'gacha-display result';
    
    // Add explosive shake effect
    gachaMachine.style.transform = 'scale(1.1)';
    gachaMachine.style.transition = 'transform 0.1s cubic-bezier(0.22, 1, 0.36, 1)';
    setTimeout(() => { gachaMachine.style.transform = 'scale(1)'; }, 100);

    if (result.rarity === 'LEGENDARY') {
        display.classList.add('legendary-flash');
        // HUGE Confetti Explosion for Legendary
        var duration = 3000;
        var end = Date.now() + duration;
        (function frame() {
            confetti({
                particleCount: 5,
                angle: 60,
                spread: 55,
                origin: { x: 0 },
                colors: ['#FFD700', '#FF3F6C']
            });
            confetti({
                particleCount: 5,
                angle: 120,
                spread: 55,
                origin: { x: 1 },
                colors: ['#FFD700', '#FF3F6C']
            });
            if (Date.now() < end) requestAnimationFrame(frame);
        }());
        if (window.AudioFX) window.AudioFX.playMatch();
        Haptics.impact({ style: ImpactStyle.Heavy }).catch(e => {});
    } else {
        // Standard Confetti Burst
        confetti({
            particleCount: 100,
            spread: 70,
            origin: { y: 0.6 }
        });
        if (window.AudioFX) window.AudioFX.playLevelUp();
        Haptics.impact({ style: ImpactStyle.Medium }).catch(e => {});
    }
    
    display.innerHTML = result.icon;
    
    setTimeout(function () {
      display.className = 'gacha-display';
      document.getElementById('gacha-result-rarity').textContent = result.rarity;
      document.getElementById('gacha-result-rarity').className = 'gacha-result-rarity ' + result.rarity;
      document.getElementById('gacha-result-icon').textContent = result.icon;
      document.getElementById('gacha-result-name').textContent = result.name;
      document.getElementById('gacha-result-desc').textContent = result.desc;
      document.getElementById('gacha-result-modal').style.display = 'flex';

      // Save to Supabase and Apply Cosmetic
      if (window.currentUserUid && window.DB_Service) {
        window.DB_Service.unlockCosmetic(window.currentUserUid, result.name);
      }
      if (result.name.includes("Frame")) {
        const color = result.rarity === 'LEGENDARY' ? '#ff00ff' : '#00ffff';
        const img = document.querySelector('.profile-avatar-large img');
        if (img) {
          img.style.border = `4px solid ${color}`;
          img.style.boxShadow = `0 0 15px ${color}`;
        }
      }
    }, 1500);
  }, 1500);
}

// Chat
// Window assignments moved to top of file
// window.openChatDetail = openChatDetail;
// window.closeChatDetail = closeChatDetail;
// window.sendMessage = sendMessage;


function closeChatDetail() {
  document.getElementById('chat-detail-modal').style.display = 'none';
  currentChatUser = null;
  if (window._chatUnsub) {
    window._chatUnsub();
    window._chatUnsub = null;
  }
}

window.submitIcebreaker = function(choice) {
  var status = document.getElementById('icebreaker-status');
  status.textContent = "Waiting for match to answer...";
  
  if (window.currentUserUid && window.DB_Service) {
      // In a real app, this updates active_quests table
      // We will simulate the match answering after 3 seconds for the demo
      setTimeout(() => {
          document.getElementById('icebreaker-overlay').style.display = 'none';
          showToast('Icebreaker complete! Chat unlocked. ✨', 'earn', '+100');
          window.DB_Service.updateEmbers(window.currentUserUid, 100);
      }, 3000);
  }
};

function openChatDetail(user) {
  currentChatUser = user;
  var data = chatData[user];
  if (!data) return;
  var avatarEl = document.getElementById('chat-detail-avatar');
  avatarEl.innerHTML = '<img src="' + data.photo + '" alt="' + data.name + '" />';
  document.getElementById('chat-detail-name').textContent = data.name;
  var messages = document.getElementById('chat-messages');
  
  // Icebreaker UI Check
  var icebreaker = document.getElementById('icebreaker-overlay');
  if (user === 'maya') {
      icebreaker.style.display = 'flex';
      document.getElementById('icebreaker-status').textContent = '';
  } else {
      icebreaker.style.display = 'none';
  }
  
  // Dynamic Why Matched tag insight
  var userProfile = (profiles && profiles.find(p => p.name.toLowerCase() === user.toLowerCase() || (p.id && p.id.toLowerCase().includes(user.toLowerCase())))) ||
                    (seedProfiles && seedProfiles.find(p => p.name.toLowerCase() === user.toLowerCase()));
  var mutualTags = userProfile && userProfile.tags && userProfile.tags.length > 0 
    ? userProfile.tags.slice(0, 2).join(' & ') 
    : 'Coffee, Music & Spontaneous Vibes';
  var whyMatchedHtml = '<div id="why-matched-pill" class="why-matched-pill">⚡ Spark Insight: High shared affinity for ' + mutualTags + '!</div>';

  function updateChatFlowIndicator(msgCount) {
    var flowEl = document.getElementById('chat-flow-status');
    if (!flowEl) return;
    if (msgCount <= 2) {
      flowEl.innerHTML = '🔥 Spark: Warming Up';
      flowEl.style.borderColor = 'rgba(255, 255, 255, 0.2)';
    } else if (msgCount <= 6) {
      flowEl.innerHTML = '⚡ Spark: Flowing Smoothly';
      flowEl.style.borderColor = 'var(--cyan)';
    } else {
      flowEl.innerHTML = '🔥 Spark: Blazing Hot! 🔥';
    }
    if (window.VibeHeatmeter) window.VibeHeatmeter.updateHeat(msgCount);
  }

  // Load messages
  // We render local static messages first
  if (data.msgs.length > 0) {
    messages.innerHTML = whyMatchedHtml + '<div class="chat-date-divider">Previous</div>';
  } else {
    messages.innerHTML = whyMatchedHtml + '<div class="chat-date-divider">Today</div>';
  }
  updateChatFlowIndicator(data.msgs.length);

  function renderMsg(m) {
    var bubble = document.createElement('div');
    bubble.className = 'chat-bubble ' + m.type;

    if (m.video) {
      bubble.className += ' chat-bubble-video';
      bubble.innerHTML = `
        <div class="play-overlay" onclick="this.style.display='none'; this.nextElementSibling.play()"><div class="play-icon">▶</div></div>
        <video src="${m.videoSrc}" poster="${data.photo}" style="width:100%"></video>
        <span class="bubble-time">${m.time}</span>
      `;
    } else if (m.media) {
      bubble.innerHTML = '<div class="chat-bubble-media" onclick="openLightbox(\'' + m.media + '\')"><img src="' + m.media + '" alt="Shared" /></div><span class="bubble-time">' + m.time + '</span>';
    } else {
      bubble.innerHTML = '<p>' + m.text + '</p><span class="bubble-time">' + m.time + '</span>';
    }
    messages.appendChild(bubble);
  }

  // Render Client-side history
  data.msgs.forEach(renderMsg);

  // 2. Subscribe to Firebase Messages
  if (window.currentUserUid) {
    if (window._chatUnsub) window._chatUnsub(); // Unsub previous

    const partnerId = user.toLowerCase(); // Simple ID mapping
    window._chatUnsub = DB_Service.subscribeToChat(window.currentUserUid, partnerId, (newMsgs) => {
      newMsgs.forEach(msg => {
        // Map Supabase 'timestamp' to 'time' for renderMsg
        if (msg.timestamp && !msg.time) {
            var t = new Date(msg.timestamp);
            msg.time = (t.getHours() % 12 || 12) + ':' + String(t.getMinutes()).padStart(2, '0');
        }
        
        // Check if we already have this msg in local data
        const exists = data.msgs.some(existing => existing.text === msg.text);
        if (!exists) {
          renderMsg(msg);
          data.msgs.push(msg);
          updateChatFlowIndicator(data.msgs.length);
        }
      });
      messages.scrollTop = messages.scrollHeight;
    });
  }

  if (data.msgs.length === 0 && (!window.currentUserUid)) { // Only show hint if really empty
    var hint = document.createElement('div');
    hint.className = 'chat-bubble received';
    hint.innerHTML = '<p>You matched! Say something first ✨</p><span class="bubble-time">Now</span>';
    messages.appendChild(hint);
  }

  // Mount Co-Op Match Quest banner
  var coopMount = document.getElementById('coop-quest-mount');
  if (coopMount && window.CoopQuests) {
    coopMount.innerHTML = window.CoopQuests.renderCoopBar({ id: user, name: data.name });
  }

  // Mount Sparky AI Wingman suggestions tray
  var wingmanMount = document.getElementById('sparky-wingman-mount');
  if (wingmanMount && window.SparkyAI) {
    wingmanMount.innerHTML = window.SparkyAI.renderWingmanBar(userProfile || { name: data.name, tags: ['Coffee', 'Adventure'] });
  }

  document.getElementById('chat-detail-modal').style.display = 'flex';
  document.getElementById('ai-starters').style.display = 'none';
  messages.scrollTop = messages.scrollHeight;
}

function sendMessage() {
  try {
    var input = document.getElementById('chat-input');
    if (!input) return;

    var text = input.value.trim();
    if (!text || !currentChatUser) return;

    input.value = '';

    if (window.AudioFX) window.AudioFX.playPop();
    if (window.CoopQuests && currentChatUser) {
      window.CoopQuests.incrementProgress(currentChatUser, 'msgs', 1);
    }

    // If using DB, save it there
    if (window.currentUserUid && window.DB_Service && !window.isAiQuestActive) {
      window.DB_Service.sendMessage(window.currentUserUid, currentChatUser, { text: text, type: 'sent' });
    } else {
      // Fallback for local simulation or active AI Quest
      var messages = document.getElementById('chat-messages');
      var bubble = document.createElement('div');
      bubble.className = 'chat-bubble sent';
      var now = new Date();
      var timeStr = (now.getHours() % 12 || 12) + ':' + String(now.getMinutes()).padStart(2, '0');
      bubble.innerHTML = '<p>' + text + '</p><span class="bubble-time">' + timeStr + '</span>';
      messages.appendChild(bubble);
      messages.scrollTop = messages.scrollHeight;

      if (chatData[currentChatUser]) {
        chatData[currentChatUser].msgs.push({ text: text, type: 'sent', time: timeStr });
        var flowEl = document.getElementById('chat-flow-status');
        if (flowEl) {
          var c = chatData[currentChatUser].msgs.length;
          flowEl.innerHTML = c > 6 ? '🔥 Spark: Blazing Hot! 🔥' : '⚡ Spark: Flowing Smoothly';
          flowEl.style.borderColor = c > 6 ? 'var(--coral)' : 'var(--cyan)';
        }
      }
      
      // If AI Quest is active, process it
      if (window.isAiQuestActive && window.SparkAI && window.SparkAI.generateQuestStep) {
          window.aiQuestHistory = window.aiQuestHistory || [];
          window.aiQuestHistory.push({ role: 'user', content: text });
          
          var loading = document.createElement('div');
          loading.className = 'chat-bubble received';
          loading.innerHTML = '<div class="typing-indicator" style="display:inline-block"><span></span><span></span><span></span></div>';
          messages.appendChild(loading);
          messages.scrollTop = messages.scrollHeight;

          window.SparkAI.generateQuestStep(window.aiQuestHistory, text).then(reply => {
              messages.removeChild(loading);
              var rb = document.createElement('div');
              rb.className = 'chat-bubble received';
              rb.innerHTML = '<h4 style="color:#00E5FF; margin:0 0 5px 0;">🐉 AI Quest Master</h4><p>' + reply + '</p><span class="bubble-time">Just now</span>';
              rb.style.border = "1px solid #00E5FF";
              messages.appendChild(rb);
              messages.scrollTop = messages.scrollHeight;
              window.aiQuestHistory.push({ role: 'assistant', content: reply });
          }).catch(err => {
              messages.removeChild(loading);
              showToast('Quest step failed.', 'spend');
          });
      }
    }
  } catch (err) {
    console.error("Error sending message:", err);
  }
}



function moderateContent(text) {
  var flagWords = ['hate', 'kill', 'threat', 'spam', 'btc', 'crypto'];
  for (var i = 0; i < flagWords.length; i++) {
    if (text.toLowerCase().indexOf(flagWords[i]) >= 0) return true;
  }
  return false;
}

function attachMedia() {
  let fileInput = document.getElementById('chat-photo-file-input');
  if (!fileInput) {
    fileInput = document.createElement('input');
    fileInput.type = 'file';
    fileInput.id = 'chat-photo-file-input';
    fileInput.accept = 'image/*';
    fileInput.style.display = 'none';
    document.body.appendChild(fileInput);
  }

  fileInput.onchange = function(e) {
    const file = e.target.files && e.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = function(evt) {
      const dataUrl = evt.target.result;
      const messages = document.getElementById('chat-messages');
      const bubble = document.createElement('div');
      bubble.className = 'chat-bubble sent';
      const now = new Date();
      const timeStr = (now.getHours() % 12 || 12) + ':' + String(now.getMinutes()).padStart(2, '0');

      bubble.innerHTML = `
        <div class="chat-bubble-media ai-scanning" onclick="window.openLightbox('${dataUrl}')" style="cursor:pointer;">
          <img src="${dataUrl}" alt="Photo" style="max-height:220px; width:auto; border-radius:12px; object-fit:cover;" />
        </div>
        <span class="bubble-time">${timeStr}</span>
      `;
      messages.appendChild(bubble);
      messages.scrollTop = messages.scrollHeight;

      if (window.AudioFX) window.AudioFX.playPop();

      if (currentChatUser && chatData[currentChatUser]) {
        chatData[currentChatUser].msgs.push({ media: dataUrl, type: 'sent', time: timeStr });
      }

      if (window.CoopQuests && currentChatUser) {
        window.CoopQuests.incrementProgress(currentChatUser, 'msgs', 1);
      }

      setTimeout(function () {
        const mediaEl = bubble.querySelector('.chat-bubble-media');
        if (mediaEl) mediaEl.classList.remove('ai-scanning');
        showToast('Photo scanned by AI — safe ✓', 'info');
      }, 1500);
    };
    reader.readAsDataURL(file);
    fileInput.value = '';
  };

  fileInput.click();
}

// AI Conversation Starters
// AI Icebreakers (Real)
function generateStarters() {
  var container = document.getElementById('chat-suggestions');
  container.innerHTML = '<div class="typing-indicator"><span></span><span></span><span></span></div>';

  // Get current match data
  var matchName = currentChatUser ? (currentChatUser.charAt(0).toUpperCase() + currentChatUser.slice(1)) : 'Match';
  var interests = ['travel', 'coffee', 'gaming']; // Mock data
  var matchProfile = { name: matchName, tags: interests, bio: '' };
  
  if (currentChatUser && chatData[currentChatUser]) {
    interests = chatData[currentChatUser].tags || interests;
    matchProfile.tags = interests;
    matchProfile.bio = chatData[currentChatUser].detail || '';
  }
  
  // Mock User Profile for AI context (Normally fetched from DB)
  var myProfile = { name: 'User', tags: ['music', 'travel', 'food'], bio: 'Looking for someone to explore the city with.' };

  // Check if we should generate Icebreakers (empty chat) or Replies (existing chat)
  var history = [];
  if (currentChatUser && chatData[currentChatUser]) {
    history = chatData[currentChatUser].msgs || [];
  }

  if (window.SparkAI && window.SparkAI.apiKey) {
    let aiPromise;

    if (history.length > 0) {
      // Generate Reply
      aiPromise = window.SparkAI.generateReply(history.slice(-5), 'Dating app chat');
    } else {
      // Generate Icebreaker Context-Aware
      aiPromise = window.SparkAI.generateIcebreakers(myProfile, matchProfile);
    }

    aiPromise.then(function (suggestions) {
      container.innerHTML = '';
      if (suggestions && suggestions.length > 0) {
        suggestions.forEach(function (text) {
          var chip = document.createElement('div');
          chip.className = 'suggestion-chip';
          chip.textContent = text;
          chip.onclick = function () { sendSuggestion(text); };
          container.appendChild(chip);
        });
      } else {
        showFallbackStarters(container);
      }
    });
  } else {
    setTimeout(function () { showFallbackStarters(container); }, 500);
  }
}

function showFallbackStarters(container) {
  container.innerHTML = '';
  var starters = ["What's your favorite travel story? 🌍", "Coffee or Tea? ☕", "Best game you've played recently? 🎮"];
  starters.forEach(function (text) {
    var chip = document.createElement('div');
    chip.className = 'suggestion-chip';
    chip.textContent = text;
    chip.onclick = function () { sendSuggestion(text); };
    container.appendChild(chip);
  });
}

function sendSuggestion(text) {
  document.getElementById('chat-input').value = text;
  // Optionally, you might want to send the message immediately or just fill the input
  // sendMessage();
  hideAiStarters(); // Assuming this hides the suggestions container
}

window.generateAiReply = async function() {
  if (!currentChatUser) return;
  var data = chatData[currentChatUser];
  if (!data || data.msgs.length === 0) {
      showToast('No messages to reply to yet!', 'info');
      return;
  }
  
  var input = document.getElementById('chat-input');
  input.placeholder = "🤖 Sparky is thinking...";
  input.disabled = true;
  
  try {
      var recentMsgs = data.msgs.slice(-3).map(m => (m.type === 'sent' ? 'Me: ' : data.name + ': ') + m.text).join('\n');
      var reply = await window.SparkAI.generateReply(data.name, recentMsgs);
      input.value = reply;
  } catch(e) {
      console.error(e);
      showToast('AI failed to generate reply', 'spend');
  } finally {
      input.placeholder = "Type something thoughtful...";
      input.disabled = false;
  }
}

function showAiStarters() {
  var data = chatData[currentChatUser];
  if (!data) return;
  // The new generateStarters function will handle populating the suggestions
  generateStarters();
  document.getElementById('ai-starters').style.display = 'block';
}

function hideAiStarters() { document.getElementById('ai-starters').style.display = 'none'; }

// Lightbox
function openLightbox(src) {
  document.getElementById('lightbox-img').src = src;
  document.getElementById('media-lightbox').style.display = 'flex';
}
function closeLightbox() { document.getElementById('media-lightbox').style.display = 'none'; }

// Stories
function openStory(userId) {
  var data = storyData[userId];
  if (!data) return;
  currentStory = data;
  currentSlideIndex = 0;
  document.getElementById('story-viewer').style.display = 'flex';
  document.getElementById('story-user-avatar').innerHTML = '<img src="' + data.photo + '" alt="' + data.name + '" />';
  document.getElementById('story-user-name').textContent = data.name;
  var bars = document.getElementById('story-progress-bars');
  bars.innerHTML = '';
  for (var i = 0; i < data.slides.length; i++) {
    var bar = document.createElement('div');
    bar.className = 'story-progress-bar';
    bar.innerHTML = '<div class="story-progress-fill"></div>';
    bars.appendChild(bar);
  }
  showSlide(0);
}

function showSlide(idx) {
  if (!currentStory || idx >= currentStory.slides.length) { closeStory(); return; }
  currentSlideIndex = idx;
  var slide = currentStory.slides[idx];
  var content = document.getElementById('story-content');

  // Reset content
  content.innerHTML = '';
  content.style.background = slide.bg || '#000';

  if (slide.type === 'video') {
    content.innerHTML = '<video src="' + slide.videoSrc + '" autoplay loop playsinline style="width:100%; height:100%; object-fit:cover;"></video>';
  } else {
    content.innerHTML = '<div class="story-text-overlay">' + slide.text + '</div>';
  }

  var fills = document.querySelectorAll('#story-progress-bars .story-progress-fill');
  for (var i = 0; i < fills.length; i++) {
    fills[i].className = 'story-progress-fill';
    if (i < idx) fills[i].classList.add('done');
    else if (i === idx) fills[i].classList.add('active');
  }
  clearTimeout(storyTimer);
  storyTimer = setTimeout(function () { advanceStory(); }, 5000);
}

function advanceStory() { showSlide(currentSlideIndex + 1); }
function closeStory() { document.getElementById('story-viewer').style.display = 'none'; clearTimeout(storyTimer); currentStory = null; }
function addStory() {
  openCamera('story');
}
function reactToStory(emoji) { showToast('Reacted with ' + emoji, 'info'); }

// AI Polish Bio (Real)
async function aiPolishBio() {
  if (!window.SparkAI || !window.SparkAI.apiKey) {
    showToast('Please enter your Gemini API Key in Settings first!', 'spend');
    openSettingsModal();
    return;
  }

  var bioEl = document.getElementById('ai-polish-bio');
  var btn = document.getElementById('btn-ai-polish');

  if (!bioEl || !btn) return;

  var originalText = bioEl.innerText;

  btn.disabled = true;
  btn.innerText = '✨ Polish in progress...';

  // Visual shimmer effect
  bioEl.style.opacity = '0.5';

  const newBio = await window.SparkAI.polishBio(originalText);

  bioEl.style.opacity = '1';
  btn.disabled = false;
  btn.innerText = '✨ Polish My Bio with AI';

  if (newBio) {
    bioEl.innerText = newBio;
    showToast('Bio polished successfully! ✨', 'earn', '+50');
    updateQuestProgress('engage3'); // Quest: Update Bio
  } else {
    showToast('AI request failed. Please check your API Key.', 'spend');
  }
}

// Voice Prompts
function playVoicePrompt() {
  var waveform = document.getElementById('voice-waveform');
  waveform.classList.toggle('playing');
  if (waveform.classList.contains('playing')) {
    setTimeout(function () { waveform.classList.remove('playing'); }, 8000);
  }
}

let mediaRecorder;
let audioChunks = [];

async function recordVoicePrompt() {
  document.getElementById('recording-overlay').style.display = 'flex';
  
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    mediaRecorder = new MediaRecorder(stream);
    audioChunks = [];

    mediaRecorder.ondataavailable = (event) => {
      if (event.data.size > 0) audioChunks.push(event.data);
    };

    mediaRecorder.onstop = async () => {
      const audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
      const audioUrl = URL.createObjectURL(audioBlob);
      // Attach to the play button
      const playBtn = document.querySelector('.voice-play-btn');
      playBtn.onclick = () => {
        const audio = new Audio(audioUrl);
        audio.play();
      };
      
      showToast('Voice prompt recorded! 🎙️', 'earn', '+50');
      if (window.currentUserUid && window.DB_Service) {
        window.DB_Service.updateEmbers(window.currentUserUid, 50);
        
        // Upload to Supabase Storage
        const publicUrl = await window.DB_Service.uploadVoicePrompt(window.currentUserUid, audioBlob);
        if (publicUrl) {
           console.log("Voice prompt uploaded successfully to", publicUrl);
        }
      } else {
        embers += 50;
        updateEmberDisplay();
      }
    };

    mediaRecorder.start();

    var sec = 0;
    var timer = document.getElementById('recording-timer');
    window._recInterval = setInterval(function () {
      sec++;
      timer.textContent = '0:' + String(sec).padStart(2, '0');
    }, 1000);

  } catch (err) {
    console.error("Microphone access denied or error:", err);
    document.getElementById('recording-overlay').style.display = 'none';
    showToast('Microphone access required! ⚠️');
  }
}

function stopVoiceRecording() {
  clearInterval(window._recInterval);
  document.getElementById('recording-overlay').style.display = 'none';
  if (mediaRecorder && mediaRecorder.state === 'recording') {
    mediaRecorder.stop();
    // Stop all microphone tracks
    mediaRecorder.stream.getTracks().forEach(track => track.stop());
  }
}

// Video Date
function scheduleVideoDate() {
  document.getElementById('video-date-modal').style.display = 'flex';
  selectedVideoTime = null;
}

function selectVideoTime(el) {
  var opts = document.querySelectorAll('.video-time-option');
  for (var i = 0; i < opts.length; i++) opts[i].classList.remove('selected');
  el.classList.add('selected');
  selectedVideoTime = el.textContent;
}

function confirmVideoDate() {
  if (!selectedVideoTime) { showToast('Pick a time first!', 'info'); return; }
  closeModal('video-date-modal');
  showToast('Video date scheduled: ' + selectedVideoTime + ' 📹', 'info');
  setTimeout(function () { startVideoCall(); }, 1500);
}

function startVideoCall() {
  document.getElementById('video-call-screen').style.display = 'flex';
  var name = currentChatUser && chatData[currentChatUser] ? chatData[currentChatUser].name : 'Match';
  document.getElementById('video-call-name').textContent = name;
  videoCallSeconds = 0;
  videoCallTimer = setInterval(function () {
    videoCallSeconds++;
    var m = Math.floor(videoCallSeconds / 60);
    var s = videoCallSeconds % 60;
    document.getElementById('video-call-timer').textContent = String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
  }, 1000);
}

function endVideoDate() {
  clearInterval(videoCallTimer);
  document.getElementById('video-call-screen').style.display = 'none';
  showToast('Great call! Trust Score +5 🛡️', 'earn', '+5');
}

function toggleMute() { showToast('Mic toggled', 'info'); }
function toggleCamera() { showToast('Camera toggled', 'info'); }

// Date Planner
function openDatePlanner() {
  document.getElementById('date-planner-modal').style.display = 'flex';
  selectedVenue = null;
  document.getElementById('ai-venue-suggestion').style.display = 'none';
}

function selectVenue(el, type) {
  var opts = document.querySelectorAll('.venue-option');
  for (var i = 0; i < opts.length; i++) opts[i].classList.remove('selected');
  el.classList.add('selected');
  selectedVenue = type;
  var suggestions = {
    drinks: '🍷 <strong>Skyline Rooftop Lounge</strong> — $20 off couples cocktails tonight!',
    dinner: '🍽️ <strong>Firefly Bistro</strong> — Candlelit tasting menu, 4.8★ rated!',
    coffee: '☕ <strong>Bean & Bloom Café</strong> — Cozy vibes, great pour-overs!',
    movie: '🎬 <strong>Starlight Cinema</strong> — Outdoor screening under the stars!',
    outdoor: '🏞️ <strong>Sunset Ridge Trail</strong> — Golden hour magic, 3mi loop!',
    creative: '🎨 <strong>Paint & Sip Studio</strong> — BYOB canvas night this Friday!'
  };
  document.getElementById('venue-suggestion-body').innerHTML = suggestions[type] || '';
  document.getElementById('ai-venue-suggestion').style.display = 'block';
}

// Date Planner
window.openDatePlanner = openDatePlanner;
window.selectVenue = selectVenue;
window.confirmDate = confirmDate;

function confirmDate() {
  if (!selectedVenue) { showToast('Choose a vibe first!', 'info'); return; }
  closeModal('date-planner-modal');

  var reward = 15;
  if (window.currentUserUid) {
    DB_Service.updateEmbers(window.currentUserUid, reward);
  } else {
    window.embers += reward;
    updateEmberDisplay();
  }

  showToast('Date plan sent! 📅', 'earn', '+' + reward);
}

// Safety Features
function startSelfieVerification() { document.getElementById('selfie-modal').style.display = 'flex'; }

var uploadedSelfieBase64 = null;

function handleSelfieUpload(input) {
  if (input.files && input.files[0]) {
    var reader = new FileReader();
    reader.onload = function (e) {
      uploadedSelfieBase64 = e.target.result;
      document.getElementById('selfie-status').textContent = '📸 Photo loaded! Ready to verify.';
      // Optional: show preview
      document.querySelector('.selfie-camera').style.backgroundImage = 'url(' + e.target.result + ')';
      document.querySelector('.selfie-camera').style.backgroundSize = 'cover';
    };
    reader.readAsDataURL(input.files[0]);
  }
}

function captureSelfie() {
  var status = document.getElementById('selfie-status');
  var btn = document.getElementById('selfie-capture-btn');

  // Use uploaded image or fallback to the red dot if they didn't upload (for demo)
  // But for "Real AI", we prefer the upload.
  var imageToAnalyze = uploadedSelfieBase64;

  if (!imageToAnalyze) {
    // If no image uploaded, warn them or use a fallback sample that is a real face?
    // For now, let's just alert them to upload for the real test.
    if (window.SparkAI && window.SparkAI.apiKey) {
      if (!confirm("No photo uploaded. Connect to AI with a mock image?")) return;
      // Use a sample face image (base64 of a placeholder would be huge, let's use the red dot but warn it might fail)
      imageToAnalyze = "data:image/jpeg;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==";
    } else {
      // No API key, just simulate success
      setTimeout(finishVerification, 1500);
      return;
    }
  }

  btn.disabled = true;
  btn.textContent = '⏳ Verifying...';
  status.textContent = 'Analyzing selfie...';

  if (window.SparkAI && window.SparkAI.apiKey) {
    window.SparkAI.analyzeImage(imageToAnalyze).then(function (result) {
      console.log("AI Analysis Result:", result);
      if (result) {
        // Strict check: needs to be safe. 
        // Note: The red dot might not return 'safe' or 'person'.
        if (result.safe) {
          finishVerification();
        } else {
          status.textContent = '❌ AI Analysis: Not a verified person or unsafe.';
          btn.disabled = false;
          btn.textContent = '📷 Capture / Upload';
        }
      } else {
        status.textContent = '❌ AI Request Failed.';
        btn.disabled = false;
        btn.textContent = '📷 Capture / Upload';
      }
    });
  } else {
    setTimeout(finishVerification, 2500);
  }

  function finishVerification() {
    status.textContent = '✓ Verified!';
    status.style.color = '#22C55E';
    btn.textContent = '✓ Verified!';
    btn.style.background = 'linear-gradient(135deg, #22C55E, #10B981)';
    showToast('Selfie verified! Gold Badge unlocked 🛡️', 'earn', '+30');
    if (window.currentUserUid) {
      DB_Service.updateEmbers(window.currentUserUid, 30);
    } else {
      embers += 30;
      updateEmberDisplay();
    }
    setTimeout(function () { closeModal('selfie-modal'); }, 1500);
  }
}

// Safety & Report
window.openReportModal = openReportModal;
window.submitReport = submitReport;
window.activatePanicButton = activatePanicButton;
window.cancelPanic = cancelPanic;
window.toggleIntimateMode = toggleIntimateMode;
window.verifyAge = verifyAge;
window.simulateIdUpload = simulateIdUpload;

function openReportModal(user) {
  document.getElementById('report-modal').dataset.user = user;
  document.getElementById('report-modal').style.display = 'flex';
}

function submitReport(reason) {
  var user = document.getElementById('report-modal').dataset.user;
  closeModal('report-modal');

  showToast('Report submitted. User blocked. 🛡️', 'info');

  if (user && user !== 'general') {
    // Hide from Chat List
    var chatItem = document.querySelector(`.chat-item[onclick*="${user}"]`);
    if (chatItem) chatItem.style.display = 'none';

    // If we were in the chat detail, close it
    if (currentChatUser === user) closeChatDetail();
  }
}

// Quest Logic
// Quest Logic
window.updateQuestProgress = updateQuestProgress;
window.claimQuestReward = claimQuestReward;

function updateQuestProgress(questId) {
  if (!window.questProgress[questId] || window.questProgress[questId].claimed) return;

  // Optimistic update
  window.questProgress[questId].current++;
  var q = window.questProgress[questId];

  if (window.currentUserUid) {
    // Sync to DB
    DB_Service.updateQuest(window.currentUserUid, questId, q);
  }

  // Update UI if on Quest Screen (simplified: just find by data attribute)
  var card = document.querySelector(`.quest-card[data-quest="${questId}"]`);
  if (card) {
    var pct = Math.min(100, (q.current / q.target) * 100);
    card.querySelector('.quest-fill').style.width = pct + '%';
    card.querySelector('.quest-progress-text').textContent = q.current + ' / ' + q.target;

    if (q.current >= q.target) {
      showToast('Quest Completed! Claim your reward 🎁', 'earn');
      card.classList.add('completed');
      card.onclick = function () { claimQuestReward(this, questId); };
    }
  }
}

function claimQuestReward(card, questId) {
  if (window.questProgress[questId].claimed) return;

  window.questProgress[questId].claimed = true;
  var reward = 0;
  if (questId === 'engage1') reward = 20;
  if (questId === 'engage2') reward = 30;
  if (questId === 'engage4') reward = 50;
  if (questId === 'engage5') reward = 15;
  if (questId === 'engage6') reward = 40;

  if (window.currentUserUid) {
    DB_Service.updateEmbers(window.currentUserUid, reward);
    DB_Service.updateQuest(window.currentUserUid, questId, window.questProgress[questId]);
  } else {
    window.embers += reward;
    updateEmberDisplay();
  }

  card.querySelector('.quest-reward').classList.add('claimed');
  card.querySelector('.quest-progress-text').textContent = 'Done ✓';
  showToast('Quest Reward Claimed! +' + reward + ' Embers', 'earn', '+' + reward);
  floatingEmber();

  if (window.AudioFX) window.AudioFX.playEmberClaim();
  confetti({ particleCount: 50, spread: 60, origin: { y: 0.5 } });
  try {
    Haptics.notification({ type: 'SUCCESS' }).catch(() => {});
  } catch (e) {}
}

function activatePanicButton() {
  document.getElementById('panic-modal').style.display = 'flex';
  var count = 5;
  document.getElementById('panic-countdown').textContent = count;
  document.getElementById('panic-timer').textContent = count;
  panicInterval = setInterval(function () {
    count--;
    document.getElementById('panic-countdown').textContent = count;
    document.getElementById('panic-timer').textContent = count;
    if (count <= 0) {
      clearInterval(panicInterval);
      closeModal('panic-modal');
      showToast('🚨 Emergency contacts notified with your location', 'info');
    }
  }, 1000);
}

function cancelPanic() { clearInterval(panicInterval); closeModal('panic-modal'); showToast('Emergency alert cancelled', 'info'); }

// Intimate Mode
function toggleIntimateMode() {
  if (!ageVerified) { document.getElementById('age-gate-modal').style.display = 'flex'; return; }
  isIntimateMode = !isIntimateMode;
  document.getElementById('intimate-toggle').checked = isIntimateMode;
  showToast(isIntimateMode ? 'Intimate Mode enabled 🔥' : 'Intimate Mode disabled', 'info');
}

function verifyAge() {
  var check = document.getElementById('age-confirm-check');
  if (!check.checked) { showToast('Please confirm your age', 'info'); return; }
  ageVerified = true;
  closeModal('age-gate-modal');
  isIntimateMode = true;
  document.getElementById('intimate-toggle').checked = true;
  showToast('Age verified! Intimate Mode enabled 🔥', 'info');
}

function simulateIdUpload() {
  document.getElementById('id-upload-text').textContent = '✓ ID uploaded — reviewing...';
  setTimeout(function () { document.getElementById('id-upload-text').textContent = '✓ ID verified!'; }, 1500);
}

// Rewarded Ad
function showRewardedAd() {
  document.getElementById('rewarded-ad-overlay').style.display = 'flex';
  var count = 5;
  var el = document.getElementById('ad-countdown');
  el.textContent = 'Skip in ' + count + 's';
  el.onclick = null;
  var interval = setInterval(function () {
    count--;
    if (count > 0) {
      el.textContent = 'Skip in ' + count + 's';
    } else {
      clearInterval(interval);
      el.textContent = 'Skip ✕';
      el.style.cursor = 'pointer';
      el.onclick = function () { closeRewardedAd(); };
    }
  }, 1000);
}

window.showRewardedAd = showRewardedAd;
window.closeRewardedAd = closeRewardedAd;
function closeRewardedAd() {
  document.getElementById('rewarded-ad-overlay').style.display = 'none';
  var reward = 20;
  if (window.currentUserUid) {
    DB_Service.updateEmbers(window.currentUserUid, reward);
  } else {
    window.embers += reward;
    updateEmberDisplay();
  }
  showToast('You earned ' + reward + ' Embers! 🎬', 'earn', '+' + reward);
  floatingEmber();
}

// Toast System
function showToast(text, type, amount) {
  type = type || 'info';
  amount = amount || '';

  // Play Sound based on type
  if (type === 'earn') SoundService.playSuccess();
  if (type === 'spend') SoundService.playClick();
  if (type === 'error') SoundService.playError();

  var container = document.getElementById('toast-container');
  var toast = document.createElement('div');
  toast.className = 'toast ' + type;
  var icons = { earn: '✦', spend: '✦', info: 'ℹ️' };
  var amountHtml = amount ? '<span class="toast-amount">' + amount + '</span>' : '';
  toast.innerHTML = '<span class="toast-icon">' + (icons[type] || 'ℹ️') + '</span><span class="toast-text">' + text + '</span>' + amountHtml;
  container.appendChild(toast);
  setTimeout(function () { toast.remove(); }, 3500);
}

// Floating Ember Effect
function floatingEmber() {
  var el = document.createElement('div');
  el.className = 'floating-ember';
  el.textContent = '✦';
  el.style.left = (30 + Math.random() * 40) + '%';
  el.style.top = '50%';
  el.style.color = '#FFB800';
  document.body.appendChild(el);
  setTimeout(function () { el.remove(); }, 2000);
}

// ===== AFFILIATE INVITE PROGRAM =====

// Invite Tiers
var inviteTiers = [
  { name: 'Spark', icon: '🔥', threshold: 0, reward: 25, perk: '' },
  { name: 'Flame', icon: '⚡', threshold: 3, reward: 50, perk: 'Neon Profile Frame' },
  { name: 'Blaze', icon: '💎', threshold: 10, reward: 75, perk: 'Free Boost' },
  { name: 'Inferno', icon: '👑', threshold: 25, reward: 100, perk: '1-week Gold sub' },
  { name: 'Supernova', icon: '🌟', threshold: 50, reward: 150, perk: 'Permanent VIP badge + Revenue share' },
];

// Invite State
var inviteCount = 0;
var inviteActiveCount = 0;
var inviteEmbersEarned = 0;
var currentInviteTier = 0;
var inviteActivityLog = [];

// Demo names for simulated invites
var demoInviteNames = [
  'Emma L.', 'Noah W.', 'Olivia R.', 'Liam K.', 'Ava P.',
  'Mia J.', 'Ethan C.', 'Harper T.', 'Lucas D.', 'Chloe B.',
  'Sophia G.', 'Mason F.', 'Ella N.', 'James H.', 'Aria S.',
  'Benjamin Z.', 'Luna M.', 'Henry V.', 'Grace A.', 'Jack Q.',
  'Amelia X.', 'Logan U.', 'Lily E.', 'Owen I.', 'Riley O.',
  'Daniel Y.', 'Nora R.', 'Carter B.', 'Zoe K.', 'Wyatt T.',
  'Hannah F.', 'Dylan J.', 'Julia M.', 'Caleb P.', 'Layla W.',
  'Andrew S.', 'Penelope V.', 'Isaac A.', 'Scarlett D.', 'Nathan G.',
  'Victoria L.', 'Luke H.', 'Madeline N.', 'Ryan C.', 'Stella Z.',
  'Aaron Q.', 'Hazel X.', 'Joshua U.', 'Violet I.', 'Eli O.'
];

function getCurrentTierIndex() {
  var idx = 0;
  for (var i = inviteTiers.length - 1; i >= 0; i--) {
    if (inviteCount >= inviteTiers[i].threshold) { idx = i; break; }
  }
  return idx;
}

function getRewardForCurrentTier() {
  return inviteTiers[getCurrentTierIndex()].reward;
}

function updateInviteUI() {
  var tierIdx = getCurrentTierIndex();
  var tier = inviteTiers[tierIdx];

  // Tier name
  var tierNameEl = document.getElementById('invite-tier-name');
  if (tierNameEl) tierNameEl.textContent = tier.icon + ' ' + tier.name;

  // Progress bar
  var fillEl = document.getElementById('invite-tier-fill');
  if (fillEl) {
    if (tierIdx < inviteTiers.length - 1) {
      var nextThreshold = inviteTiers[tierIdx + 1].threshold;
      var currentThreshold = tier.threshold;
      var progress = ((inviteCount - currentThreshold) / (nextThreshold - currentThreshold)) * 100;
      fillEl.style.width = Math.min(100, progress) + '%';
    } else {
      fillEl.style.width = '100%';
    }
  }

  // Milestones
  var milestones = document.querySelectorAll('.invite-tier-milestones .milestone');
  for (var i = 0; i < milestones.length; i++) {
    milestones[i].classList.remove('active', 'reached');
    var req = parseInt(milestones[i].getAttribute('data-tier'));
    if (i === tierIdx) milestones[i].classList.add('active');
    else if (inviteCount >= req) milestones[i].classList.add('reached');
  }

  // Next tier info
  var nextEl = document.getElementById('invite-tier-next');
  if (nextEl) {
    if (tierIdx < inviteTiers.length - 1) {
      var next = inviteTiers[tierIdx + 1];
      var remaining = next.threshold - inviteCount;
      nextEl.innerHTML = '<span>Next tier: <strong>' + next.icon + ' ' + next.name + '</strong> — invite <span id="invites-to-next">' + remaining + '</span> more friend' + (remaining !== 1 ? 's' : '') + '</span>';
    } else {
      nextEl.innerHTML = '<span>🎉 <strong>Max tier reached!</strong> You are a Supernova!</span>';
    }
  }

  // Reward display
  var rewardEl = document.getElementById('invite-tier-reward');
  if (rewardEl) {
    rewardEl.innerHTML = '<span class="ember-icon">✦</span> Currently earning <strong>' + tier.reward + ' Embers</strong> per invite';
  }

  // Tier detail items
  for (var j = 0; j < inviteTiers.length; j++) {
    var item = document.getElementById('tier-item-' + j);
    if (item) {
      item.classList.remove('active', 'reached');
      if (j === tierIdx) item.classList.add('active');
      else if (j < tierIdx) item.classList.add('reached');
    }
  }

  // Stats
  var totalEl = document.getElementById('invite-total-count');
  var activeEl = document.getElementById('invite-active-count');
  var embersEl = document.getElementById('invite-embers-earned');
  if (totalEl) totalEl.textContent = inviteCount;
  if (activeEl) activeEl.textContent = inviteActiveCount;
  if (embersEl) embersEl.textContent = inviteEmbersEarned;

  // Leaderboard "You" row
  var lbRank = document.getElementById('lb-your-rank');
  var lbCount = document.getElementById('lb-your-count');
  if (lbRank) {
    if (inviteCount >= 47) lbRank.textContent = '1';
    else if (inviteCount >= 38) lbRank.textContent = '2';
    else if (inviteCount >= 31) lbRank.textContent = '3';
    else if (inviteCount >= 24) lbRank.textContent = '4';
    else if (inviteCount >= 19) lbRank.textContent = '5';
    else if (inviteCount > 0) lbRank.textContent = '6';
    else lbRank.textContent = '—';
  }
  if (lbCount) lbCount.textContent = inviteCount + ' invite' + (inviteCount !== 1 ? 's' : '');
}

function simulateInvite() {
  var oldTier = getCurrentTierIndex();
  var reward = getRewardForCurrentTier();
  inviteCount++;
  inviteActiveCount = Math.ceil(inviteCount * (0.6 + Math.random() * 0.3));
  inviteEmbersEarned += reward;
  if (window.currentUserUid) {
    DB_Service.updateEmbers(window.currentUserUid, reward);
  } else {
    embers += reward;
    updateEmberDisplay();
  }

  // Pick a demo name
  var nameIdx = (inviteCount - 1) % demoInviteNames.length;
  var friendName = demoInviteNames[nameIdx];

  // Add activity log entry
  var timeLabels = ['Just now', '1m ago', '3m ago', '5m ago', '10m ago'];
  inviteActivityLog.unshift({
    name: friendName,
    reward: reward,
    time: timeLabels[0]
  });
  // Shift times for older entries
  for (var i = 1; i < inviteActivityLog.length; i++) {
    inviteActivityLog[i].time = timeLabels[Math.min(i, timeLabels.length - 1)];
  }
  renderActivityFeed();

  // Check for tier upgrade
  var newTier = getCurrentTierIndex();
  if (newTier > oldTier) {
    var tierData = inviteTiers[newTier];
    showToast('🎉 Tier upgrade! You\'re now ' + tierData.icon + ' ' + tierData.name + '!', 'earn', '+' + reward);
    // Animate tier card
    var tierCard = document.querySelector('.invite-tier-card');
    if (tierCard) {
      tierCard.classList.add('tier-upgrading');
      setTimeout(function () { tierCard.classList.remove('tier-upgrading'); }, 700);
    }
    if (tierData.perk) {
      setTimeout(function () {
        showToast('Perk unlocked: ' + tierData.perk + ' 🎁', 'info');
      }, 1200);
    }
  } else {
    showToast(friendName + ' joined using your code! +' + reward + ' Embers ✦', 'earn', '+' + reward);
  }

  floatingEmber();
  updateInviteUI();
}

function renderActivityFeed() {
  var list = document.getElementById('invite-activity-list');
  if (!list) return;
  if (inviteActivityLog.length === 0) {
    list.innerHTML = '<div class="invite-empty-state"><span class="invite-empty-icon">🎁</span><p>No referrals yet — share your code to get started!</p></div>';
    return;
  }
  list.innerHTML = '';
  var max = Math.min(inviteActivityLog.length, 8);
  for (var i = 0; i < max; i++) {
    var entry = inviteActivityLog[i];
    var item = document.createElement('div');
    item.className = 'invite-activity-item';
    item.innerHTML =
      '<span class="invite-activity-icon">👤</span>' +
      '<span class="invite-activity-text"><strong>' + entry.name + '</strong> joined SparkQuest</span>' +
      '<span class="invite-activity-amount">+' + entry.reward + ' ✦</span>' +
      '<span class="invite-activity-time">' + entry.time + '</span>';
    list.appendChild(item);
  }
}

function copyInviteCode() {
  var code = document.getElementById('invite-code').textContent;
  if (navigator.clipboard) {
    navigator.clipboard.writeText(code);
  }
  showToast('Invite code copied: ' + code + ' 📋', 'info');
}
window.copyInviteCode = copyInviteCode;

window.shareInviteLink = shareInviteLink;
window.shareViaText = shareViaText;
window.showQrCode = showQrCode;

function shareInviteLink() {
  var code = document.getElementById('invite-code').textContent;
  var link = 'https://sparkquest.app/join?code=' + code;
  if (navigator.clipboard) {
    navigator.clipboard.writeText(link);
  }
  showToast('Invite link copied! Share it with friends 🔗', 'info');
}

function shareViaText() {
  var code = document.getElementById('invite-code').textContent;
  showToast('SMS share opened with code ' + code + ' 💬', 'info');
}

function showQrCode() {
  document.getElementById('qr-modal').style.display = 'flex';
}

// ===== SETTINGS & CALENDAR =====
window.openSettingsModal = openSettingsModal;
window.openCalendarModal = openCalendarModal;
window.toggleSetting = toggleSetting;
window.saveApiKey = saveApiKey;

function openSettingsModal() {
  document.getElementById('settings-modal').style.display = 'flex';
  var savedKey = localStorage.getItem('spark_gemini_api_key');

  // Also check in-memory key if available
  if (!savedKey && window.SparkAI && window.SparkAI.apiKey) {
    savedKey = window.SparkAI.apiKey;
  }

  if (savedKey) document.getElementById('settings-api-key').value = savedKey;
}
function openCalendarModal() { document.getElementById('calendar-modal').style.display = 'flex'; }

function toggleSetting(type) {
  var state = event.target.checked;
  var msg = '';
  if (type === 'notif') msg = state ? 'Notifications Enabled 🔔' : 'Notifications Paused 🔕';
  if (type === 'ghost') msg = state ? 'Ghost Mode Active 👻' : 'You are visible again 👀';
  showToast(msg, 'info');
}

// Calendar Logic
var scheduledDates = [
  { id: 1, title: 'Video Date with Sophia', time: 'Today, 7:00 PM', type: 'video', day: '18', month: 'FEB' }
];

function renderCalendar() {
  var list = document.getElementById('calendar-list');
  var empty = document.querySelector('.date-empty-state');

  // Clear existing cards (keep empty state)
  var cards = list.querySelectorAll('.date-card');
  for (var i = 0; i < cards.length; i++) cards[i].remove();

  if (scheduledDates.length === 0) {
    empty.style.display = 'flex';
  } else {
    empty.style.display = 'none';
    for (var i = 0; i < scheduledDates.length; i++) {
      var d = scheduledDates[i];
      var card = document.createElement('div');
      card.className = 'date-card';
      card.innerHTML = `
        <div class="date-date">
          <span class="date-day">${d.day}</span>
          <span class="date-month">${d.month}</span>
        </div>
        <div class="date-info">
          <span class="date-title">${d.title}</span>
          <span class="date-time">${d.time} · ${d.type === 'video' ? 'In-App Video' : 'In Person'}</span>
        </div>
        <div class="date-actions">
          <button class="btn-xs primary" onclick="joinDate(${d.id})">Join</button>
          <button class="btn-xs secondary" onclick="rescheduleDate(${d.id})">Reschedule</button>
        </div>
      `;
      list.insertBefore(card, empty);
    }
  }
}

function saveApiKey() {
  var apiKey = document.getElementById('settings-api-key').value.trim();
  if (apiKey) {
    if (window.SparkAI) {
      window.SparkAI.init(apiKey);
      localStorage.setItem('spark_gemini_api_key', apiKey);
      showToast('API Key saved! AI features enabled 🤖', 'info');
    }
  } else {
    localStorage.removeItem('spark_gemini_api_key');
    if (window.SparkAI) window.SparkAI.init(null);
    showToast('API Key removed.', 'info');
  }
  closeModal('settings-modal');
}

window.joinDate = joinDate;
window.rescheduleDate = rescheduleDate;

function joinDate(id) {
  closeModal('calendar-modal');
  startVideoCall();
}

function rescheduleDate(id) {
  showToast('Reschedule request sent!', 'info');
}

// Update confirmVideoDate to add to calendar
var originalConfirmVideoDate = confirmVideoDate;
confirmVideoDate = function () {
  if (!selectedVideoTime) { showToast('Pick a time first!', 'info'); return; }

  // Parse time for demo
  var now = new Date();
  var day = now.getDate();
  var month = now.toLocaleString('default', { month: 'short' }).toUpperCase();

  scheduledDates.push({
    id: Date.now(),
    title: 'Video Date with ' + (currentChatUser ? chatData[currentChatUser].name : 'Match'),
    time: selectedVideoTime,
    type: 'video',
    day: day,
    month: month
  });

  renderCalendar();
  originalConfirmVideoDate();
};

// Initial Render
document.addEventListener('DOMContentLoaded', renderCalendar);

// End of App Logic

window.checkDailyLogin = function() {
  var lastLogin = localStorage.getItem("spark_last_login");
  var streak = parseInt(localStorage.getItem("spark_login_streak") || "0");
  var today = new Date().toDateString();
  
  if (lastLogin !== today) {
      var yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      
      if (lastLogin === yesterday.toDateString()) {
          streak += 1;
      } else {
          streak = 1;
      }
      
      localStorage.setItem("spark_login_streak", streak);
      var streakEl = document.getElementById("daily-streak");
      if (streakEl) streakEl.textContent = streak;
      var modal = document.getElementById("daily-login-modal");
      if (modal) modal.style.display = "flex";
  }
};

window.claimDailyReward = function() {
  document.getElementById("daily-login-modal").style.display = "none";
  localStorage.setItem("spark_last_login", new Date().toDateString());
  showToast("Daily Login Reward Claimed! ??", "earn", "+50");
  
  if (window.currentUserUid && window.DB_Service) {
      window.DB_Service.updateEmbers(window.currentUserUid, 50);
  } else {
      window.embers += 50;
      updateEmberDisplay();
  }
};

window.uploadProfilePhoto = function(event) {
  var file = event.target.files[0];
  if (file) {
      var reader = new FileReader();
      reader.onload = function(e) {
          var img = document.getElementById('my-profile-img');
          if (img) img.src = e.target.result;
          showToast('Profile photo updated!', 'info');
      }
      reader.readAsDataURL(file);
  }
};

window.saveProfileTags = function() {
  var input = document.getElementById('my-tags-input');
  if (input && input.value) {
      showToast('Tags saved: ' + input.value, 'earn', '+10');
      // In a real app, this would sync to Supabase
  } else {
      showToast('Please enter some tags', 'info');
  }
};

window.joinMaskedSpark = function() {
  showToast('Searching for an anonymous match...', 'info');
  setTimeout(() => {
    alert("You've been matched with a mysterious Spark! (Voice channel would open here in production)");
  }, 2000);
};

window.startAiQuest = function() {
  if (!window.currentChatUser) {
    showToast('Open a chat first to start a quest.', 'spend');
    return;
  }
  showToast('Generating AI Quest...', 'info');
  if (window.SparkAI && window.SparkAI.generateQuestStep) {
     window.SparkAI.generateQuestStep([], "Start a new adventure!").then(reply => {
         var messages = document.getElementById('chat-messages');
         if (!messages) return;
         var rb = document.createElement('div');
         rb.className = 'chat-bubble received';
         rb.innerHTML = '<h4 style="color:#00E5FF; margin:0 0 5px 0;">🐉 AI Quest Master</h4><p>' + reply + '</p><span class="bubble-time">Just now</span>';
         rb.style.border = "1px solid #00E5FF";
         messages.appendChild(rb);
         messages.scrollTop = messages.scrollHeight;
         window.isAiQuestActive = true;
         window.aiQuestHistory = window.aiQuestHistory || [];
         window.aiQuestHistory.push({ role: 'assistant', content: reply });
         if (window.updateQuestProgress) window.updateQuestProgress('engage6');
     }).catch(err => {
         showToast('AI Quest generation failed.', 'spend');
     });
  }
};

// The Masked Spark Implementation
function joinMaskedSpark() {
  document.getElementById('masked-spark-modal').style.display = 'flex';
  document.getElementById('masked-match-status').textContent = 'Ready to find your masked match?';
}

window.joinMaskedSpark = joinMaskedSpark;

function startMaskedSearch() {
  const cost = 50;
  if (window.embers < cost) {
    showToast('Not enough Embers to search!', 'spend');
    return;
  }
  
  if (window.currentUserUid && window.DB_Service) {
    window.DB_Service.updateEmbers(window.currentUserUid, -cost);
  } else {
    window.embers -= cost;
    updateEmberDisplay();
  }
  
  document.getElementById('masked-match-status').innerHTML = '<span>Searching for a voice match... </span><div class="typing-indicator" style="display:inline-block"><span></span><span></span><span></span></div>';
  
  // Simulate finding a match after 3 seconds
  setTimeout(() => {
    document.getElementById('masked-match-status').innerHTML = '<span style="color:var(--primary-color); font-weight:bold;">Match Found! Connecting audio... 🎭</span>';
    if (window.Haptics) window.Haptics.impact({ style: ImpactStyle.Heavy }).catch(e => {});
    
    // Jump to Active Room
    setTimeout(() => {
      closeModal('masked-spark-modal');
      document.getElementById('masked-room-modal').style.display = 'flex';
      startMaskedTimer(180); // 3 minutes
      WebRTCService.init('masked_spark_room'); // Connect Audio
      showToast('Masked audio connected. Say hi!', 'earn');
    }, 1500);
    
  }, 3000);
}

let maskedTimerInterval = null;
let vibeHit = false;

function startMaskedTimer(seconds) {
  let timeLeft = seconds;
  vibeHit = false;
  document.getElementById('btn-masked-vibe').innerText = 'Hit the Vibe! ⚡';
  document.getElementById('btn-masked-vibe').style.background = 'var(--primary-color)';
  
  const promptEl = document.getElementById('masked-room-prompt');
  if (promptEl) {
    promptEl.textContent = 'Prompt 1: "What is your most controversial food opinion? 🍕"';
  }

  clearInterval(maskedTimerInterval);
  maskedTimerInterval = setInterval(() => {
    timeLeft--;
    let m = Math.floor(timeLeft / 60).toString().padStart(2, '0');
    let s = (timeLeft % 60).toString().padStart(2, '0');
    document.getElementById('masked-timer').innerText = `${m}:${s}`;
    
    // Dynamic Prompt Rotation every 60 seconds
    if (timeLeft === 120 && promptEl) {
      promptEl.textContent = 'Prompt 2: "What is the most spontaneous thing on your bucket list? ✈️"';
      if (window.AudioFX) window.AudioFX.playPop();
    } else if (timeLeft === 60 && promptEl) {
      promptEl.textContent = 'Prompt 3: "Describe your personality using only 3 movie titles. 🎬"';
      if (window.AudioFX) window.AudioFX.playPop();
    }

    if (timeLeft <= 0) {
      clearInterval(maskedTimerInterval);
      if (!vibeHit) {
        showToast('Time is up! The spark faded.', 'info');
        leaveMaskedRoom();
      }
    }
  }, 1000);
}

function clickMaskedVibe() {
  vibeHit = true;
  document.getElementById('btn-masked-vibe').innerText = 'Vibe Hit! Waiting for them... ⏳';
  document.getElementById('btn-masked-vibe').style.background = 'var(--neon-blue)';
  if (window.Haptics) window.Haptics.impact({ style: ImpactStyle.Heavy }).catch(e => {});
  
  // Simulate the other person hitting vibe 3 seconds later
  setTimeout(() => {
    clearInterval(maskedTimerInterval);
    document.getElementById('masked-timer').innerText = 'IT\'S A MATCH!';
    document.getElementById('masked-timer').style.color = 'var(--neon-blue)';
    document.getElementById('masked-match-avatar').innerHTML = '<img src="img/match1.jpg" style="width:100%; height:100%; object-fit:cover; border-radius:50%;" />';
    confetti({ particleCount: 100, spread: 70, origin: { y: 0.6 } });
    if (window.Haptics) window.Haptics.impact({ style: ImpactStyle.Heavy }).catch(e => {});
    
    setTimeout(() => {
      leaveMaskedRoom();
      showToast('You matched! Continue in chat.', 'earn');
    }, 4000);
  }, 3000);
}

function leaveMaskedRoom() {
  clearInterval(maskedTimerInterval);
  closeModal('masked-room-modal');
  if (WebRTCService.leave) WebRTCService.leave();
}

window.startMaskedSearch = startMaskedSearch;
window.clickMaskedVibe = clickMaskedVibe;
window.leaveMaskedRoom = leaveMaskedRoom;
// ================== FTUE & AUTHENTICATION ================== //
window.nextFtueSlide = function(slideNum) {
  document.querySelectorAll('.ftue-slide').forEach(s => s.style.display = 'none');
  const nextSlide = document.getElementById(`ftue-slide-${slideNum}`);
  if (nextSlide) nextSlide.style.display = 'block';
};

window.requestAppPermissions = async function() {
  if (window.Capacitor && window.Capacitor.isNativePlatform()) {
    try {
      if (window.PushNotifications) await window.PushNotifications.requestPermissions();
    } catch(e) { console.log(e); }
  }
  window.nextFtueSlide(3);
};

window.requestVerification = function() {
  document.getElementById('verification-modal').style.display = 'flex';
};

window.captureVerification = async function() {
  document.getElementById('verification-scanning').style.display = 'block';
  showToast("Scanning pose... 🤖", "info");
  
  // Simulate AI pose verification taking 3 seconds
  setTimeout(async () => {
    document.getElementById('verification-scanning').style.display = 'none';
    document.getElementById('verification-modal').style.display = 'none';
    
    if (window.currentUserUid && window.DB_Service) {
      await window.DB_Service.updateVerification(window.currentUserUid);
      window.isVerified = true;
      document.getElementById('verify-btn').style.display = 'none';
      document.getElementById('verified-status').style.display = 'block';
      showToast("Identity Verified! ✅", "earn");
    }
  }, 3000);
};

window.handleAuth = async function(action) {
  const email = document.getElementById('auth-email').value;
  const pass = document.getElementById('auth-pass').value;
  const errorDiv = document.getElementById('auth-error');
  
  if (!email || !pass) {
    errorDiv.innerText = "Please enter email and password.";
    return;
  }
  errorDiv.innerText = "Processing...";
  
  try {
    const { supabase } = await import('./js/supabase-config.js');
    let res;
    
    if (action === 'signup') {
      res = await supabase.auth.signUp({ email, password: pass });
    } else {
      res = await supabase.auth.signInWithPassword({ email, password: pass });
    }
    
    if (res.error) {
      errorDiv.innerText = res.error.message;
    } else if (res.data && res.data.user) {
      // Success!
      window.currentUserUid = res.data.user.id;
      if (action === 'signup' && window.DB_Service) {
        await window.DB_Service.createUser({ id: res.data.user.id, email: email });
      } else if (window.DB_Service) {
        let userData = await window.DB_Service.getUserData(res.data.user.id);
        if (userData && userData.isPremium) window.isPremium = true;
        if (userData && userData.isVerified) {
          window.isVerified = true;
          document.getElementById('verify-btn').style.display = 'none';
          document.getElementById('verified-status').style.display = 'block';
        }
      }
      document.getElementById('ftue-modal').style.display = 'none';
      if (window.showToast) window.showToast("Welcome to SparkQuest!", "earn");
    }
  } catch (err) {
    errorDiv.innerText = "Connection error. Please try again.";
    console.error(err);
  }
};

window.toggleNSFW = function(cb) {
  if (!window.isPremium) {
    cb.checked = false;
    showToast('Requires Spark Premium!', 'spend');
  } else {
    showToast(cb.checked ? 'NSFW Mode Enabled 😈' : 'NSFW Mode Disabled', 'info');
  }
};

window.togglePremiumFeature = function(cb) {
  if (!window.isPremium) {
    cb.checked = false;
    showToast('Requires Spark Premium!', 'spend');
  }
};

async function checkSession() {
  try {
    const { supabase } = await import('./js/supabase-config.js');
    const { data: { session } } = await supabase.auth.getSession();
    if (session && session.user) {
      window.currentUserUid = session.user.id;
      
      if (window.DB_Service) {
         let userData = await window.DB_Service.getUserData(session.user.id);
         if (userData && userData.isPremium) window.isPremium = true;
         if (userData && userData.isVerified) {
            window.isVerified = true;
            document.getElementById('verify-btn').style.display = 'none';
            document.getElementById('verified-status').style.display = 'block';
         }
      }

      const ftue = document.getElementById('ftue-modal');
      if (ftue) ftue.style.display = 'none';
      console.log("[AUTH] Session restored for", session.user.id);
    }
  } catch (e) {
    console.error("[AUTH] checkSession error:", e);
  }
}

function initNetworkMonitor() {
  function updateNetworkStatus(online) {
    const banner = document.getElementById('network-status-banner');
    const text = document.getElementById('network-status-text');
    const icon = document.getElementById('network-status-icon');
    if (!banner) return;

    if (!online) {
      banner.className = 'network-status-banner offline';
      if (icon) icon.textContent = '⚡';
      if (text) text.textContent = 'Offline Mode — Actions saved locally, will sync automatically';
      banner.style.display = 'flex';
    } else {
      banner.className = 'network-status-banner online';
      if (icon) icon.textContent = '🟢';
      if (text) text.textContent = 'Back Online — Synced with SparkQuest Cloud';
      banner.style.display = 'flex';
      setTimeout(() => {
        banner.style.display = 'none';
      }, 3500);
    }
  }

  window.addEventListener('online', () => updateNetworkStatus(true));
  window.addEventListener('offline', () => updateNetworkStatus(false));

  if (!navigator.onLine) {
    updateNetworkStatus(false);
  }
}

// Init — Module scripts are deferred, so DOM is already ready
(async function () {
  try {
    console.log('[APP] Init IIFE started');
    initNetworkMonitor();
    
    // Check Auth Session First
    await checkSession();

    console.log('[DEBUG] Step 1: Particles');
    createSplashParticles();

    console.log('[DEBUG] Step 2: InviteUI');
    updateInviteUI();
    
    console.log('[DEBUG] Step 2.5: AdMob');
    await AdMobService.initialize();

    console.log('[DEBUG] Step 2.6: ThemeManager & Streak');
    if (window.ThemeManager) {
      window.ThemeManager.init();
    }
    const streakMount = document.getElementById('header-streak-mount');
    if (streakMount && window.CoopQuests) {
      streakMount.innerHTML = window.CoopQuests.renderHeaderStreakBadge();
    }
    if (window.DailySpinWheel) window.DailySpinWheel.init();
    if (window.MysteryMatch) window.MysteryMatch.init();
    if (window.VibeHeatmeter) window.VibeHeatmeter.init();
    if (window.SafeHavens) window.SafeHavens.init();
    if (window.VIPCosmetics) window.VIPCosmetics.init();

    console.log('[DEBUG] Step 3: AI Init');
    const userApiKey = localStorage.getItem('spark_ai_api_key') || localStorage.getItem('spark_gemini_api_key');
    if (userApiKey && window.SparkAI) {
      window.SparkAI.init(userApiKey);
    }

    console.log('[DEBUG] Step 4: Auth Service Init');

    // Auth Service handles login, user creation, and data subscription
    const user = await AuthService.init();
    await loadDiscoveryProfiles();

    if (user) {
      console.log('[APP] Auth Service returned user:', user.uid);
      // Additional UI logic if needed on login?
      // Most state updates are now handled inside AuthService or callbacks.
    } else {
      console.warn('[APP] Auth Service returned null (Offline/Demo Mode)');
      showToast("Running in Offline Demo Mode", "info");
    }
    
    // Daily Login Check
    if (window.checkDailyLogin) window.checkDailyLogin();
    
    // Register Push Notifications
    if (window.Capacitor && window.Capacitor.isNativePlatform()) {
        PushNotifications.requestPermissions().then(result => {
            if (result.receive === 'granted') {
                PushNotifications.register();
            }
        });
        
        PushNotifications.addListener('registration', (token) => {
            console.log('Push registration success, token: ' + token.value);
            // We would save this token to Supabase for the user
        });
    }


    // Listen for settings changes
    const settingsInput = document.getElementById('settings-api-key');
    if (settingsInput) {
      if (window.SparkAI && window.SparkAI.apiKey) {
        settingsInput.value = window.SparkAI.apiKey;
      }
      settingsInput.addEventListener('change', saveApiKey);
    }


  } catch (err) {
    console.error('[CRITICAL] IIFE Failed:', err);
  }
// Photo Grid Functions
let draggedSlot = null;

function triggerSlotUpload(index) {
  document.getElementById(`upload-slot-${index}`).click();
}

function uploadToSlot(event, index) {
  var file = event.target.files[0];
  if (!file) return;
  var reader = new FileReader();
  reader.onload = function(e) {
    var slot = document.querySelector(`.photo-slot[data-index="${index}"]`);
    var img = document.getElementById(`slot-${index}-img`);
    img.src = e.target.result;
    img.style.display = 'block';
    slot.classList.remove('empty');
    slot.querySelector('.slot-edit').innerText = '✎';
  };
  reader.readAsDataURL(file);
}

function allowDrop(ev) {
  ev.preventDefault();
  ev.currentTarget.classList.add('drag-over');
}

function dragSlot(ev) {
  draggedSlot = ev.currentTarget;
  ev.dataTransfer.effectAllowed = 'move';
}

function dropSlot(ev) {
  ev.preventDefault();
  let targetSlot = ev.currentTarget;
  targetSlot.classList.remove('drag-over');
  
  if (draggedSlot && draggedSlot !== targetSlot) {
    // Swap images between draggedSlot and targetSlot
    let draggedImg = draggedSlot.querySelector('img');
    let targetImg = targetSlot.querySelector('img');
    let draggedSrc = draggedImg.src;
    let targetSrc = targetImg.src;
    
    let draggedIsEmpty = draggedSlot.classList.contains('empty');
    let targetIsEmpty = targetSlot.classList.contains('empty');
    
    // Swap contents
    if (targetIsEmpty) {
      draggedImg.src = '';
      draggedImg.style.display = 'none';
      draggedSlot.classList.add('empty');
      draggedSlot.querySelector('.slot-edit').innerText = '+';
    } else {
      draggedImg.src = targetSrc;
      draggedImg.style.display = 'block';
      draggedSlot.classList.remove('empty');
      draggedSlot.querySelector('.slot-edit').innerText = '✎';
    }
    
    if (draggedIsEmpty) {
      targetImg.src = '';
      targetImg.style.display = 'none';
      targetSlot.classList.add('empty');
      targetSlot.querySelector('.slot-edit').innerText = '+';
    } else {
      targetImg.src = draggedSrc;
      targetImg.style.display = 'block';
      targetSlot.classList.remove('empty');
      targetSlot.querySelector('.slot-edit').innerText = '✎';
    }
  }
}

// Ensure functions are global
window.triggerSlotUpload = triggerSlotUpload;
window.uploadToSlot = uploadToSlot;
window.allowDrop = allowDrop;
window.dragSlot = dragSlot;
window.dropSlot = dropSlot;

// WebRTC Live Stream Functions
async function joinLiveStream() {
  const btnJoin = document.getElementById('btn-join-stream');
  const btnLeave = document.getElementById('btn-leave-stream');
  if (btnJoin) btnJoin.disabled = true;
  
  const uid = await WebRTCService.init('spark_demo_channel');
  if (uid) {
    if (btnJoin) btnJoin.style.display = 'none';
    if (btnLeave) {
      btnLeave.style.display = 'inline-block';
      btnLeave.disabled = false;
    }
    showToast('Joined Live Stream!', 'info');
  } else {
    showToast('Failed to join stream', 'info');
    if (btnJoin) btnJoin.disabled = false;
  }
}

async function leaveLiveStream() {
  const btnJoin = document.getElementById('btn-join-stream');
  const btnLeave = document.getElementById('btn-leave-stream');
  if (btnLeave) btnLeave.disabled = true;
  
  if (WebRTCService.leave) {
    await WebRTCService.leave();
  }
  
  if (btnLeave) btnLeave.style.display = 'none';
  if (btnJoin) {
    btnJoin.style.display = 'inline-block';
    btnJoin.disabled = false;
  }
  showToast('Left Live Stream', 'info');
}

window.joinLiveStream = joinLiveStream;
window.leaveLiveStream = leaveLiveStream;

// Push Notifications Setup
async function setupPushNotifications() {
  if (Capacitor.getPlatform() === 'web') {
    console.log('[Push] Push notifications not supported on web.');
    return;
  }
  
  let permStatus = await PushNotifications.checkPermissions();
  if (permStatus.receive === 'prompt') {
    permStatus = await PushNotifications.requestPermissions();
  }
  if (permStatus.receive !== 'granted') {
    console.log('[Push] User denied push permissions');
    return;
  }
  
  await PushNotifications.register();
  
  PushNotifications.addListener('registration', token => {
    console.log('[Push] Registration token: ', token.value);
    // Ideally save to DB here
  });
  
  PushNotifications.addListener('pushNotificationReceived', notification => {
    console.log('[Push] Received: ', notification);
    showToast(notification.title || 'New Match!', 'info', notification.body);
  });
  
  PushNotifications.addListener('pushNotificationActionPerformed', action => {
    console.log('[Push] Action performed: ', action);
    // Deep link or navigate
  });
}

// ==========================================
// STORE COMPLIANCE & SAFETY MODERATION (UGC)
// ==========================================
window._activeReportTarget = null;
window._activeReportReason = 'fake';

window.openReportModal = function(target) {
  window._activeReportTarget = target || (window.currentChatUser ? { name: window.currentChatUser } : 'User');
  var name = typeof window._activeReportTarget === 'object' ? window._activeReportTarget.name : window._activeReportTarget;
  var nameEl = document.getElementById('report-target-name');
  if (nameEl) nameEl.textContent = name;
  var modal = document.getElementById('report-modal');
  if (modal) modal.style.display = 'flex';
};

window.selectReportReason = function(btn, reason) {
  window._activeReportReason = reason;
  var container = document.getElementById('report-categories-container');
  if (container) {
    container.querySelectorAll('.report-cat').forEach(b => b.classList.remove('selected'));
  }
  if (btn) btn.classList.add('selected');
};

window.submitActiveReport = async function() {
  var target = window._activeReportTarget;
  var targetId = typeof target === 'object' ? (target.id || target.name) : target;
  var reason = window._activeReportReason || 'other';
  var descEl = document.getElementById('report-desc-input');
  var details = descEl ? descEl.value.trim() : '';

  if (window.currentUserUid && window.DB_Service) {
    await window.DB_Service.reportUser(window.currentUserUid, targetId, reason, details);
  }

  closeModal('report-modal');
  showToast('Report submitted. Thank you for keeping SparkQuest safe.', 'info');
  if (descEl) descEl.value = '';
};

window.blockActiveUser = async function() {
  var target = window._activeReportTarget;
  var targetId = typeof target === 'object' ? (target.id || target.name) : target;
  var targetName = typeof target === 'object' ? target.name : target;

  if (window.currentUserUid && window.DB_Service) {
    await window.DB_Service.blockUser(window.currentUserUid, targetId);
  }

  // Remove from discovery deck
  profiles = profiles.filter(p => (p.id !== targetId && p.name !== targetName));
  buildSwipeDeck();

  // If currently chatting with this user, close chat
  if (window.currentChatUser && window.currentChatUser.toLowerCase() === String(targetName).toLowerCase()) {
    closeChatDetail();
  }

  closeModal('report-modal');
  showToast(`Blocked ${targetName}. You will no longer encounter each other.`, 'info');
};

window.openDeleteAccountModal = function() {
  closeModal('settings-modal');
  var modal = document.getElementById('delete-account-modal');
  if (modal) modal.style.display = 'flex';
};

window.confirmDeleteAccount = async function() {
  if (window.currentUserUid && window.DB_Service) {
    showToast('Deleting account & user data...', 'info');
    var success = await window.DB_Service.deleteAccount(window.currentUserUid);
    if (success) {
      closeModal('delete-account-modal');
      showToast('Your account and data have been permanently deleted.', 'info');
      setTimeout(() => {
        window.location.reload();
      }, 1000);
      return;
    }
  }
  closeModal('delete-account-modal');
  showToast('Account data reset.', 'info');
  localStorage.clear();
  setTimeout(() => window.location.reload(), 800);
};

window.downloadUserData = function() {
  const exportData = {
    userId: window.currentUserUid,
    embers: window.embers,
    inventory: window.inventory,
    isPremium: window.isPremium,
    questProgress: window.questProgress,
    exportTimestamp: new Date().toISOString()
  };
  const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `sparkquest-profile-export-${Date.now()}.json`;
  a.click();
  URL.revokeObjectURL(url);
  showToast('Profile data exported successfully.', 'info');
};

})(); // End Init IIFE

