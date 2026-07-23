import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final FlutterTts _tts = FlutterTts();

  Future<void> initialize() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    // Transient "duck" audio focus (lowers other apps' volume instead of
    // pausing them) — matches how turn-by-turn navigation apps announce
    // guidance over music/podcasts.
    await _tts.setAudioAttributesForNavigation();
  }

  Future<void> speak(String text) async {
    // Cancel any in-progress speech first so announcements never overlap or queue.
    await _tts.stop();
    // focus: true is required for the native side to actually request
    // AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK — without it, other apps' audio
    // is never ducked regardless of setAudioAttributesForNavigation().
    await _tts.speak(text, focus: true);
  }

  void stop() {
    _tts.stop();
  }

  void dispose() {
    _tts.stop();
  }
}
