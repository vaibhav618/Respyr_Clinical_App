import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioHelper {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false; // Track playback state
  bool isMuted = false; // Track mute/unmute state

  Future<void> playAudio(String assetPath) async {
    if (isMuted) return;
    try {
      await _audioPlayer.setAsset(assetPath);
      _audioPlayer.play();
      isPlaying = true;
      // Reset `isPlaying` when audio finishes
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          isPlaying = false;
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error playing audio: $e');
      }
    }
  }

  void playInhaleAudio() {
    playAudio('assets/audio/inhale_1.mp3');
  }

  void playActivatingSensors() {
    playAudio('assets/audio/activating_sensons.mp3');
  }

  void playStartBreathTest() {
    playAudio('assets/audio/start_breath_test.mp3');
  }

  void playPlaceBreatheTube() {
    playAudio('assets/audio/place_tube.mp3');
  }

  void playExhaleAudio() {
    playAudio('assets/audio/exhale.mp3');
  }

  // Stop the audio
  void stopAudio() {
    _audioPlayer.pause();
    isPlaying = false;
  }

  // Mute or unmute the audio
  Future<void> toggleMute() async {
    if (isMuted) {
      await _audioPlayer.setVolume(1.0);
      isMuted = false;
    } else {
      await _audioPlayer.setVolume(0.0);
      isMuted = true;
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
