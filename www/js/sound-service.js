
const SoundService = {
    ctx: null,

    init() {
        if (!this.ctx) {
            this.ctx = new (window.AudioContext || window.webkitAudioContext)();
        }
    },

    playTone(freq, type, duration, vol = 0.1) {
        if (!this.ctx) this.init();
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();

        osc.type = type;
        osc.frequency.setValueAtTime(freq, this.ctx.currentTime);

        gain.gain.setValueAtTime(vol, this.ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, this.ctx.currentTime + duration);

        osc.connect(gain);
        gain.connect(this.ctx.destination);

        osc.start();
        osc.stop(this.ctx.currentTime + duration);
    },

    playSwipe(direction) {
        // Swoosh sound
        if (!this.ctx) this.init();
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();

        osc.frequency.setValueAtTime(direction === 'right' ? 300 : 200, this.ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(direction === 'right' ? 600 : 100, this.ctx.currentTime + 0.2);

        gain.gain.setValueAtTime(0.05, this.ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, this.ctx.currentTime + 0.2);

        osc.connect(gain);
        gain.connect(this.ctx.destination);

        osc.start();
        osc.stop(this.ctx.currentTime + 0.2);
    },

    playMatch() {
        // Major Chord Arpeggio (C Major: C, E, G, C)
        const now = this.ctx ? this.ctx.currentTime : 0;
        const notes = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6
        notes.forEach((freq, i) => {
            setTimeout(() => this.playTone(freq, 'sine', 0.4, 0.1), i * 100);
        });
    },

    playClick() {
        this.playTone(800, 'sine', 0.1, 0.05);
    },

    playError() {
        this.playTone(150, 'sawtooth', 0.3, 0.05);
    },

    playSuccess() {
        this.playTone(600, 'sine', 0.2, 0.1);
        setTimeout(() => this.playTone(800, 'sine', 0.4, 0.1), 100);
    }
};

export default SoundService;
