import AgoraRTC from 'agora-rtc-sdk-ng';

const WebRTCService = {
  appId: 'aab8b8f5a8c24f6cb7d2f4d6d6b1d1f0', // Demo App ID (Replace with production in real app)
  client: null,
  localAudioTrack: null,
  localVideoTrack: null,
  isJoined: false,

  async init(channelName, token = null) {
    this.client = AgoraRTC.createClient({ mode: 'rtc', codec: 'vp8' });

    this.client.on('user-published', async (user, mediaType) => {
      await this.client.subscribe(user, mediaType);
      console.log('subscribe success');

      if (mediaType === 'video') {
        const remoteVideoTrack = user.videoTrack;
        const playerContainer = document.getElementById('remote-video-container');
        if (playerContainer) {
          const player = document.createElement('div');
          player.id = user.uid.toString();
          player.style.width = '100%';
          player.style.height = '100%';
          playerContainer.appendChild(player);
          remoteVideoTrack.play(player.id);
        }
      }
      if (mediaType === 'audio') {
        const remoteAudioTrack = user.audioTrack;
        remoteAudioTrack.play();
      }
    });

    this.client.on('user-unpublished', user => {
      const playerContainer = document.getElementById(user.uid.toString());
      if (playerContainer) {
        playerContainer.remove();
      }
    });

    try {
      const uid = await this.client.join(this.appId, channelName, token, null);
      
      this.localAudioTrack = await AgoraRTC.createMicrophoneAudioTrack();
      this.localVideoTrack = await AgoraRTC.createCameraVideoTrack();
      
      const localPlayer = document.getElementById('local-video-container');
      if (localPlayer) {
          this.localVideoTrack.play(localPlayer);
      }

      await this.client.publish([this.localAudioTrack, this.localVideoTrack]);
      console.log('publish success');
      this.isJoined = true;
      return uid;
    } catch (e) {
      console.error('Agora join failed', e);
      return null;
    }
  },

  async leave() {
    if (this.localAudioTrack) {
      this.localAudioTrack.close();
    }
    if (this.localVideoTrack) {
      this.localVideoTrack.close();
    }
    if (this.client) {
      await this.client.leave();
    }
    this.isJoined = false;
  }
};

export default WebRTCService;
window.WebRTCService = WebRTCService;
