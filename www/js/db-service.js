// Database Service - Handles all Supabase interactions & Store Compliance
import { supabase } from './supabase-config.js';

const DB_Service = {
    // User Profile Management
    async createUser(user, extraData = {}) {
        if (!supabase) return null;
        try {
            const { data: userSnap } = await supabase
                .from('users')
                .select('*')
                .eq('id', user.id)
                .single();

            if (!userSnap) {
                const defaultProfile = {
                    id: user.id,
                    email: user.email || "anonymous",
                    display_name: extraData.name || (user.email ? user.email.split('@')[0] : 'Explorer'),
                    age: extraData.age || 25,
                    bio: extraData.bio || 'On a quest for genuine sparks ✨',
                    photo_url: extraData.photo || 'img/alex.png',
                    tags: extraData.tags || ['Gaming', 'Coffee', 'Adventure'],
                    created_at: new Date().toISOString(),
                    embers: 325,
                    is_premium: false,
                    premium_tier: 'free',
                    is_verified: false,
                    inventory: { boost: 2, superlike: 5 },
                    quest_progress: {
                        engage1: { current: 7, target: 10, claimed: false },
                        engage2: { current: 1, target: 3, claimed: false },
                        engage3: { current: 1, target: 1, claimed: true },
                        engage4: { current: 0, target: 1, claimed: false },
                        engage5: { current: 0, target: 1, claimed: false },
                        engage6: { current: 0, target: 1, claimed: false }
                    }
                };

                const { data, error } = await supabase
                    .from('users')
                    .insert([defaultProfile])
                    .select()
                    .single();

                if (error) {
                    console.error('[DB_Service] Error creating user:', error);
                    return null;
                }
                return data;
            }
            return userSnap;
        } catch (err) {
            console.error('[DB_Service] Create user failed:', err);
            return null;
        }
    },

    async getUserData(uid) {
        if (!supabase || !uid) return null;
        try {
            const { data, error } = await supabase
                .from('users')
                .select('*')
                .eq('id', uid)
                .single();

            if (data) {
                return {
                    ...data,
                    isPremium: data.is_premium,
                    premiumTier: data.premium_tier,
                    isVerified: data.is_verified,
                    questProgress: data.quest_progress
                };
            }
        } catch (e) {
            console.warn('[DB_Service] Get user data failed:', e);
        }
        return null;
    },

    // Dynamic Discovery Feed (Live DB Users + Seeded Profiles)
    async getDiscoveryProfiles(currentUid, vibeFilter = 'all') {
        let liveProfiles = [];
        if (supabase && currentUid) {
            try {
                // Fetch blocked users and already swiped users to filter out
                const { data: swipes } = await supabase
                    .from('swipes')
                    .select('profile')
                    .eq('user_id', currentUid);

                const swipedIds = new Set((swipes || []).map(s => s.profile));

                const { data: blocks } = await supabase
                    .from('blocks')
                    .select('blocked_id')
                    .eq('blocker_id', currentUid);

                const blockedIds = new Set((blocks || []).map(b => b.blocked_id));

                const { data: dbUsers } = await supabase
                    .from('users')
                    .select('id, display_name, age, bio, photo_url, tags, is_verified')
                    .neq('id', currentUid)
                    .limit(20);

                if (dbUsers) {
                    liveProfiles = dbUsers
                        .filter(u => !swipedIds.has(u.id) && !blockedIds.has(u.id))
                        .map(u => ({
                            id: u.id,
                            name: u.display_name || 'Explorer',
                            age: u.age || 24,
                            photo: u.photo_url || 'img/alex.png',
                            detail: u.bio || 'Adventurer nearby',
                            tags: Array.isArray(u.tags) ? u.tags : ['✨ Vibes'],
                            compat: 'high',
                            compatPct: 85 + Math.floor(Math.random() * 12),
                            verified: u.is_verified || false,
                            voicePrompt: true,
                            isLiveUser: true
                        }));
                }
            } catch (err) {
                console.warn('[DB_Service] Live discovery query failed, falling back to seed:', err);
            }
        }

        return liveProfiles;
    },

    // Swiping & Mutual Matching
    async recordSwipe(uid, targetId, direction) {
        if (!supabase || !uid) return { is_match: false };
        try {
            const { data, error } = await supabase.rpc('record_swipe_and_check_match', {
                p_target_id: String(targetId),
                p_direction: direction
            });

            if (!error && data) {
                return data;
            }
        } catch (e) {
            console.warn('[DB_Service] record_swipe_and_check_match RPC unavailable, recording locally:', e);
        }

        // Direct table fallback
        try {
            await supabase.from('swipes').insert([{
                user_id: uid,
                profile: String(targetId),
                direction: direction,
                timestamp: new Date().toISOString()
            }]);
        } catch (err) {}

        return { is_match: false };
    },

    // Matches List
    async getUserMatches(uid) {
        if (!supabase || !uid) return [];
        try {
            const { data: matches, error } = await supabase
                .from('matches')
                .select('*')
                .or(`user1_id.eq.${uid},user2_id.eq.${uid}`)
                .eq('status', 'active');

            if (error || !matches) return [];

            const partnerIds = matches.map(m => m.user1_id === uid ? m.user2_id : m.user1_id);
            if (partnerIds.length === 0) return [];

            const { data: partners } = await supabase
                .from('users')
                .select('id, display_name, photo_url, is_verified')
                .in('id', partnerIds);

            return partners || [];
        } catch (e) {
            console.error('[DB_Service] Error fetching matches:', e);
            return [];
        }
    },

    // Updates
    async updateVerification(uid) {
        if (!supabase || !uid) return false;
        const { error } = await supabase
            .from('users')
            .update({ is_verified: true, updated_at: new Date().toISOString() })
            .eq('id', uid);
        return !error;
    },

    async updateEmbers(uid, amount) {
        if (!supabase || !uid) return;
        try {
            const { error } = await supabase.rpc('increment_embers', { user_id: uid, amt: amount });
            if (error) {
                // Fallback to direct update
                const user = await this.getUserData(uid);
                if (user) {
                    const newEmbers = Math.max(0, (user.embers || 0) + amount);
                    await supabase.from('users').update({ embers: newEmbers }).eq('id', uid);
                }
            }
        } catch (e) {
            console.error('[DB_Service] Error updating embers:', e);
        }
    },

    async updateInventory(uid, item, amount) {
        if (!supabase || !uid) return;
        const user = await this.getUserData(uid);
        if (user && user.inventory) {
            user.inventory[item] = Math.max(0, (user.inventory[item] || 0) + amount);
            await supabase.from('users').update({ inventory: user.inventory }).eq('id', uid);
        }
    },

    async setPremiumStatus(uid, isPremium, tier = 'gold') {
        if (!supabase || !uid) return;
        await supabase
            .from('users')
            .update({
                is_premium: isPremium,
                premium_tier: tier,
                updated_at: new Date().toISOString()
            })
            .eq('id', uid);
    },

    async updateQuest(uid, questId, progressData) {
        if (!supabase || !uid) return;
        const user = await this.getUserData(uid);
        if (user && user.questProgress) {
            user.questProgress[questId] = progressData;
            await supabase.from('users').update({ quest_progress: user.questProgress }).eq('id', uid);
        }
    },

    // Chat System
    async sendMessage(userId, partnerId, message) {
        if (!supabase || !userId) return;
        await supabase
            .from('messages')
            .insert([{
                user_id: userId,
                partner_id: String(partnerId),
                text: message.text,
                type: message.type || 'sent',
                timestamp: new Date().toISOString()
            }]);
    },

    subscribeToChat(userId, partnerId, callback) {
        if (!supabase || !userId) return () => {};

        const fetchMessages = () => {
            supabase.from('messages')
                .select('*')
                .or(`and(user_id.eq.${userId},partner_id.eq.${partnerId}),and(user_id.eq.${partnerId},partner_id.eq.${userId})`)
                .order('timestamp', { ascending: true })
                .limit(50)
                .then(({ data }) => {
                    if (data) callback(data);
                });
        };

        fetchMessages();

        const channel = supabase
            .channel(`chat_${userId}_${partnerId}`)
            .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages' }, () => {
                fetchMessages();
            })
            .subscribe();

        return () => supabase.removeChannel(channel);
    },

    subscribeToUserData(uid, callback) {
        if (!supabase || !uid) return () => {};

        this.getUserData(uid).then(data => {
            if (data) callback(data);
        });

        const channel = supabase
            .channel(`user_sync_${uid}`)
            .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'users', filter: `id=eq.${uid}` }, payload => {
                const data = payload.new;
                callback({
                    ...data,
                    isPremium: data.is_premium,
                    premiumTier: data.premium_tier,
                    questProgress: data.quest_progress
                });
            })
            .subscribe();

        return () => supabase.removeChannel(channel);
    },

    // Safety & Compliance (Report / Block / Account Deletion)
    async reportUser(reporterId, reportedId, reason, details = '') {
        if (!supabase || !reporterId) return false;
        try {
            const { error } = await supabase.from('reports').insert([{
                reporter_id: reporterId,
                reported_id: String(reportedId),
                reason: reason,
                details: details,
                created_at: new Date().toISOString()
            }]);
            return !error;
        } catch (e) {
            console.error('[DB_Service] Error reporting user:', e);
            return false;
        }
    },

    async blockUser(blockerId, blockedId) {
        if (!supabase || !blockerId) return false;
        try {
            const { error } = await supabase.from('blocks').insert([{
                blocker_id: blockerId,
                blocked_id: String(blockedId),
                created_at: new Date().toISOString()
            }]);
            return !error;
        } catch (e) {
            console.error('[DB_Service] Error blocking user:', e);
            return false;
        }
    },

    async deleteAccount(uid) {
        if (!supabase || !uid) return false;
        try {
            const { data, error } = await supabase.rpc('delete_user_account');
            if (!error && data) {
                await supabase.auth.signOut();
                localStorage.clear();
                return true;
            }
        } catch (e) {
            console.warn('[DB_Service] delete_user_account RPC error, trying direct deletion:', e);
        }

        try {
            await supabase.from('users').delete().eq('id', uid);
            await supabase.auth.signOut();
            localStorage.clear();
            return true;
        } catch (e) {
            console.error('[DB_Service] Account deletion failed:', e);
            return false;
        }
    },

    // Map & Media
    async saveCheckIn(uid, venueId, lat, lng) {
        if (!supabase || !uid) return;
        await supabase.from('map_checkins').insert([{
            user_id: uid,
            venue_id: venueId,
            lat: lat,
            lng: lng,
            timestamp: new Date().toISOString()
        }]);
    },

    async unlockCosmetic(uid, cosmeticName) {
        if (!supabase || !uid) return;
        const user = await this.getUserData(uid);
        if (user && user.inventory) {
            user.inventory[cosmeticName] = true;
            await supabase.from('users').update({ inventory: user.inventory }).eq('id', uid);
        }
    },

    async uploadVoicePrompt(uid, audioBlob) {
        if (!supabase || !uid) return null;
        try {
            const filePath = `${uid}/prompt.webm`;
            const { error } = await supabase.storage
                .from('voice_prompts')
                .upload(filePath, audioBlob, { upsert: true, contentType: 'audio/webm' });

            if (error) {
                console.error("[DB_Service] Audio upload error:", error);
                return null;
            }
            return this.getVoicePromptUrl(uid);
        } catch (err) {
            console.error("[DB_Service] Storage upload exception:", err);
            return null;
        }
    },

    getVoicePromptUrl(uid) {
        if (!supabase || !uid) return null;
        const { data } = supabase.storage
            .from('voice_prompts')
            .getPublicUrl(`${uid}/prompt.webm`);
        return data?.publicUrl || null;
    }
};

window.DB_Service = DB_Service;
export default DB_Service;
