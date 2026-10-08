// Database Service - Handles all Supabase interactions
import { supabase } from './supabase-config.js';

const DB_Service = {
    // User Management
    async createUser(user) {
        if (!supabase) return;
        const { data: userSnap, error } = await supabase
            .from('users')
            .select('*')
            .eq('id', user.id)
            .single();

        if (!userSnap) {
            // Create new user document with default values
            const { error: insertError } = await supabase
                .from('users')
                .insert([{
                    id: user.id,
                    email: user.email || "anonymous",
                    created_at: new Date().toISOString(),
                    embers: 325, // Default starting embers
                    is_premium: false,
                    inventory: {
                        boost: 2,
                        superlike: 5
                    },
                    quest_progress: {
                        engage1: { current: 7, target: 10, claimed: false },
                        engage2: { current: 1, target: 3, claimed: false },
                        engage3: { current: 1, target: 1, claimed: true }
                    }
                }]);
            return true;
        }
        return false; // User already exists
    },

    async getUserData(uid) {
        if (!supabase) return null;
        const { data, error } = await supabase
            .from('users')
            .select('*')
            .eq('id', uid)
            .single();
        if (data) {
            return {
                ...data,
                isPremium: data.is_premium,
                questProgress: data.quest_progress
            };
        }
        return null;
    },

    // Updates
    async updateEmbers(uid, amount) {
        if (!supabase) return;
        // Try to update by fetching current and adding. For production, consider using a Supabase RPC for atomic increment.
        const user = await this.getUserData(uid);
        if(user) {
            await supabase.from('users').update({ embers: user.embers + amount }).eq('id', uid);
        }
    },

    async updateInventory(uid, item, amount) {
        if (!supabase) return;
        const user = await this.getUserData(uid);
        if(user && user.inventory) {
            user.inventory[item] = (user.inventory[item] || 0) + amount;
            await supabase.from('users').update({ inventory: user.inventory }).eq('id', uid);
        }
    },

    async updateQuest(uid, questId, progressData) {
        if (!supabase) return;
        const user = await this.getUserData(uid);
        if(user && user.questProgress) {
            user.questProgress[questId] = progressData;
            await supabase.from('users').update({ quest_progress: user.questProgress }).eq('id', uid);
        }
    },

    // Chat System
    async sendMessage(userId, partnerId, message) {
        if (!supabase) return;
        await supabase
            .from('messages')
            .insert([{
                user_id: userId,
                partner_id: partnerId,
                ...message,
                timestamp: new Date().toISOString()
            }]);
    },

    subscribeToChat(userId, partnerId, callback) {
        if (!supabase) return;
        
        const fetchMessages = () => {
            supabase.from('messages')
                .select('*')
                .eq('user_id', userId)
                .eq('partner_id', partnerId)
                .order('timestamp', { ascending: true })
                .limit(50)
                .then(({data}) => {
                    if (data) callback(data);
                });
        };

        // Initial fetch
        fetchMessages();

        // Realtime subscription
        const channel = supabase
            .channel(`public:messages:user_id=eq.${userId}`)
            .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages', filter: `user_id=eq.${userId}` }, payload => {
                fetchMessages();
            })
            .subscribe();
            
        return () => supabase.removeChannel(channel);
    },

    // Global Listener for User Data (Embers, etc.)
    subscribeToUserData(uid, callback) {
        if (!supabase) return;
        
        // Initial fetch
        this.getUserData(uid).then(data => {
            if(data) callback(data);
        });

        // Realtime subscription
        const channel = supabase
            .channel(`public:users:id=eq.${uid}`)
            .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'users', filter: `id=eq.${uid}` }, payload => {
                const data = payload.new;
                callback({
                    ...data,
                    isPremium: data.is_premium,
                    questProgress: data.quest_progress
                });
            })
            .subscribe();
            
        return () => supabase.removeChannel(channel);
    },

    async recordSwipe(uid, profileName, direction) {
        if (!supabase) return;
        await supabase
            .from('swipes')
            .insert([{
                user_id: uid,
                profile: profileName,
                direction: direction,
                timestamp: new Date().toISOString()
            }]);
    },

    // 6. Map Checkins
    async saveCheckIn(uid, venueId, lat, lng) {
        if (!supabase) return;
        await supabase
            .from('map_checkins')
            .insert([{
                user_id: uid,
                venue_id: venueId,
                lat: lat,
                lng: lng,
                timestamp: new Date().toISOString()
            }]);
    },

    async getRecentCheckIns(callback) {
        if (!supabase) return;
        // Fetch last 100 checkins within 24h
        const { data } = await supabase
            .from('map_checkins')
            .select('*')
            .order('timestamp', { ascending: false })
            .limit(100);
        if (data) callback(data);
    },

    // 7. Cosmetics / Inventory
    async unlockCosmetic(uid, cosmeticName) {
        if (!supabase) return;
        const user = await this.getUserData(uid);
        if(user && user.inventory) {
            user.inventory[cosmeticName] = true;
            await supabase.from('users').update({ inventory: user.inventory }).eq('id', uid);
        }
    },

    // 8. Voice Prompt Storage
    async uploadVoicePrompt(uid, audioBlob) {
        if (!supabase) return null;
        const filePath = `${uid}/prompt.webm`;
        const { data, error } = await supabase.storage
            .from('voice_prompts')
            .upload(filePath, audioBlob, { upsert: true, contentType: 'audio/webm' });
        
        if (error) {
            console.error("Audio upload error:", error);
            return null;
        }
        return this.getVoicePromptUrl(uid);
    },

    getVoicePromptUrl(uid) {
        if (!supabase) return null;
        const { data } = supabase.storage
            .from('voice_prompts')
            .getPublicUrl(`${uid}/prompt.webm`);
        return data.publicUrl;
    }
};

window.DB_Service = DB_Service;
export default DB_Service;
