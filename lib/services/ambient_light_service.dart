import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:light/light.dart';

enum LightLevel { bright, normal, dark }

class AmbientLightService {
  static const double _brightThreshold = 1000;
  static const double _darkThreshold = 100;
  static const _debounceDuration = Duration(seconds: 2);

  final Light _light = Light();
  StreamSubscription<int>? _subscription;

  LightLevel _currentLevel = LightLevel.normal;
  LightLevel _pendingLevel = LightLevel.normal;
  Timer? _debounceTimer;

  final ValueNotifier<LightLevel> levelNotifier =
      ValueNotifier(LightLevel.normal);

  void start() {
    if (_subscription != null) return;
    try {
      _subscription = _light.lightSensorStream.listen(
        _onLux,
        onError: (Object e) {
          debugPrint('Ambient light sensor stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('Ambient light sensor not available: $e');
      // Sensor unavailable — stay at normal.
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  void dispose() {
    stop();
    levelNotifier.dispose();
  }

  void _onLux(int lux) {
    final newLevel = _luxToLevel(lux.toDouble());

    if (newLevel == _currentLevel) {
      // Back within the stable level — drop any pending change.
      _debounceTimer?.cancel();
      _debounceTimer = null;
      _pendingLevel = _currentLevel;
      return;
    }

    if (newLevel == _pendingLevel && _debounceTimer != null) {
      // Already debouncing towards this level — let the running timer finish
      // instead of restarting it on every reading.
      return;
    }

    _pendingLevel = newLevel;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _currentLevel = _pendingLevel;
      levelNotifier.value = _currentLevel;
    });
  }

  LightLevel _luxToLevel(double lux) {
    if (lux > _brightThreshold) return LightLevel.bright;
    if (lux < _darkThreshold) return LightLevel.dark;
    return LightLevel.normal;
  }
}
