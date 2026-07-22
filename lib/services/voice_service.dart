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
    await _tts.speak(text);
  }

  void stop() {
    _tts.stop();
  }

  void dispose() {
    _tts.stop();
  }
}
