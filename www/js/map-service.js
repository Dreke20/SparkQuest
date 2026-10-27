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
        L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png?key=cb1_4ero_1_181cc1dc4b739395458d2fff', {
            attribution: '&copy; OpenStreetMap &copy; CartoDB',
            subdomains: 'abcd',
            maxZoom: 19
        }).addTo(this.map);

        // Simulate User Movement
        this.simulateUserLocation();

        // Fix for map rendering inside hidden tabs/modals
        setTimeout(() => {
            this.map.invalidateSize();
        }, 100);
    },

    addMockDrops(baseLat, baseLng) {
        baseLat = baseLat || this.defaultLat;
        baseLng = baseLng || this.defaultLng;

        const drops = [
            { lat: baseLat + 0.0015, lng: baseLng + 0.0015, type: 'fire', value: 25 },
            { lat: baseLat - 0.0015, lng: baseLng - 0.0015, type: 'gem', value: 100 },
            { lat: baseLat + 0.0025, lng: baseLng - 0.0005, type: 'neon', value: 500 }
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
                    if (window.SafeHavensInstance) {
                        const vId = venue.name.toLowerCase().includes('skyline') ? 'venue_skyline' : 'venue_boathouse';
                        window.SafeHavensInstance.showVenue(vId);
                    } else if (window.showVenueInfo) {
                        window.showVenueInfo(venue.name);
                    }
                    
                    if (window.currentUserUid && window.DB_Service) {
                        window.DB_Service.saveCheckIn(window.currentUserUid, venue.name, venue.lat, venue.lng);
                    }
                });
        });
    },

    async fetchNearbyVenues(lat, lng) {
        try {
            // Overpass API query for bars, cafes, nightclubs around 2000m
            // Use 'nwr' (node, way, relation) and 'out center' to get points for building polygons
            const query = `[out:json];(nwr["amenity"~"cafe|bar|restaurant|pub|nightclub"](around:2000,${lat},${lng}););out center 15;`;
            
            const response = await fetch('https://overpass-api.de/api/interpreter', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                body: 'data=' + encodeURIComponent(query)
            });

            if (!response.ok) throw new Error('Overpass API returned ' + response.status);
            const data = await response.json();
            
            if (data && data.elements && data.elements.length > 0) {
                let foundVenues = 0;
                data.elements.forEach(el => {
                    if (el.tags && el.tags.name) {
                        let icon = "📍";
                        if (el.tags.amenity === 'cafe') icon = '☕';
                        if (el.tags.amenity === 'bar' || el.tags.amenity === 'pub') icon = '🍻';
                        if (el.tags.amenity === 'restaurant') icon = '🍽️';
                        if (el.tags.amenity === 'nightclub') icon = '🪩';

                        const customIcon = L.divIcon({
                            className: 'custom-venue-pin',
                            html: `<div class="venue-icon">${icon}</div><div class="venue-label">${el.tags.name}</div>`,
                            iconSize: [120, 40],
                            iconAnchor: [60, 40]
                        });
                        
                        const vLat = el.lat || (el.center && el.center.lat);
                        const vLon = el.lon || (el.center && el.center.lon);

                        if (vLat && vLon) {
                            foundVenues++;
                            L.marker([vLat, vLon], { icon: customIcon }).addTo(this.map)
                                .on('click', () => {
                                    if (window.showVenueInfo) window.showVenueInfo(el.tags.name);
                                    
                                    if (window.currentUserUid && window.DB_Service) {
                                        window.DB_Service.saveCheckIn(window.currentUserUid, el.tags.name, vLat, vLon);
                                        if (window.showToast) window.showToast(`Checked in to ${el.tags.name}! 🗺️`, 'info');
                                        if (window.updateQuestProgress) window.updateQuestProgress('engage4');
                                    }
                                });
                        }
                    }
                });
                
                // If the elements didn't have names or lat/lon
                if (foundVenues === 0) {
                    this.addMockVenues(lat, lng);
                }
            } else {
                this.addMockVenues(lat, lng);
            }
        } catch (e) {
            console.error('Failed to fetch nearby venues:', e);
            this.addMockVenues(lat, lng); // Fallback
        }
    },

    addMockVenues(baseLat, baseLng) {
        // If not provided, fallback to default NYC
        baseLat = baseLat || this.defaultLat;
        baseLng = baseLng || this.defaultLng;
        
        const venues = [
            { lat: baseLat + 0.001, lng: baseLng - 0.002, name: "Skyline Lounge", icon: "🍸" },
            { lat: baseLat - 0.002, lng: baseLng + 0.001, name: "The Boathouse", icon: "⛵" },
            { lat: baseLat + 0.002, lng: baseLng + 0.002, name: "Neon Cafe", icon: "☕" }
        ];

        venues.forEach(venue => {
            const customIcon = L.divIcon({
                className: 'custom-venue-pin',
                html: `<div class="venue-icon">${venue.icon}</div><div class="venue-label">${venue.name}</div>`,
                iconSize: [120, 40],
                iconAnchor: [60, 40]
            });

            L.marker([venue.lat, venue.lng], { icon: customIcon }).addTo(this.map)
                .on('click', () => {
                    if (window.showVenueInfo) window.showVenueInfo(venue.name);
                    
                    if (window.currentUserUid && window.DB_Service) {
                        window.DB_Service.saveCheckIn(window.currentUserUid, venue.name, venue.lat, venue.lng);
                        if (window.showToast) window.showToast(`Checked in to ${venue.name}! 🗺️`, 'info');
                        if (window.updateQuestProgress) window.updateQuestProgress('engage4');
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
            this.fetchNearbyVenues(lat, lng);
            this.addMockDrops(lat, lng);
            this.loadLiveHeatmaps(lat, lng);
            this.watchProximity(lat, lng);
        } catch(e) {
            console.log("Geolocation error or running on web without permissions", e);
            this.fetchNearbyVenues(this.defaultLat, this.defaultLng);
            this.addMockDrops(this.defaultLat, this.defaultLng);
            this.loadLiveHeatmaps(this.defaultLat, this.defaultLng);
            this.watchProximity(this.defaultLat, this.defaultLng);
        }
    },

    refresh() {
        if (this.map) {
            setTimeout(() => {
                this.map.invalidateSize();
            }, 100);
        }
    },
    
    loadLiveHeatmaps(baseLat, baseLng) {
        if (!this.map) return;
        
        baseLat = baseLat || this.defaultLat;
        baseLng = baseLng || this.defaultLng;

        // Mock stunning heat spots for visual demo
        const heatSpots = [
            { lat: baseLat, lng: baseLng + 0.0002, intensity: 0.8 },
            { lat: baseLat + 0.0015, lng: baseLng - 0.0015, intensity: 0.5 },
            { lat: baseLat - 0.002, lng: baseLng + 0.003, intensity: 0.9 },
            { lat: baseLat - 0.0005, lng: baseLng - 0.0025, intensity: 0.7 }
        ];

        if (typeof L.heatLayer === 'function') {
            const heatData = heatSpots.map(spot => [spot.lat, spot.lng, spot.intensity * 20]); // Leaflet heat uses intensity roughly 0.1 to 1.0, but scaling it makes it more visible
            L.heatLayer(heatData, {
                radius: 50,
                blur: 40,
                maxZoom: 15,
                max: 1.0,
                gradient: {0.3: 'blue', 0.5: 'cyan', 0.7: 'lime', 0.8: 'yellow', 1.0: 'red'}
            }).addTo(this.map);
        } else {
            // Fallback if plugin fails to load
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
        }

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
    },

    watchProximity(lat, lng) {
        // In a real app, this uses Capacitor Background Geolocation
        // Here we simulate walking closer to a Drop and firing an alert
        setInterval(() => {
            if (!this.userMarker) return;
            // Randomly trigger an alert for demo purposes
            if (Math.random() < 0.15) {
                if (window.showToast) {
                    window.showToast('📍 You are near a Neon Drop!', 'info', 'Tap to reveal');
                }
                if (window.Haptics) {
                    window.Haptics.impact({ style: 'Heavy' }).catch(()=>{});
                }
            }
        }, 15000); // Check every 15 seconds
    },

    pulseRadar() {
        if (!this.map) return;
        const center = this.userMarker ? this.userMarker.getLatLng() : this.map.getCenter();

        if (window.AudioFX) window.AudioFX.playRadarPing();
        if (window.Haptics) window.Haptics.impact({ style: 'Medium' }).catch(() => {});

        // Add expanding animated radar circle wave
        let currentRadius = 50;
        const radarWave = L.circle(center, {
            color: '#00E5FF',
            fillColor: '#00E5FF',
            fillOpacity: 0.25,
            weight: 2,
            radius: currentRadius
        }).addTo(this.map);

        const expandInterval = setInterval(() => {
            currentRadius += 75;
            radarWave.setRadius(currentRadius);
            radarWave.setStyle({
                fillOpacity: Math.max(0.01, 0.25 - (currentRadius / 1500) * 0.25),
                opacity: Math.max(0.05, 1 - (currentRadius / 1500))
            });

            if (currentRadius >= 1200) {
                clearInterval(expandInterval);
                this.map.removeLayer(radarWave);
            }
        }, 30);

        // Spawn 2 newly discovered bonus Ember drops near user
        setTimeout(() => {
            const offsets = [
                { dLat: 0.002, dLng: 0.0018, type: 'fire', value: 35 },
                { dLat: -0.0025, dLng: -0.0015, type: 'gem', value: 75 }
            ];
            offsets.forEach(off => {
                const dropLat = center.lat + off.dLat;
                const dropLng = center.lng + off.dLng;
                const iconHtml = off.type === 'fire' ? '🔥' : '💎';
                const pulseClass = off.type === 'fire' ? 'pulse-fire' : 'pulse-gem';

                const customIcon = L.divIcon({
                    className: `custom-map-pin ${pulseClass}`,
                    html: `<div class="pin-content">${iconHtml}</div>`,
                    iconSize: [40, 40],
                    iconAnchor: [20, 20]
                });

                const marker = L.marker([dropLat, dropLng], { icon: customIcon }).addTo(this.map);
                marker.on('click', () => {
                    if (window.claimMapDrop) {
                        window.claimMapDrop({ dataset: { value: off.value, type: off.type } });
                        this.map.removeLayer(marker);
                    }
                });
            });

            if (window.showToast) {
                window.showToast('📡 Radar Scan: 2 Ember Beacons revealed nearby!', 'earn', '+75🔥');
            }
        }, 600);
    }
};

export default MapService;
