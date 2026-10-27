// SparkQuest Chat Mini-Games Engine (Two Sparks & a Lie, Vibe Duel)
import DB_Service from '../db-service.js';

const SAMPLE_FACTS = {
  sophia: [
    { text: "Hiked the Inca Trail to Machu Picchu at sunrise", isLie: false },
    { text: "Spends weekends photographing golden hour rooftops", isLie: false },
    { text: "Secretly drinks decaf coffee because caffeine makes me jittery", isLie: true }
  ],
  alex: [
    { text: "Built my first video game engine in high school", isLie: false },
    { text: "Can cook a authentic 5-course Italian feast from scratch", isLie: false },
    { text: "Never owned a mechanical keyboard or played Elden Ring", isLie: true }
  ],
  maya: [
    { text: "Certified hot yoga instructor with 500+ hours training", isLie: false },
    { text: "Traveled solo through Southeast Asia with just a backpack", isLie: false },
    { text: "Dislikes all matcha lattes and plant-based smoothies", isLie: true }
  ],
  jordan: [
    { text: "Produced a synthwave beat that surpassed 100k plays", isLie: false },
    { text: "Visited 15 indie film festivals in the last two years", isLie: false },
    { text: "Has never listened to Daft Punk or bought a vinyl record", isLie: true }
  ],
  default: [
    { text: "Once entered a city-wide spicy taco eating contest", isLie: false },
    { text: "Listened to over 60,000 minutes of music last year", isLie: false },
    { text: "Has never binge-watched a TV series in a single weekend", isLie: true }
  ]
};

const TRIVIA_QUESTIONS = [
  {
    q: "What's the undisputed best date night food?",
    options: ["Late Night Ramen 🍜", "Artisanal Pizza 🍕", "Tacos & Margaritas 🌮", "Sushi Boat 🍣"],
    answerIndex: 0,
    banter: "Late night ramen hits different every single time!"
  },
  {
    q: "Pick the ideal first date vibe:",
    options: ["Speakeasy with cozy booths 🍸", "Arcade bar & air hockey 🕹️", "Sunset walk with boba 🧋", "Record store hunting 🎵"],
    answerIndex: 1,
    banter: "Arcade bar competition brings out the best banter!"
  },
  {
    q: "A spontaneous road trip is planned — who controls the aux cord?",
    options: ["Whoever is driving 🚗", "Collaborative playlist only 🎧", "Passenger prince / princess 👑", "No music, deep podcasts only 🎙️"],
    answerIndex: 1,
    banter: "Collaborative playlists are the ultimate green flag."
  }
];

