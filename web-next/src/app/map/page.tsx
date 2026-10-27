"use client";

import dynamic from 'next/dynamic';
import { MapPin } from 'lucide-react';

// Dynamically import the map component with SSR disabled
const Map = dynamic(() => import('@/components/MapComponent'), {
  ssr: false,
  loading: () => (
    <div className="w-full h-full rounded-[2rem] bg-zinc-900 border border-white/5 flex flex-col items-center justify-center text-zinc-500 animate-pulse">
      <MapPin className="w-12 h-12 mb-4 opacity-50" />
      <p className="font-bold tracking-widest text-sm">INITIALIZING GPS...</p>
    </div>
  )
});

export default function MapPage() {
  return (
    <div className="flex flex-col h-full w-full bg-dark p-6 pt-12">
      {/* Header */}
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-3xl font-black text-primary drop-shadow-[0_0_10px_rgba(255,0,128,0.6)] tracking-tight">NEON DROPS</h1>
          <p className="text-white/50 text-sm font-medium mt-1">Discover live venues nearby</p>
        </div>
      </div>
      
      {/* Map Container - fills remaining space */}
      <div className="flex-1 w-full relative pb-[10px]">
        <Map />
      </div>
    </div>
  );
}
