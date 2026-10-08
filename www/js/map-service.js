import { Geolocation } from '@capacitor/geolocation';

const MapService = {
    map: null,
    userMarker: null,

    // Default location (Central Park, NY)
    defaultLat: 40.785091,
    defaultLng: -73.968285,

    init() {
        if (this.map) return; // Already initialized


        console.log('[MapService] Initializing Leaflet map...');
        const mapEl = document.getElementById('spark-map');
        console.log('[MapService] Target element:', mapEl);
        if (typeof L === 'undefined') {
            console.error('[MapService] Leaflet (L) is not defined. Map cannot be initialized.');
            if (mapEl) {
                mapEl.innerHTML = '<div style="display:flex;justify-content:center;align-items:center;height:100%;color:white;text-align:center;">' +
                    '<div><h3 style="margin:0 0 10px">Map Offline</h3><p style="font-size:14px;opacity:0.7">Unable to load map engine.<br>Please checks internet connection.</p></div></div>';
            }
            return;
        }

        // Initialize Map
        this.map = L.map('spark-map', {
            zoomControl: false, // We'll add custom controls if needed
            attributionControl: false
        }).setView([this.defaultLat, this.defaultLng], 15);

        // Dark Mode Map Tiles (CartoDB Dark Matter)
        L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
            attribution: '&copy; OpenStreetMap &copy; CartoDB',
            subdomains: 'abcd',
            maxZoom: 19
        }).addTo(this.map);

        // Mock Data
        this.addMockDrops();
        this.addMockVenues();

        // Simulate User Movement
        this.simulateUserLocation();
        
        // Load Live Heatmaps from DB
        this.loadLiveHeatmaps();

        // Fix for map rendering inside hidden tabs/modals
        setTimeout(() => {
            this.map.invalidateSize();
        }, 100);
    },

    addMockDrops() {
        const drops = [
            { lat: 40.7855, lng: -73.9685, type: 'fire', value: 25 },
            { lat: 40.7845, lng: -73.9665, type: 'gem', value: 100 },
            { lat: 40.7850, lng: -73.9680, type: 'neon', value: 500 } // IRL Neon Drop Event
        ];

        drops.forEach(drop => {
            const iconHtml = drop.type === 'fire' ? '🔥' : (drop.type === 'neon' ? '🎁' : '💎');
            const pulseClass = drop.type === 'fire' ? 'pulse-fire' : (drop.type === 'neon' ? 'pulse-neon' : 'pulse-gem');

            const customIcon = L.divIcon({
                className: `custom-map-pin ${pulseClass}`,
                html: `<div class="pin-content">${iconHtml}</div>`,
                iconSize: [40, 40],
                iconAnchor: [20, 20]
            });

            const marker = L.marker([drop.lat, drop.lng], { icon: customIcon }).addTo(this.map);

            marker.on('click', () => {
                if (window.claimMapDrop) {
                    window.claimMapDrop({ dataset: { value: drop.value, type: drop.type } });
                    this.map.removeLayer(marker); // Remove on claim
                }
            });
        });
    },

    addMockVenues() {
        const venues = [
            { lat: 40.7860, lng: -73.9650, name: "Skyline Lounge", icon: "🍸" },
            { lat: 40.7830, lng: -73.9690, name: "The Boathouse", icon: "⛵" }
        ];

        venues.forEach(venue => {
            const customIcon = L.divIcon({
                className: 'custom-venue-pin',
                html: `<div class="venue-icon">${venue.icon}</div><div class="venue-label">${venue.name}</div>`,
                iconSize: [120, 40],
                iconAnchor: [60, 40] // Bottom centerish
            });

            L.marker([venue.lat, venue.lng], { icon: customIcon }).addTo(this.map)
                .on('click', () => {
                    if (window.showVenueInfo) window.showVenueInfo(venue.name);
                    
                    if (window.currentUserUid && window.DB_Service) {
                        window.DB_Service.saveCheckIn(window.currentUserUid, venue.name, venue.lat, venue.lng);
                        // showToast isn't globally available here directly without window, so we assume it is
                        if (window.showToast) window.showToast(`Checked in to ${venue.name}! 🗺️`, 'info');
                    }
                });
        });
    },

    async simulateUserLocation() {
        const userIcon = L.divIcon({
            className: 'user-location-marker',
            html: '<div class="user-dot"></div><div class="user-radar"></div>',
            iconSize: [20, 20],
            iconAnchor: [10, 10]
        });

        this.userMarker = L.marker([this.defaultLat, this.defaultLng], { icon: userIcon }).addTo(this.map);
        
        try {
            // Get True Native GPS Location
            const position = await Geolocation.getCurrentPosition();
            const lat = position.coords.latitude;
            const lng = position.coords.longitude;
            
            // Update Marker and Map Center
            this.userMarker.setLatLng([lat, lng]);
            this.map.setView([lat, lng], 15);
        } catch(e) {
            console.log("Geolocation error or running on web without permissions", e);
        }
    },

    refresh() {
        if (this.map) {
            setTimeout(() => {
                this.map.invalidateSize();
            }, 100);
        }
    },
    
    loadLiveHeatmaps() {
        if (!this.map) return;
        
        // Mock stunning heat spots for visual demo
        const heatSpots = [
            { lat: 40.7850, lng: -73.9680, intensity: 0.8 },
            { lat: 40.7865, lng: -73.9695, intensity: 0.5 },
            { lat: 40.7830, lng: -73.9650, intensity: 0.9 },
            { lat: 40.7845, lng: -73.9710, intensity: 0.7 }
        ];

        heatSpots.forEach(spot => {
            L.circle([spot.lat, spot.lng], {
                color: '#ff3f6c',
                fillColor: '#ff3f6c',
                fillOpacity: spot.intensity * 0.4,
                radius: spot.intensity * 300,
                weight: 0,
                className: 'pulse-fire'
            }).addTo(this.map);
        });

        if (window.DB_Service && window.DB_Service.getRecentCheckIns) {
            window.DB_Service.getRecentCheckIns((checkins) => {
                if (!checkins) return;
                checkins.forEach(ci => {
                    L.circle([ci.lat, ci.lng], {
                        color: '#00e5ff',
                        fillColor: '#00e5ff',
                        fillOpacity: 0.3,
                        radius: 120,
                        stroke: false,
                        className: 'pulse-neon'
                    }).addTo(this.map);
                });
            });
        }
    }
};

export default MapService;
