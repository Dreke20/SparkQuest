"use client";

import { useState } from 'react';
import { motion, useMotionValue, useTransform, AnimatePresence } from 'framer-motion';
import { X, Heart, Settings, Hexagon } from 'lucide-react';

const PROFILES = [
  { id: 1, name: "Neon Alpha", age: 24, image: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=60", bio: "Ready for the next quest?" },
  { id: 2, name: "Cyber Queen", age: 22, image: "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop&q=60", bio: "Let's hack the matrix." },
  { id: 3, name: "Glitch", age: 26, image: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500&auto=format&fit=crop&q=60", bio: "Error 404: Love not found." }
];

export default function Home() {
  const [cards, setCards] = useState(PROFILES);
  
  // Swipe physics
  const x = useMotionValue(0);
  const rotate = useTransform(x, [-200, 200], [-15, 15]);
  const opacity = useTransform(x, [-200, -100, 0, 100, 200], [0, 1, 1, 1, 0]);

  const handleDragEnd = (event: any, info: any) => {
    if (info.offset.x > 100) {
      handleSwipe('right');
    } else if (info.offset.x < -100) {
      handleSwipe('left');
    }
  };

  const handleSwipe = (direction: 'left' | 'right') => {
    setCards((prev) => prev.slice(1));
    // Trigger Match or Reject logic here
  };

  return (
    <div className="flex flex-col h-full w-full relative bg-dark items-center justify-center p-4 pt-20">
      
      {/* Deck Filter */}
      <div className="absolute top-[80px] right-6 z-30">
        <select className="bg-black/60 border border-primary/30 text-white text-sm font-bold py-2 px-4 rounded-full outline-none backdrop-blur-md cursor-pointer hover:border-primary transition-colors">
          <option value="all">🔍 All Vibes</option>
          <option value="Foodie">🍣 Foodie</option>
          <option value="Gamer">🎮 Gamer</option>
          <option value="Fitness">🏋️ Fitness</option>
        </select>
      </div>

      {/* Swipe Deck */}
      <div className="relative w-full max-w-sm h-[460px] flex items-center justify-center mt-4">
        <AnimatePresence>
          {cards.map((profile, index) => {
            const isTop = index === 0;
            return (
              <motion.div
                key={profile.id}
                style={{ x: isTop ? x : 0, rotate: isTop ? rotate : 0, opacity: isTop ? opacity : 1 }}
                drag={isTop ? "x" : false}
                dragConstraints={{ left: 0, right: 0 }}
                onDragEnd={isTop ? handleDragEnd : undefined}
                initial={{ scale: 0.95, opacity: 0 }}
                animate={{ scale: isTop ? 1 : 0.95, opacity: 1, y: isTop ? 0 : index * 10 }}
                exit={{ x: x.get() > 0 ? 300 : -300, opacity: 0, transition: { duration: 0.2 } }}
                transition={{ type: "spring", stiffness: 300, damping: 20 }}
                className="absolute w-full h-full bg-[#222] rounded-[2rem] overflow-hidden shadow-2xl border border-white/10 cursor-grab active:cursor-grabbing origin-bottom"
              >
                <div className="absolute inset-0 bg-gradient-to-t from-black via-black/20 to-transparent z-10 pointer-events-none" />
                <img src={profile.image} alt={profile.name} className="absolute inset-0 w-full h-full object-cover" draggable={false} />
                
                {/* Profile Info */}
                <div className="absolute bottom-0 left-0 w-full p-8 z-20">
                  <h2 className="text-4xl font-black text-white drop-shadow-lg tracking-tight">
                    {profile.name} <span className="font-light opacity-80 text-3xl ml-1">{profile.age}</span>
                  </h2>
                  <p className="text-white/80 mt-2 text-lg font-medium">
                    {profile.bio}
                  </p>
                </div>
              </motion.div>
            );
          })}
        </AnimatePresence>
        
        {cards.length === 0 && (
          <div className="text-white/50 text-center animate-pulse">
            <Hexagon className="w-16 h-16 mx-auto mb-4 opacity-50" />
            <p className="text-xl font-bold tracking-widest">NO MORE SPARKS</p>
          </div>
        )}
      </div>

      {/* Action Buttons */}
      <div className="flex justify-center items-center gap-6 mt-8 z-20">
        <motion.button 
          whileTap={{ scale: 0.9 }}
          onClick={() => handleSwipe('left')}
          className="w-16 h-16 rounded-full bg-black/60 border border-white/10 flex items-center justify-center text-white/50 shadow-lg hover:bg-red-500/20 hover:text-red-500 transition-colors"
        >
          <X className="w-8 h-8" />
        </motion.button>
        <motion.button 
          whileTap={{ scale: 0.9 }}
          className="w-12 h-12 rounded-full bg-black/60 border border-white/10 flex items-center justify-center shadow-lg text-blue-400 hover:bg-blue-500/20 transition-colors"
        >
          <span className="text-xl">🧊</span>
        </motion.button>
        <motion.button 
          whileTap={{ scale: 0.9 }}
          onClick={() => handleSwipe('right')}
          className="w-20 h-20 rounded-full bg-gradient-to-br from-primary to-accent flex items-center justify-center text-white shadow-[0_0_30px_rgba(255,0,128,0.4)]"
        >
          <Heart className="w-10 h-10 fill-current" />
        </motion.button>
      </div>
    </div>
  );
}
