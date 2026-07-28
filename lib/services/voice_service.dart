import 'package:audio_session/audio_session.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final FlutterTts _tts = FlutterTts();
  AudioSession? _session;
  // Set by speak()'s optional onComplete for the currently in-flight
  // utterance only — cleared as soon as it fires, or whenever an utterance
  // ends some other way (cancelled/errored), so a stale callback can never
  // fire for an unrelated later utterance.
  void Function()? _pendingCompletion;

  Future<void> initialize() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    // Configures how the TTS engine's own output audio is routed/categorized.
    await _tts.setAudioAttributesForNavigation();

    // flutter_tts's own built-in focus request (used when speak() is called
    // with focus: true) always issues a bare AudioFocusRequest with no
    // AudioAttributes attached, using AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK.
    // Requesting focus ourselves via audio_session lets us attach the correct
    // navigation-guidance AudioAttributes to the focus request itself.
    _session = await AudioSession.instance;
    await _session!.configure(AudioSessionConfiguration(
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        usage: AndroidAudioUsage.assistanceNavigationGuidance,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
    ));

    // Release focus whenever an utterance ends, however it ends — finished
    // normally, cancelled by the next speak() call's stop(), or errored.
    // Deliberately not using awaitSpeakCompletion() for this: a call
    // interrupted by stop() (the normal case, since speak() always stops the
    // previous utterance first) isn't guaranteed to resolve its own
    // completion await, so relying on that could leave focus held
    // indefinitely. These handlers fire regardless of which call triggered
    // them, so completion-handler-driven callers (e.g. the arrival
    // announcement's deferred navigation) share this same handler rather
    // than each registering their own.
    _tts.setCompletionHandler(() {
      _session?.setActive(false);
      final completion = _pendingCompletion;
      _pendingCompletion = null;
      completion?.call();
    });
    _tts.setCancelHandler(() {
      _session?.setActive(false);
      _pendingCompletion = null;
    });
    _tts.setErrorHandler((message) {
      _session?.setActive(false);
      _pendingCompletion = null;
    });
  }

  // [onComplete], when given, fires once this exact utterance finishes
  // speaking (via the shared completion handler above) — not on being
  // interrupted/cancelled by a later speak() or stop() call.
  Future<void> speak(String text, {void Function()? onComplete}) async {
    // Cancel any in-progress speech first so announcements never overlap or queue.
    await _tts.stop();
    _pendingCompletion = onComplete;
    await _session?.setActive(true);
    // Small buffer delay: Android's audio focus grant is near-instant
    // and does not wait for the demoted app (e.g. Spotify) to actually
    // finish lowering its volume. There is no API that signals when
    // ducking has visibly taken effect, so this fixed delay is a
    // heuristic to reduce (not guarantee) the chance that TTS speech
    // starts before the music has audibly ducked. Adjust if testing
    // shows it's too short or noticeably too long.
    await Future.delayed(const Duration(milliseconds: 200));
    // focus: false — audio_session now owns the focus request (configured
    // above); letting flutter_tts also request its own focus would create
    // two independent, conflicting requests.
    await _tts.speak(text, focus: false);
  }

  void stop() {
    _pendingCompletion = null;
    _tts.stop();
    _session?.setActive(false);
  }

  void dispose() {
    _pendingCompletion = null;
    _tts.stop();
    _session?.setActive(false);
  }
}
