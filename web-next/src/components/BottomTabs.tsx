"use client";

import { usePathname, useRouter } from 'next/navigation';
import { Flame, Map, MessageCircleHeart, Store, User } from 'lucide-react';

export default function BottomTabs() {
  const pathname = usePathname();
  const router = useRouter();

  const tabs = [
    { id: '/', icon: <Flame className="w-6 h-6" />, label: 'Sparks' },
    { id: '/map', icon: <Map className="w-6 h-6" />, label: 'Neon' },
    { id: '/matches', icon: <MessageCircleHeart className="w-6 h-6" />, label: 'Matches' },
    { id: '/shop', icon: <Store className="w-6 h-6" />, label: 'Shop' },
    { id: '/profile', icon: <User className="w-6 h-6" />, label: 'Profile' }
  ];

  return (
    <nav className="fixed bottom-0 left-0 w-full h-[70px] bg-black/90 backdrop-blur-xl border-t border-white/5 flex justify-around items-center z-50">
      {tabs.map(tab => {
        const isActive = pathname === tab.id;
        return (
          <button 
            key={tab.id}
            onClick={() => router.push(tab.id)}
            className={`flex flex-col items-center justify-center w-full h-full space-y-1 transition-all ${
              isActive 
                ? 'text-primary scale-110 drop-shadow-[0_0_10px_rgba(255,0,128,0.8)]' 
                : 'text-white/40 hover:text-white/80'
            }`}
          >
            {tab.icon}
            <span className={`text-[10px] font-black tracking-widest ${isActive ? 'opacity-100' : 'opacity-0'}`}>
              {tab.label}
            </span>
          </button>
        );
      })}
    </nav>
  );
}
