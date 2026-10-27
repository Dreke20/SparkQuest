"use client";

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Flame, Gift, Sparkles, Crown } from 'lucide-react';
import { useAuth } from '@/lib/useAuth';
import { supabase } from '@/lib/supabase';

export default function ShopPage() {
  const { user, userData, loading, loginAnonymously, fetchUserData } = useAuth();
  const [isSpinning, setIsSpinning] = useState(false);
  const [result, setResult] = useState<string | null>(null);

  const handleSpin = async () => {
    if (isSpinning) return;
    
    if (!user) {
      alert("Please login first to use the shop!");
      return;
    }

    if (!userData || userData.embers < 150) {
      alert("Not enough Embers! You need 150 🔥");
      return;
    }

    setIsSpinning(true);
    setResult(null);
    
    // Deduct embers securely via RPC (Atomic Transaction)
    const { error } = await supabase.rpc('increment_embers', { user_id: user.id, amt: -150 });
    
    if (error) {
      console.error(error);
      alert("Transaction failed!");
      setIsSpinning(false);
      return;
    }

    // Refresh UI embers count
    fetchUserData(user.id);

    // Mock spin duration
    setTimeout(() => {
      setIsSpinning(false);
      setResult('SSR Legendary Match!');
    }, 2000);
  };

  return (
    <div className="flex flex-col h-full w-full bg-dark p-6 pt-24 overflow-y-auto">
      <h1 className="text-3xl font-black text-primary drop-shadow-[0_0_15px_rgba(255,0,128,0.6)] tracking-tight mb-6">SHOP</h1>


      {/* AdMob Integration Stub */}
      {user && (
        <motion.button 
          whileTap={{ scale: 0.95 }}
          onClick={async () => {
            alert("Playing Video Ad... (AdMob integration)");
            setTimeout(async () => {
              await supabase.rpc('increment_embers', { user_id: user.id, amt: 50 });
              fetchUserData(user.id);
              alert("You earned 50 🔥!");
            }, 1000);
          }}
          className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 rounded-2xl p-4 flex items-center justify-between shadow-lg mb-8"
        >
          <div className="flex items-center gap-3">
            <div className="bg-white/20 p-2 rounded-full">
              <Flame className="w-6 h-6 text-white" />
            </div>
            <div className="text-left">
              <h3 className="font-bold text-white">Earn Free Embers</h3>
              <p className="text-xs text-white/70">Watch a short ad to get +50 🔥</p>
            </div>
          </div>
          <span className="font-black text-white bg-black/30 px-3 py-1 rounded-full text-sm">PLAY</span>
        </motion.button>
      )}
      
      {/* Gacha Machine */}
      <div className="w-full relative max-w-sm mx-auto aspect-square bg-gradient-to-br from-[#1a1a1a] to-black rounded-[3rem] shadow-[0_0_40px_rgba(255,0,128,0.15)] border border-white/5 flex flex-col items-center justify-center mb-10 overflow-hidden">
        
        {/* Background glow */}
        <div className="absolute inset-0 bg-primary/5 blur-[80px] rounded-full pointer-events-none" />

        {/* Machine Screen */}
        <div className="relative w-48 h-48 bg-black rounded-full border-4 border-zinc-800 shadow-inner flex items-center justify-center overflow-hidden mb-6">
          <motion.div
            animate={{ 
              rotate: isSpinning ? 1080 : 0,
              scale: isSpinning ? [1, 0.8, 1.2, 1] : 1
            }}
            transition={{ duration: 2, ease: "easeInOut" }}
            className="text-7xl drop-shadow-[0_0_20px_rgba(255,255,255,0.5)]"
          >
            {result ? '✨' : '🔮'}
          </motion.div>
        </div>

        {/* Spin Button */}
        <motion.button 
          whileTap={{ scale: 0.95 }}
          onClick={handleSpin}
          disabled={isSpinning || !user}
          className={`relative px-8 py-4 rounded-full font-black text-xl tracking-widest shadow-2xl transition-all ${
            isSpinning || !user
            ? 'bg-zinc-800 text-zinc-500 scale-95' 
            : 'bg-gradient-to-r from-primary to-accent text-white shadow-primary/40 hover:shadow-primary/60 hover:scale-105'
          }`}
        >
          {isSpinning ? 'SPINNING...' : 'SPIN - 150 🔥'}
        </motion.button>

        {/* Result Text */}
        <AnimatePresence>
          {result && (
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="absolute top-6 font-black text-xl text-accent drop-shadow-[0_0_10px_rgba(255,140,0,0.8)] text-center w-full"
            >
              {result}
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Item Store */}
      <h3 className="text-lg font-bold text-white mb-4 px-2">Premium Items</h3>
      <div className="w-full grid grid-cols-2 gap-4 pb-8">
        {[
          { id: 1, name: 'Profile Boost', icon: <Flame />, price: 500, color: 'text-primary' },
          { id: 2, name: 'Mystery Box', icon: <Gift />, price: 800, color: 'text-purple-400' },
          { id: 3, name: 'Super Spark', icon: <Sparkles />, price: 1200, color: 'text-blue-400' },
          { id: 4, name: 'VIP Pass', icon: <Crown />, price: 5000, color: 'text-yellow-400' },
        ].map((item) => (
          <motion.div 
            key={item.id} 
            whileHover={{ y: -5 }}
            whileTap={{ scale: 0.95 }}
            className="bg-black/40 p-5 rounded-3xl border border-white/5 flex flex-col items-center gap-3 cursor-pointer backdrop-blur-md"
          >
            <div className={`w-16 h-16 bg-zinc-900 rounded-full flex items-center justify-center shadow-inner ${item.color}`}>
              {item.icon}
            </div>
            <div className="text-center">
              <span className="font-bold text-sm block text-white/90">{item.name}</span>
              <span className="text-primary text-xs font-black">{item.price} 🔥</span>
            </div>
          </motion.div>
        ))}
      </div>
    </div>
  );
}
