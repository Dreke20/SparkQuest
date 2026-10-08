// Groq AI Service (Free Tier)
const SparkAI = {
    apiKey: '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',
    apiUrl: "https://api.groq.com/openai/v1/chat/completions",
    model: "llama3-8b-8192",

    init(key) {
        if (!key) return false;
        this.apiKey = key;
        localStorage.setItem('spark_ai_api_key', key);
        return true;
    },

    async callGroq(messages) {
        if (!this.apiKey) {
            console.error("No Groq API Key set.");
            return null;
        }

        try {
            const response = await fetch(this.apiUrl, {
                method: "POST",
                headers: {
                    "Authorization": `Bearer ${this.apiKey}`,
                    "Content-Type": "application/json"
                },
                body: JSON.stringify({
                    model: this.model,
                    messages: messages,
                    temperature: 0.7,
                })
            });
            const data = await response.json();
            return data.choices[0].message.content;
        } catch (e) {
            console.error("Groq API Error:", e);
            return null;
        }
    },

    async polishBio(currentBio) {
        const prompt = `Rewrite this dating app bio to be more witty, charming, and engaging. Keep it under 30 words. Bio: "${currentBio}"`;
        const result = await this.callGroq([{ role: "user", content: prompt }]);
        return result ? result.replace(/^"|"$/g, '').trim() : null;
    },

    async generateIcebreakers(profileName, interests) {
        const prompt = `Generate exactly 3 short, fun icebreaker messages for ${profileName} based on: ${interests.join(', ')}. Return ONLY a raw JSON array of 3 strings. Example: ["hi", "hello", "hey"]`;
        const result = await this.callGroq([{ role: "user", content: prompt }]);
        
        try {
            let text = result.replace(/```json|```/g, '').trim();
            return JSON.parse(text);
        } catch (e) {
            return ["Hey! love your vibe ✨", "What's the best adventure you've been on?", "Hi! We have so much in common!"];
        }
    },

    async generateReply(history, context) {
        const prompt = `Suggest exactly 3 short, engaging replies to the last message. Context: ${context}. History: ${JSON.stringify(history)}. Return ONLY a raw JSON array of 3 strings.`;
        const result = await this.callGroq([{ role: "user", content: prompt }]);

        try {
            let text = result.replace(/```json|```/g, '').trim();
            return JSON.parse(text);
        } catch (e) {
            return ["That's interesting! Tell me more.", "Haha, totally!", "I'd love to hear more about that."];
        }
    },

    async generateQuestStep(history, userAction) {
        const prompt = `You are a creative 'Quest Master' in a gamified dating app. The couple is on a multiplayer text adventure.
History of the quest: ${JSON.stringify(history)}
User's latest action: "${userAction}"
Write the next short, exciting narrative step (under 50 words) that pushes the story forward and gives them a fun, interactive choice to make together.`;
        
        const result = await this.callGroq([
            { role: "system", content: "You are a fun, witty narrator for a cooperative text-adventure game played by two people on a date. Keep it short and romantic/adventurous." },
            { role: "user", content: prompt }
        ]);
        return result || "The dragon blocks your path. Do you fight it together, or try to sneak past?";
    },

    async analyzeImage(base64Image) {
        // Groq does not support Vision in the free endpoints yet. 
        // We will simulate the Vibe Check based on random logic for now!
        console.warn("Groq vision not supported. Simulating Vibe Check.");
        return new Promise((resolve) => {
            setTimeout(() => {
                resolve({ safe: true, tags: ["adventurous", "verified", "stylish"], score: 0.92 });
            }, 1000);
        });
    }
};

window.SparkAI = SparkAI;

const savedKey = localStorage.getItem('spark_ai_api_key');
if (savedKey) {
    SparkAI.init(savedKey);
}
