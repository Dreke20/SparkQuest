
export function createParticles(x, y, type = 'confetti') {
    const count = 30;
    const container = document.body;



    for (let i = 0; i < count; i++) {
        const p = document.createElement('div');
        p.classList.add('particle');
        p.style.zIndex = "200000";

        // Random visual properties
        const size = Math.random() * 8 + 4 + 'px';
        p.style.width = size;
        p.style.height = size;
        p.style.left = x + 'px';
        p.style.top = y + 'px';

        if (type === 'heart') {
            p.innerHTML = '❤️';
            p.style.backgroundColor = 'transparent';
            p.style.fontSize = Math.random() * 20 + 10 + 'px';
        } else {
            // Confetti colors
            const colors = ['#FF4B91', '#FF9E75', '#FFD166', '#06D6A0', '#118AB2'];
            p.style.backgroundColor = colors[Math.floor(Math.random() * colors.length)];
            p.style.borderRadius = Math.random() > 0.5 ? '50%' : '2px';
        }

        // Physics
        const angle = Math.random() * Math.PI * 2;
        const velocity = Math.random() * 150 + 50;
        const tx = Math.cos(angle) * velocity;
        const ty = Math.sin(angle) * velocity;
        const rotation = Math.random() * 720 - 360;

        p.style.setProperty('--tx', `${tx}px`);
        p.style.setProperty('--ty', `${ty}px`);
        p.style.setProperty('--rot', `${rotation}deg`);

        // Animation
        p.style.animation = `particle-explode 1s forwards ease-out`;

        container.appendChild(p);

        // Cleanup
        setTimeout(() => p.remove(), 1000);
    }
}

// Make it available globally for inline onclick handlers if needed
window.createParticles = createParticles;
