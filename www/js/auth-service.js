import { supabase } from './supabase-config.js';
import DB_Service from './db-service.js';

const AuthService = {
    init() {
        return new Promise(async (resolve) => {
            console.log('[AuthService] Initializing Supabase Auth...');

            const { data: { session }, error } = await supabase.auth.getSession();
            if (session?.user) {
                console.log('[AuthService] User signed in:', session.user.id);
                await this.handleUserLogin(session.user);
                resolve(session.user);
            } else {
                console.log('[AuthService] No user, signing in anonymously...');
                const user = await this.signIn();
                resolve(user);
            }

            // Setup listener
            supabase.auth.onAuthStateChange(async (event, session) => {
                if (event === 'SIGNED_IN' && session?.user) {
                    await this.handleUserLogin(session.user);
                }
            });
        });
    },

    async signIn() {
        try {
            // Note: You must enable Anonymous Sign-Ins in your Supabase dashboard (Authentication -> Providers)
            const { data, error } = await supabase.auth.signInAnonymously();
            if (error) throw error;
            return data.user;
        } catch (error) {
            console.error('[AuthService] Sign-in failed:', error);
            return null;
        }
    },

    async handleUserLogin(user) {
        window.currentUserUid = user.id;

        // Ensure user doc exists
        await DB_Service.createUser(user);

        // Subscribe to data
        DB_Service.subscribeToUserData(user.id, (data) => {
            if (data) {
                window.embers = data.embers || 325;
                window.inventory = data.inventory || { boost: 2, superlike: 5 };
                window.questProgress = data.questProgress;
                window.isPremium = data.isPremium;

                // Trigger UI updates if function exists
                if (typeof window.updateEmberDisplay === 'function') {
                    window.updateEmberDisplay();
                }
            }
        });

        // Trigger Login Reward if conditions met
        if (localStorage.getItem('spark_legal_accepted') && typeof window.showLoginReward === 'function') {
            // Check if we should show it
        }
    }
};

export default AuthService;
