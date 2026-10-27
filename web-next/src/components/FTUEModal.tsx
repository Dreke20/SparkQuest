"use client";

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useAuth } from '@/lib/useAuth';

export default function FTUEModal() {
  const { user, loading, loginAnonymously } = useAuth();
  const [step, setStep] = useState(1);

  // If loading or already logged in, hide FTUE
  if (loading || user) return null;

  return (
    <div className="absolute inset-0 z-[99999] bg-black flex flex-col items-center justify-center text-center p-6" 
         style={{ background: 'linear-gradient(135deg, #0a0a0a, #1a1a1a)' }}>
      
      <AnimatePresence mode="wait">
        {step === 1 && (
          <motion.div 
            key="step1"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, x: -50 }}
            className="flex flex-col items-center w-full max-w-sm"
          >
            <div className="w-32 h-32 rounded-[2rem] border-2 border-primary/50 shadow-[0_0_40px_rgba(255,0,128,0.4)] mb-8 overflow-hidden flex items-center justify-center">
              <img src="/img/logo.jpg" alt="SparkQuest Logo" className="w-full h-full object-cover" />
            </div>
            <h1 className="text-4xl font-black text-primary mb-4 tracking-tight">SparkQuest</h1>
            <p className="text-white/70 text-base mb-12 font-medium">Dating. Gaming. Streaming.<br/>All in one.</p>
            
            <button 
              onClick={() => setStep(2)}
              className="w-full py-4 bg-gradient-to-r from-primary to-accent rounded-full font-black text-white text-lg shadow-[0_0_20px_rgba(255,0,128,0.5)] hover:scale-105 transition-transform"
            >
              GET STARTED
            </button>
          </motion.div>
        )}

        {step === 2 && (
          <motion.div 
            key="step2"
            initial={{ opacity: 0, x: 50 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -50 }}
            className="flex flex-col items-center w-full max-w-sm"
          >
            <h2 className="text-3xl font-black text-blue-400 mb-8 drop-shadow-[0_0_10px_rgba(96,165,250,0.5)]">Permission Check</h2>
            
            <div className="w-full bg-white/5 p-4 rounded-2xl mb-3 text-left border border-white/5">
              <div className="font-bold text-white text-lg">📍 Location</div>
              <div className="text-white/50 text-sm">To find Neon Drops and local matches</div>
            </div>
            <div className="w-full bg-white/5 p-4 rounded-2xl mb-3 text-left border border-white/5">
              <div className="font-bold text-white text-lg">🎙️ Camera & Mic</div>
              <div className="text-white/50 text-sm">For Live Streaming and Masked Spark</div>
            </div>
            <div className="w-full bg-white/5 p-4 rounded-2xl mb-8 text-left border border-white/5">
              <div className="font-bold text-white text-lg">🔔 Notifications</div>
              <div className="text-white/50 text-sm">To get instantly notified of matches</div>
            </div>

            <button 
              onClick={() => setStep(3)}
              className="w-full py-4 bg-gradient-to-r from-blue-500 to-cyan-500 rounded-full font-black text-white text-lg shadow-[0_0_20px_rgba(59,130,246,0.5)] mb-4 hover:scale-105 transition-transform"
            >
              ALLOW ACCESS
            </button>
            <button 
              onClick={() => setStep(3)}
              className="text-white/40 font-bold hover:text-white transition-colors"
            >
              Skip for now
            </button>
          </motion.div>
        )}

        {step === 3 && (
          <motion.div 
            key="step3"
            initial={{ opacity: 0, x: 50 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, scale: 0.9 }}
            className="flex flex-col items-center w-full max-w-sm"
          >
            <h2 className="text-3xl font-black text-white mb-8">Create Account</h2>
            
            <input type="email" placeholder="Email Address" className="w-full p-4 mb-3 rounded-xl bg-white/10 border border-white/20 text-white placeholder-white/40 outline-none focus:border-primary transition-colors" />
            <input type="password" placeholder="Password" className="w-full p-4 mb-8 rounded-xl bg-white/10 border border-white/20 text-white placeholder-white/40 outline-none focus:border-primary transition-colors" />
            
            <button 
              onClick={() => alert('Signup form mock!')}
              className="w-full py-4 bg-gradient-to-r from-primary to-accent rounded-full font-black text-white text-lg shadow-[0_0_20px_rgba(255,0,128,0.5)] mb-4 hover:scale-105 transition-transform"
            >
              SIGN UP
            </button>
            <button 
              onClick={loginAnonymously}
              className="w-full py-4 border-2 border-primary rounded-full font-black text-primary text-lg hover:bg-primary/10 transition-colors"
            >
              GUEST LOGIN
            </button>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
