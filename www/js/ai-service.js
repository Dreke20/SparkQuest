// Spark AI Service
// Proxies AI wingman and image moderation exclusively through authenticated Supabase Edge Functions.

const SparkAI = {
    backendUrl: window.SPARK_CONFIG?.AI_BACKEND_URL || 'https://kqvjntbiagzywstijtsz.supabase.co/functions/v1/ai-wingman',
    moderationUrl: window.SPARK_CONFIG?.MODERATION_BACKEND_URL || 'https://kqvjntbiagzywstijtsz.supabase.co/functions/v1/moderate-content',

    init() {
        localStorage.removeItem('spark_ai_api_key');
        localStorage.removeItem('spark_gemini_api_key');
        return true;
    },

    async _authHeaders() {
        const headers = { 'Content-Type': 'application/json' };
        try {
            const client = window.supabaseClient || window.DB_Service?.getClient?.();
            if (client) {
                const { data: { session } } = await client.auth.getSession();
                if (session?.access_token) {
                    headers['Authorization'] = `Bearer ${session.access_token}`;
                }
            }
        } catch (_) {}
        return headers;
    },

    async callAI(messages) {
        if (!this.backendUrl) return null;
        try {
            const headers = await this._authHeaders();
            if (!headers['Authorization']) return null;
            const response = await fetch(this.backendUrl, {
                method: 'POST',
                headers,
                body: JSON.stringify({ messages })
            });
            if (response.ok) {
                const data = await response.json();
                if (data.content) return data.content;
            }
        } catch (err) {
            console.warn('[SparkAI] Edge proxy unavailable:', err);
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

    async analyzeImage(imageUrlOrData) {
        try {
            const headers = await this._authHeaders();
            if (!headers['Authorization']) {
                return { safe: false, reason: 'Authentication required for image moderation' };
            }
            const response = await fetch(this.moderationUrl, {
                method: 'POST',
                headers,
                body: JSON.stringify({ imageUrl: imageUrlOrData })
            });
            if (!response.ok) {
                return { safe: false, reason: 'Moderation check unavailable' };
            }
            const data = await response.json();
            return {
                safe: Boolean(data?.safe),
                reason: data?.reason || null,
                flagged: Array.isArray(data?.flaggedCategories) ? data.flaggedCategories : []
            };
        } catch (err) {
            return { safe: false, reason: 'Moderation check failed' };
        }
    }
};

window.SparkAI = SparkAI;
export default SparkAI;
