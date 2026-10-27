"use client";

import { useAuth } from '@/lib/useAuth';
import { Flame, MessageCircle, Settings } from 'lucide-react';
import { usePathname } from 'next/navigation';

export default function TopBar() {
  const { user, userData } = useAuth();
  const pathname = usePathname();

  // Don't show top bar in the chat interface
  if (pathname === '/matches' && false) { // Assuming chat is full screen, we'll keep TopBar for now, or hide it dynamically
      return null;
  }

  return (
    <header className="absolute top-0 left-0 w-full h-[70px] bg-gradient-to-b from-black/90 to-transparent z-40 flex justify-between items-center px-4">
      <div className="flex items-center gap-2">
        <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-primary to-accent flex items-center justify-center shadow-[0_0_15px_rgba(255,0,128,0.5)] overflow-hidden">
          <img src="/img/logo.jpg" alt="Logo" className="w-full h-full object-cover" />
        </div>
        <span className="font-black text-xl tracking-tight text-white drop-shadow-md">
          Spark<span className="text-primary">Quest</span>
        </span>
      </div>

      <div className="flex items-center gap-3">
        {user ? (
          <div className="flex items-center gap-1.5 bg-black/50 border border-white/10 px-3 py-1.5 rounded-full backdrop-blur-md">
            <span className="text-primary text-sm">✦</span>
            <span className="font-bold text-white text-sm tracking-wider">{userData?.embers ?? 0}</span>
          </div>
        ) : null}
        <button className="w-10 h-10 rounded-full bg-black/50 border border-white/10 flex items-center justify-center backdrop-blur-md relative">
          <MessageCircle className="w-5 h-5 text-white" />
          <span className="absolute top-0 right-0 w-3 h-3 bg-primary rounded-full border-2 border-black"></span>
        </button>
      </div>
    </header>
  );
}
