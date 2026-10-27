"use client";

import { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';

// Fix Leaflet's default icon path issues in React
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
});

// Custom Neon Icon
const neonIcon = new L.Icon({
  iconUrl: '/img/neon_drop_icon.png', // Fallback to standard if not found
  iconSize: [40, 40],
  iconAnchor: [20, 40],
  popupAnchor: [0, -40],
  className: 'neon-pulse-marker' // Custom CSS class we can add to globals
});

export default function MapComponent() {
  const [position, setPosition] = useState<[number, number]>([40.7128, -74.0060]); // NYC default

  useEffect(() => {
    // Attempt to get user geolocation
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => setPosition([pos.coords.latitude, pos.coords.longitude]),
        (err) => console.warn('Geolocation blocked:', err)
      );
    }
  }, []);

  return (
    <div className="w-full h-full rounded-[2rem] overflow-hidden shadow-[0_0_30px_rgba(255,0,128,0.2)] border border-primary/20 relative z-0">
      <MapContainer 
        center={position} 
        zoom={13} 
        style={{ height: '100%', width: '100%', background: '#121212' }}
        zoomControl={false}
      >
        <TileLayer
          url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
          attribution='&copy; OpenStreetMap contributors'
        />
        
        {/* User Location */}
        <Marker position={position}>
          <Popup className="dark-popup">
            <div className="text-black font-bold">You are here!</div>
          </Popup>
        </Marker>

        {/* Mock Neon Drop */}
        <Marker position={[position[0] + 0.01, position[1] + 0.01]}>
          <Popup>
            <div className="text-center text-black">
              <h3 className="font-bold text-primary mb-1">Cyber Club</h3>
              <p className="text-xs">Live Event in 10m!</p>
              <button className="mt-2 w-full py-1 bg-primary text-white font-bold rounded-full text-xs">
                JOIN
              </button>
            </div>
          </Popup>
        </Marker>
      </MapContainer>
    </div>
  );
}
