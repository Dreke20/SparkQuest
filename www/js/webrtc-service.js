import AgoraRTC from 'agora-rtc-sdk-ng';

const WebRTCService = {
  appId: window.SPARK_CONFIG?.AGORA_APP_ID || localStorage.getItem('spark_agora_app_id') || 'aab8b8f5a8c24f6cb7d2f4d6d6b1d1f0',
  tokenUrl: window.SPARK_CONFIG?.AGORA_TOKEN_URL || null,
  client: null,
  localAudioTrack: null,
  localVideoTrack: null,
  isJoined: false,

  async fetchToken(channelName, uid) {
    if (!this.tokenUrl) return null;
    try {
      const response = await fetch(`${this.tokenUrl}?channel=${encodeURIComponent(channelName)}&uid=${encodeURIComponent(uid)}`);
      if (response.ok) {
        const data = await response.json();
        return data.token || null;
      }
    } catch (e) {
      console.warn('[WebRTCService] Token fetch failed, proceeding with fallback:', e);
    }
    return null;
  },

  async init(channelName, providedToken = null) {
    if (!channelName) return null;
    this.client = AgoraRTC.createClient({ mode: 'rtc', codec: 'vp8' });

    this.client.on('user-published', async (user, mediaType) => {
      try {
        await this.client.subscribe(user, mediaType);
        console.log('[WebRTCService] Remote user subscribed:', user.uid, mediaType);

        if (mediaType === 'video') {
          const remoteVideoTrack = user.videoTrack;
          const playerContainer = document.getElementById('remote-video-container');
          if (playerContainer) {
            let player = document.getElementById('remote-player-' + user.uid);
            if (!player) {
              player = document.createElement('div');
              player.id = 'remote-player-' + user.uid;
              player.style.width = '100%';
              player.style.height = '100%';
              playerContainer.appendChild(player);
            }
            remoteVideoTrack.play(player.id);
          }
        }
        if (mediaType === 'audio') {
          const remoteAudioTrack = user.audioTrack;
          remoteAudioTrack.play();
        }
      } catch (err) {
        console.error('[WebRTCService] Error subscribing to remote user:', err);
      }
    });

    this.client.on('user-unpublished', user => {
      const player = document.getElementById('remote-player-' + user.uid);
      if (player) player.remove();
    });

    try {
      const uidToUse = window.currentUserUid || Math.floor(Math.random() * 100000);
      const token = providedToken || (await this.fetchToken(channelName, uidToUse));
      const uid = await this.client.join(this.appId, channelName, token, uidToUse);
      
      this.localAudioTrack = await AgoraRTC.createMicrophoneAudioTrack();
      this.localVideoTrack = await AgoraRTC.createCameraVideoTrack();
      
      const localPlayer = document.getElementById('local-video-container');
      if (localPlayer) {
          this.localVideoTrack.play(localPlayer);
      }

      await this.client.publish([this.localAudioTrack, this.localVideoTrack]);
      console.log('[WebRTCService] Published local stream successfully');
      this.isJoined = true;
      return uid;
    } catch (e) {
      console.error('[WebRTCService] Agora join failed:', e);
      this.leave();
      return null;
    }
  },

  async leave() {
    try {
      if (this.localAudioTrack) {
        this.localAudioTrack.stop();
        this.localAudioTrack.close();
        this.localAudioTrack = null;
      }
      if (this.localVideoTrack) {
        this.localVideoTrack.stop();
        this.localVideoTrack.close();
        this.localVideoTrack = null;
      }
      if (this.client) {
        await this.client.leave();
      }
    } catch (err) {
      console.warn('[WebRTCService] Error leaving channel:', err);
    } finally {
      this.isJoined = false;
    }
  }
};

export default WebRTCService;
window.WebRTCService = WebRTCService;