export const MiniGamesEngine = {
  currentMatch: null,
  activeGame: null,
  triviaIndex: 0,
  triviaScore: 0,

  openGamesModal(matchName) {
    this.currentMatch = matchName || window.currentChatUser || 'your match';
    const modal = document.getElementById('mini-game-modal');
    if (!modal) return;

    document.getElementById('mini-game-hub').style.display = 'block';
    document.getElementById('game-two-sparks').style.display = 'none';
    document.getElementById('game-trivia').style.display = 'none';
    modal.style.display = 'flex';
  },

  // GAME 1: Two Sparks & a Lie
  startTwoSparks() {
    this.activeGame = 'two_sparks';
    document.getElementById('mini-game-hub').style.display = 'none';
    const container = document.getElementById('game-two-sparks');
    container.style.display = 'block';

    const key = (this.currentMatch || '').toLowerCase();
    const facts = SAMPLE_FACTS[key] || SAMPLE_FACTS.default;

    // Shuffle statements
    const shuffled = [...facts].sort(() => Math.random() - 0.5);

    const cardsContainer = document.getElementById('two-sparks-cards');
    cardsContainer.innerHTML = '';

    document.getElementById('two-sparks-result').style.display = 'none';
    document.getElementById('two-sparks-header').textContent = `Which one is ${this.currentMatch}'s Lie?`;

    shuffled.forEach((item, index) => {
      const card = document.createElement('div');
      card.className = 'game-choice-card';
      card.style.cssText = 'background:var(--bg-card); border:1px solid var(--glass-border); border-radius:12px; padding:16px; margin-bottom:10px; cursor:pointer; transition:0.2s; text-align:left;';
      card.innerHTML = `<span style="font-weight:700; color:var(--cyan); margin-right:8px;">#${index + 1}</span> ${item.text}`;
      card.onclick = () => this.handleTwoSparksGuess(card, item.isLie, item.text);
      cardsContainer.appendChild(card);
    });
  },

  handleTwoSparksGuess(cardEl, isLie, text) {
    const allCards = document.querySelectorAll('#two-sparks-cards .game-choice-card');
    allCards.forEach(c => c.style.pointerEvents = 'none');

    const resultBox = document.getElementById('two-sparks-result');
    resultBox.style.display = 'block';

    if (isLie) {
      cardEl.style.borderColor = 'var(--cyan)';
      cardEl.style.background = 'rgba(0, 229, 255, 0.15)';
      resultBox.innerHTML = `
        <div style="font-size:2.5em; margin-bottom:8px;">🎯</div>
        <h3 style="color:var(--cyan); margin-bottom:6px;">Spark Mindreader!</h3>
        <p style="font-size:0.9em; color:#ddd; margin-bottom:15px;">You nailed it! That was indeed the lie! <strong>+35 Embers</strong> earned!</p>
        <button class="btn-primary" onclick="MiniGamesEngine.postGameResultToChat('sparks_win')">Send to Chat</button>
      `;

      if (window.currentUserUid && DB_Service) {
        DB_Service.updateEmbers(window.currentUserUid, 35);
      } else {
        window.embers = (window.embers || 0) + 35;
        if (typeof window.updateEmberDisplay === 'function') window.updateEmberDisplay();
      }

      if (typeof window.SoundService?.playReward === 'function') window.SoundService.playReward();
      if (typeof window.createParticles === 'function') window.createParticles(window.innerWidth / 2, window.innerHeight / 2, 'confetti');
    } else {
      cardEl.style.borderColor = 'var(--coral)';
      cardEl.style.background = 'rgba(255, 63, 108, 0.15)';
      resultBox.innerHTML = `
        <div style="font-size:2.5em; margin-bottom:8px;">🙈</div>
        <h3 style="color:var(--coral); margin-bottom:6px;">Fooled Ya!</h3>
        <p style="font-size:0.9em; color:#ddd; margin-bottom:15px;">That statement is actually 100% TRUE! Good guess though (+10 Embers for trying)!</p>
        <button class="btn-primary" onclick="MiniGamesEngine.postGameResultToChat('sparks_loss')">Share Reaction in Chat</button>
      `;

      if (window.currentUserUid && DB_Service) {
        DB_Service.updateEmbers(window.currentUserUid, 10);
      }
    }
  },

  // GAME 2: Trivia Vibe Duel
  startTrivia() {
    this.activeGame = 'trivia';
    this.triviaIndex = 0;
    this.triviaScore = 0;
    document.getElementById('mini-game-hub').style.display = 'none';
    document.getElementById('game-trivia').style.display = 'block';
    this.renderTriviaQuestion();
  },

  renderTriviaQuestion() {
    const qData = TRIVIA_QUESTIONS[this.triviaIndex];
    if (!qData) {
      this.finishTrivia();
      return;
    }

    document.getElementById('trivia-progress').textContent = `Question ${this.triviaIndex + 1} of ${TRIVIA_QUESTIONS.length}`;
    document.getElementById('trivia-question-text').textContent = qData.q;

    const optionsContainer = document.getElementById('trivia-options');
    optionsContainer.innerHTML = '';

    qData.options.forEach((opt, idx) => {
      const btn = document.createElement('button');
      btn.className = 'btn-secondary';
      btn.style.cssText = 'width:100%; margin-bottom:8px; text-align:left; padding:12px 16px; font-weight:600; font-size:0.95em;';
      btn.textContent = opt;
      btn.onclick = () => this.handleTriviaAnswer(idx, qData.answerIndex);
      optionsContainer.appendChild(btn);
    });
  },

  handleTriviaAnswer(chosenIndex, correctIndex) {
    if (chosenIndex === correctIndex) {
      this.triviaScore++;
    }
    this.triviaIndex++;
    this.renderTriviaQuestion();
  },

  finishTrivia() {
    const container = document.getElementById('game-trivia');
    const reward = this.triviaScore * 15 + 15;

    container.innerHTML = `
      <div style="text-align:center; padding:10px 0;">
        <div style="font-size:3em; margin-bottom:10px;">⚡</div>
        <h2 style="color:var(--gold);">Vibe Check Complete!</h2>
        <p style="font-size:1.1em; margin:10px 0;">Score: <strong>${this.triviaScore} / ${TRIVIA_QUESTIONS.length} Matches</strong></p>
        <p style="color:#aaa; font-size:0.9em; margin-bottom:20px;">You unlocked <strong>+${reward} Embers</strong> and a conversation spark card!</p>
        <button class="btn-primary" style="width:100%; margin-bottom:10px;" onclick="MiniGamesEngine.postGameResultToChat('trivia_done', ${this.triviaScore})">Send Results to Chat</button>
        <button class="btn-secondary" style="width:100%;" onclick="closeModal('mini-game-modal')">Close</button>
      </div>
    `;

    if (window.currentUserUid && DB_Service) {
      DB_Service.updateEmbers(window.currentUserUid, reward);
    } else {
      window.embers = (window.embers || 0) + reward;
      if (typeof window.updateEmberDisplay === 'function') window.updateEmberDisplay();
    }

    if (typeof window.SoundService?.playMatch === 'function') window.SoundService.playMatch();
    if (typeof window.createParticles === 'function') window.createParticles(window.innerWidth / 2, window.innerHeight / 2, 'confetti');
  },

  postGameResultToChat(type, score = 0) {
    let msgText = '';
    if (type === 'sparks_win') {
      msgText = `🎮 Just played Two Sparks & a Lie! I spotted your lie immediately 🎯 Let's see if you can guess mine next!`;
    } else if (type === 'sparks_loss') {
      msgText = `🎮 Just played Two Sparks & a Lie and you completely fooled me! Which one of those was actually true?! 😂`;
    } else if (type === 'trivia_done') {
      msgText = `⚡ Finished our Vibe Check Trivia with ${score}/3 score! We definitely need to compare notes on date spots 🍜`;
    }

    // Insert into chat
    const input = document.getElementById('chat-input');
    if (input) {
      input.value = msgText;
      if (typeof window.sendMessage === 'function') {
        window.sendMessage();
      }
    }

    if (typeof window.closeModal === 'function') {
      window.closeModal('mini-game-modal');
    }
  }
};

window.MiniGamesEngine = MiniGamesEngine;
export default MiniGamesEngine;
