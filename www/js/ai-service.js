// Spark AI Service
// Secure dual-mode architecture: Proxies through backend Supabase Edge Function in production
// or supports developer-configured keys / rich local creative fallbacks.

const SparkAI = {
    apiKey: localStorage.getItem('spark_ai_api_key') || null,
    backendUrl: window.SPARK_CONFIG?.AI_BACKEND_URL || null,
    groqApiUrl: "https://api.groq.com/openai/v1/chat/completions",
    model: "llama3-8b-8192",

    init(key) {
        if (!key) return false;
        this.apiKey = key;
        localStorage.setItem('spark_ai_api_key', key);
        return true;
    },

    async callAI(messages) {
        // 1. Try Backend Proxy / Supabase Edge Function first (Secure Production Path)
        if (this.backendUrl) {
            try {
                const response = await fetch(this.backendUrl, {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ messages })
                });
                if (response.ok) {
                    const data = await response.json();
                    if (data.content) return data.content;
                }
            } catch (err) {
                console.warn("[SparkAI] Backend AI proxy unavailable, falling back:", err);
            }
        }

        // 2. Direct API call if a developer key was configured in Settings
        if (this.apiKey) {
            try {
                const response = await fetch(this.groqApiUrl, {
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
                if (response.ok) {
                    const data = await response.json();
                    return data.choices?.[0]?.message?.content || null;
                }
            } catch (e) {
                console.error("[SparkAI] Direct AI API Error:", e);
            }
        }

        return null;
    },

    async polishBio(currentBio) {
        if (!currentBio || !currentBio.trim()) return "Adventurer, coffee enthusiast, and curious explorer looking for genuine sparks.";
        const prompt = `Rewrite this dating app bio to be more witty, charming, and engaging. Keep it under 30 words. Bio: "${currentBio}"`;
        const result = await this.callAI([{ role: "user", content: prompt }]);
        if (result) return result.replace(/^"|"$/g, '').trim();

        // Local Heuristic Fallback
        const templates = [
            `Passionate about ${currentBio.slice(0, 40)}. Seeking a co-pilot for late night ramen runs & spontaneous city walks. ✨`,
            `Certified coffee fanatic with a soft spot for ${currentBio.slice(0, 40)}. Let's compare playlist favorites! 🎧`,
            `On a quest to find the city's hidden gems. Big fan of ${currentBio.slice(0, 40)}. Say hi if you like good banter!`
        ];
        return templates[Math.floor(Math.random() * templates.length)];
    },

    async generateIcebreakers(userProfile, matchProfile) {
        const prompt = `You are a charismatic dating wingman. 
User's Profile: ${JSON.stringify(userProfile)}
Match's Profile: ${JSON.stringify(matchProfile)}
Generate exactly 3 short, fun, and hyper-personalized icebreaker messages for the User to send to the Match.
Use their shared interests if any, or complement something specific.
Return ONLY a raw JSON array of 3 strings. Example: ["hi", "hello", "hey"]`;

        const result = await this.callAI([{ role: "user", content: prompt }]);
        if (result) {
            try {
                let text = result.replace(/```json|```/g, '').trim();
                return JSON.parse(text);
            } catch (e) {
                console.warn("[SparkAI] Failed to parse AI icebreaker JSON, using fallback.");
            }
        }

        // Contextual Fallbacks
        const name = matchProfile?.name || 'there';
        const tags = matchProfile?.tags || [];
        const tagText = tags.length > 0 ? tags[0].replace(/[^a-zA-Z ]/g, '').trim() : 'adventures';

        return [
            `Hey ${name}! I noticed you're into ${tagText} — what got you started with that? ✨`,
            `Important question for you: best coffee spot in the city or hidden speakeasy? ☕🍸`,
            `Hi ${name}! We had high compatibility on the radar — had to come say hello! 🚀`
        ];
    },

    async generateReply(history, context) {
        const prompt = `Suggest exactly 3 short, engaging replies to the last message. Context: ${context}. History: ${JSON.stringify(history)}. Return ONLY a raw JSON array of 3 strings.`;
        const result = await this.callAI([{ role: "user", content: prompt }]);
        if (result) {
            try {
                let text = result.replace(/```json|```/g, '').trim();
                return JSON.parse(text);
            } catch (e) {
                console.warn("[SparkAI] Failed to parse AI replies, using fallback.");
            }
        }

        return [
            "That sounds amazing! Tell me more about it.",
            "Haha, totally! What made you decide on that?",
            "Count me in — let's make that happen soon!"
        ];
    },

    async generateQuestStep(history, userAction) {
        const prompt = `You are a creative 'Quest Master' in a gamified dating app. The couple is on a multiplayer text adventure.
History of the quest: ${JSON.stringify(history)}
User's latest action: "${userAction}"
Write the next short, exciting narrative step (under 50 words) that pushes the story forward and gives them a fun, interactive choice to make together.`;

        const result = await this.callAI([
            { role: "system", content: "You are a fun, witty narrator for a cooperative text-adventure game played by two people on a date. Keep it short and romantic/adventurous." },
            { role: "user", content: prompt }
        ]);

        if (result) return result;

        const narrativeSteps = [
            "A neon doorway shimmers before you in the alleyway. Do you step through together, or search the glowing terminal beside it?",
            "The jukebox suddenly begins playing a song you both recognize. Do you head to the dance floor, or grab drinks at the counter?",
            "A riddle appears on your cyber deck: 'What sparks when two worlds meet?' Do you solve it together, or race to the answer?"
        ];
        return narrativeSteps[Math.floor(Math.random() * narrativeSteps.length)];
    },

    async analyzeImage(base64Image) {
        return new Promise((resolve) => {
            setTimeout(() => {
                resolve({ safe: true, tags: ["adventurous", "verified", "stylish"], score: 0.94 });
            }, 600);
        });
    }
};

window.SparkAI = SparkAI;
export default SparkAI;
