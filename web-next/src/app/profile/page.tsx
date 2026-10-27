"use client";

import { useState } from 'react';
import { motion, Reorder } from 'framer-motion';
import { ShieldCheck, LogOut, Settings, Camera, Flame } from 'lucide-react';
import { useAuth } from '@/lib/useAuth';
import { supabase } from '@/lib/supabase';

const INITIAL_PHOTOS = [
  { id: '1', url: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&q=60' },
  { id: '2', url: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&q=60' },
  { id: '3', url: '' },
  { id: '4', url: '' },
  { id: '5', url: '' },
  { id: '6', url: '' },
];

export default function ProfilePage() {
  const { user, userData, loading, loginAnonymously } = useAuth();
  const [photos, setPhotos] = useState(INITIAL_PHOTOS);

  return (
    <div className="flex flex-col h-full w-full bg-dark p-6 pt-24 overflow-y-auto">
      {/* Header */}
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-black text-white tracking-tight">MY PROFILE</h1>
      </div>

      {/* User Info */}
      {loading ? (
        <div className="flex items-center gap-6 mb-8 animate-pulse text-white/50">Loading Identity...</div>
      ) : user ? (
        <div className="flex items-center gap-6 mb-8">
          <div className="relative">
            <div className="w-24 h-24 rounded-full bg-zinc-800 border-2 border-primary shadow-[0_0_20px_rgba(255,0,128,0.4)] overflow-hidden">
              <img src={photos[0].url} className="w-full h-full object-cover" />
            </div>
            <button className="absolute bottom-0 right-0 w-8 h-8 rounded-full bg-primary flex items-center justify-center border-2 border-black">
              <Camera className="w-4 h-4 text-white" />
            </button>
          </div>
          <div>
            <h2 className="text-2xl font-bold tracking-tight">Anonymous User</h2>
            <p className="text-white/60 font-medium text-xs font-mono">{user.id.split('-')[0]}</p>
            <div className="mt-2 inline-flex items-center gap-1 px-3 py-1 bg-green-500/10 text-green-400 text-xs font-bold rounded-full border border-green-500/30">
              <ShieldCheck className="w-3 h-3" />
              Verified User
            </div>
          </div>
        </div>
      ) : (
        <div className="flex flex-col items-center justify-center gap-4 mb-8 bg-black/40 p-6 rounded-3xl border border-white/5">
          <div className="text-white/50 text-center mb-2">You are currently playing as a guest.</div>
          <button onClick={loginAnonymously} className="w-full py-3 bg-gradient-to-r from-primary to-accent rounded-full font-bold shadow-[0_0_15px_rgba(255,0,128,0.5)]">
            LOGIN TO SAVE PROGRESS
          </button>
        </div>
      )}

      {/* Trust Score */}
      <div className="w-full bg-black/40 rounded-[2rem] p-6 border border-white/5 mb-8 backdrop-blur-md">
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-bold text-white flex items-center gap-2">
            Trust Score
          </h3>
          <span className="text-primary font-black text-xl">750</span>
        </div>
        <div className="w-full h-3 bg-zinc-900 rounded-full overflow-hidden border border-white/5">
          <motion.div 
            initial={{ width: 0 }}
            animate={{ width: '75%' }}
            transition={{ duration: 1, ease: "easeOut" }}
            className="h-full bg-gradient-to-r from-primary to-accent rounded-full relative"
          >
            <div className="absolute top-0 right-0 bottom-0 w-10 bg-gradient-to-l from-white/30 to-transparent"></div>
          </motion.div>
        </div>
        <div className="flex justify-between text-xs mt-2 text-white/40 font-medium">
          <span>Rookie</span>
          <span>Legend</span>
        </div>
      </div>

      {/* Photo Grid */}
      <div className="w-full bg-black/40 rounded-[2rem] p-6 border border-white/5 mb-8 backdrop-blur-md">
        <h3 className="text-lg font-bold text-white mb-6">Profile Photos <span className="text-white/40 text-sm font-normal">(Drag to reorder)</span></h3>
        
        <Reorder.Group axis="y" values={photos} onReorder={setPhotos} className="grid grid-cols-3 gap-3">
          {photos.map((photo) => (
            <Reorder.Item key={photo.id} value={photo} className="relative aspect-[3/4] rounded-2xl overflow-hidden bg-zinc-900 border border-white/5 cursor-grab active:cursor-grabbing">
              {photo.url ? (
                <>
                  <img src={photo.url} className="w-full h-full object-cover pointer-events-none" />
                  <div className="absolute bottom-2 right-2 w-6 h-6 rounded-full bg-black/50 backdrop-blur-md flex items-center justify-center border border-white/20">
                    <span className="text-[10px] font-bold">{photo.id}</span>
                  </div>
                </>
              ) : (
                <div className="w-full h-full flex items-center justify-center border-2 border-dashed border-white/10 rounded-2xl hover:border-primary/50 transition-colors">
                  <span className="text-2xl text-white/20">+</span>
                </div>
              )}
            </Reorder.Item>
          ))}
        </Reorder.Group>
      </div>
      
      {/* Footer Actions */}
      {user && (
        <button 
          onClick={() => supabase.auth.signOut()}
          className="w-full py-4 rounded-2xl bg-white/5 border border-white/10 text-red-400 font-bold flex items-center justify-center gap-2 hover:bg-red-500/10 transition-colors mb-10"
        >
          <LogOut className="w-5 h-5" />
          LOG OUT
        </button>
      )}
    </div>
  );
}
