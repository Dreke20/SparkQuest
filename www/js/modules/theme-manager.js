// SparkQuest Neon Theme Manager
import DB_Service from '../db-service.js';

export const THEMES = {
  'cyberpunk': {
    id: 'cyberpunk',
    name: 'Cyberpunk Neon',
    cost: 0,
    icon: '🌆',
    desc: 'The original electric violet & coral spark.',
    preview: 'linear-gradient(135deg, #7B2FFF, #FF3F6C)'
  },
  'tokyo-matrix': {
    id: 'tokyo-matrix',
    name: 'Tokyo Matrix',
    cost: 150,
    icon: '🟢',
    desc: 'High-tech emerald phosphor with digital glow.',
    preview: 'linear-gradient(135deg, #00FF66, #00FFCC)'
  },
  'solar-flare': {
    id: 'solar-flare',
    name: 'Solar Flare',
    cost: 200,
    icon: '🔥',
    desc: 'Intense golden hour amber and solar crimson.',
    preview: 'linear-gradient(135deg, #FF8800, #FFD700)'
  },
  'vaporwave': {
    id: 'vaporwave',
    name: 'Vaporwave Dream',
    cost: 250,
    icon: '🌸',
    desc: 'Dreamy retro-aesthetic lavender, cyan & magenta.',
    preview: 'linear-gradient(135deg, #B026FF, #FF6AD5)'
  }
};

export const ThemeManager = {
  currentTheme: localStorage.getItem('spark_active_theme') || 'cyberpunk',

  init() {
    this.applyTheme(this.currentTheme, false);
    this.renderThemeShop();
  },

  getUnlockedThemes() {
    try {
      const stored = localStorage.getItem('spark_unlocked_themes');
      return stored ? JSON.parse(stored) : ['cyberpunk'];
    } catch (e) {
      return ['cyberpunk'];
    }
  },

  isThemeUnlocked(themeId) {
    if (themeId === 'cyberpunk') return true;
    return this.getUnlockedThemes().includes(themeId);
  },

  applyTheme(themeId, notify = true) {
    if (!THEMES[themeId]) return;
    this.currentTheme = themeId;
    localStorage.setItem('spark_active_theme', themeId);

    if (themeId === 'cyberpunk') {
      document.documentElement.removeAttribute('data-theme');
    } else {
      document.documentElement.setAttribute('data-theme', themeId);
    }

    if (notify && typeof window.showToast === 'function') {
      window.showToast(`Equipped ${THEMES[themeId].name}! ✨`, 'info');
    }

    this.renderThemeShop();
  },

  async buyOrEquipTheme(themeId) {
    const theme = THEMES[themeId];
    if (!theme) return;

    if (this.isThemeUnlocked(themeId)) {
      this.applyTheme(themeId, true);
      return;
    }

    // Check Embers
    const balance = window.embers || 0;
    if (balance < theme.cost) {
      if (typeof window.showToast === 'function') {
        window.showToast(`Need ${theme.cost} Embers to unlock! (You have ${balance})`, 'spend');
      }
      return;
    }

    // Deduct Embers
    if (window.currentUserUid && DB_Service) {
      await DB_Service.updateEmbers(window.currentUserUid, -theme.cost);
      await DB_Service.unlockCosmetic(window.currentUserUid, `theme_${themeId}`);
    } else {
      window.embers -= theme.cost;
      if (typeof window.updateEmberDisplay === 'function') window.updateEmberDisplay();
    }

    const unlocked = this.getUnlockedThemes();
    if (!unlocked.includes(themeId)) {
      unlocked.push(themeId);
      localStorage.setItem('spark_unlocked_themes', JSON.stringify(unlocked));
    }

    if (typeof window.SoundService?.playReward === 'function') {
      window.SoundService.playReward();
    }
    if (typeof window.createParticles === 'function') {
      window.createParticles(window.innerWidth / 2, window.innerHeight / 2, 'confetti');
    }

    if (typeof window.showToast === 'function') {
      window.showToast(`Unlocked ${theme.name}! 🎨`, 'earn', `-${theme.cost}`);
    }

    this.applyTheme(themeId, false);
  },

  renderThemeShop() {
    const container = document.getElementById('theme-shop-grid');
    if (!container) return;

    const unlocked = this.getUnlockedThemes();
    container.innerHTML = '';

    Object.values(THEMES).forEach(theme => {
      const isOwned = unlocked.includes(theme.id);
      const isEquipped = this.currentTheme === theme.id;

      const card = document.createElement('div');
      card.className = `shop-item theme-item ${isEquipped ? 'highlight' : ''}`;
      card.onclick = () => this.buyOrEquipTheme(theme.id);
      card.style.position = 'relative';
      card.style.overflow = 'hidden';
      card.style.background = 'var(--bg-card)';
      card.style.border = isEquipped ? '2px solid var(--violet)' : '1px solid var(--glass-border)';

      card.innerHTML = `
        <div style="height: 40px; border-radius: 8px; margin-bottom: 8px; background: ${theme.preview}; box-shadow: 0 0 10px rgba(0,0,0,0.5);"></div>
        <span class="shop-item-name" style="font-weight: 700; font-size: 0.9em;">${theme.icon} ${theme.name}</span>
        <span class="shop-item-price" style="font-size: 0.8em; margin-top: 4px;">
          ${isEquipped ? '✓ Equipped' : isOwned ? 'Equip' : `<span class="ember-icon">✦</span> ${theme.cost} Embers`}
        </span>
        ${isEquipped ? '<span class="shop-item-badge" style="background:var(--violet);">Active</span>' : ''}
      `;
      container.appendChild(card);
    });
  }
};

window.ThemeManager = ThemeManager;
export default ThemeManager;
