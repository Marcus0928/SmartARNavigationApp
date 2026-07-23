import 'package:flutter/foundation.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:smart_ar_navigation/core/enums/navigation_approach_stage.dart';
import 'package:smart_ar_navigation/core/enums/turn_direction.dart';
import 'package:smart_ar_navigation/core/utils/instruction_builder.dart';
import 'package:smart_ar_navigation/core/utils/location_utils.dart';
import 'package:smart_ar_navigation/models/route_model.dart';
import 'package:smart_ar_navigation/models/turn_instruction.dart';
import 'package:smart_ar_navigation/services/ar_service.dart';
import 'package:smart_ar_navigation/services/voice_service.dart';

enum VoiceAnnouncement { none, far1km, far200to1km, yellow, red }

class ARViewModel extends ChangeNotifier {
  final ARService _arService;
  final VoiceService _voiceService;

  ARViewModel({required ARService arService, VoiceService? voiceService})
      : _arService = arService,
        _voiceService = voiceService ?? VoiceService() {
    // Fire-and-forget: ARViewModel is constructed once at app startup, well
    // before a navigation session can start and any speak() call could fire.
    _voiceService.initialize();
  }

  TurnDirection? _nextTurnDirection;
  double? _distanceToNextTurn;
  String _instructionText = 'Continue';
  String? _currentStreetName;
  int? _roundaboutExit;
  bool _isARInitialized = false;
  List<TurnInstruction> _remainingTurns = [];
  double? _lastDistanceToNextTurn;
  TurnInstruction? _lastHeadTurn;
  bool _lookaheadActive = false;
  double? _closestApproachToHead;
  LatLng? _destinationCoordinates;
  VoiceAnnouncement _lastAnnounced = VoiceAnnouncement.none;
  bool voiceGuidanceEnabled = true;

  // TEMPORARY - remove after voice guidance testing is complete
  bool _debugOverrideActive = false;
  // TEMPORARY - remove after voice guidance testing is complete
  bool get debugOverrideActive => _debugOverrideActive;

  TurnDirection? get nextTurnDirection => _nextTurnDirection;
  double? get distanceToNextTurn => _distanceToNextTurn;
  String get instructionText => _instructionText;
  String? get currentStreetName => _currentStreetName;
  int? get roundaboutExit => _roundaboutExit;
  bool get isARInitialized => _isARInitialized;

  NavigationApproachStage get approachStage {
    final d = _distanceToNextTurn;
    if (d == null || d > 200) return NavigationApproachStage.far;
    if (d > 50) return NavigationApproachStage.approaching;
    return NavigationApproachStage.imminent;
  }

  Future<void> initializeAR(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
  ) async {
    _isARInitialized =
        await _arService.initializeAR(sessionManager, objectManager);
    notifyListeners();
  }


  Future<void> initializeOverlay(RouteModel route, {double? heading}) async {
    final newTurns = List<TurnInstruction>.from(route.turns);

    // Discard a phantom U-turn at step 1: Google may produce one when the
    // origin snaps to the wrong road side because no heading was available.
    // If we do have heading (driver is moving) and a subsequent step exists,
    // the U-turn is almost certainly spurious.
    if (newTurns.length > 1 &&
        newTurns.first.direction == TurnDirection.uTurn &&
        heading != null) {
      newTurns.removeAt(0);
    }

    // Rerouting (recalculateRoute/acceptFasterRoute) always hands us brand-new
    // TurnInstruction objects, even when the upcoming real-world turn hasn't
    // actually changed. If the new head turn matches the previous one by
    // direction and position, carry _lastHeadTurn forward so the next
    // updateAROverlay() tick doesn't see a reference mismatch, reset
    // _lastAnnounced, and re-speak the announcement mid-utterance.
    if (newTurns.isNotEmpty && _lastHeadTurn != null) {
      final newHead = newTurns.first;
      final sameTurn = newHead.direction == _lastHeadTurn!.direction &&
          calculateDistance(newHead.position, _lastHeadTurn!.position) <= 20.0;
      if (sameTurn) {
        _lastHeadTurn = newHead;
      }
    }

    _remainingTurns = newTurns;

    if (_remainingTurns.isNotEmpty) {
      final first = _remainingTurns.first;
      _nextTurnDirection = first.direction;
      _distanceToNextTurn = first.distanceFromPrev;
      _instructionText = InstructionBuilder.buildInstruction(
        first.maneuver,
        first.exitNumber,
      );
      _currentStreetName = first.streetName;
      _roundaboutExit = first.exitNumber;
      _arService.placeArrow(first.direction, first.distanceFromPrev);
    }
    notifyListeners();
  }

  void updateAROverlay(LatLng currentLocation) {
    // TEMPORARY - remove after voice guidance testing is complete
    if (_debugOverrideActive) return;

    if (_remainingTurns.isEmpty) {
      _nextTurnDirection = TurnDirection.forward;
      _distanceToNextTurn = _destinationCoordinates != null
          ? calculateDistance(currentLocation, _destinationCoordinates!)
          : 0;
      _instructionText = 'Continue';
      _currentStreetName = null;
      _roundaboutExit = null;
      notifyListeners();
      return;
    }

    // Drop turns one-at-a-time from the head only — bulk removeWhere would skip
    // multiple turns simultaneously when consecutive positions are close together.
    // U-turns get a wider threshold (20 m) because wide arcs may never bring the
    // driver within 10 m of the theoretical turn start point.
    while (_remainingTurns.isNotEmpty) {
      final head = _remainingTurns.first;
      final threshold =
          (head.direction == TurnDirection.uTurn ||
           head.direction == TurnDirection.roundabout)
              ? 20.0
              : 10.0;
      if (calculateDistance(currentLocation, head.position) < threshold) {
        _remainingTurns.removeAt(0);
        _lastDistanceToNextTurn = null;
        _closestApproachToHead = null;
      } else {
        break;
      }
    }

    // Missed turn detection: if the user got close to a turn but is now
    // moving away, consider it missed and pop it.
    if (_remainingTurns.isNotEmpty) {
      final head = _remainingTurns.first;
      final distToHead = calculateDistance(currentLocation, head.position);

      if (_closestApproachToHead != null &&
          distToHead > _closestApproachToHead! + 80.0 &&
          _closestApproachToHead! < 200.0) {
        _remainingTurns.removeAt(0);
        _closestApproachToHead = null;
        _lastDistanceToNextTurn = null;
      } else {
        if (_closestApproachToHead == null ||
            distToHead < _closestApproachToHead!) {
          _closestApproachToHead = distToHead;
        }
      }
    }

    if (_remainingTurns.isEmpty) {
      _nextTurnDirection = TurnDirection.forward;
      _distanceToNextTurn = _destinationCoordinates != null
          ? calculateDistance(currentLocation, _destinationCoordinates!)
          : 0;
      _instructionText = 'Continue';
      _currentStreetName = null;
      _roundaboutExit = null;
      notifyListeners();
      return;
    }

    // Pop stale forward step if user has moved past its start position (GPS missed 10m window).
    if (_remainingTurns.isNotEmpty) {
      final head = _remainingTurns.first;
      if (head.direction == TurnDirection.forward) {
        final distToHead = calculateDistance(currentLocation, head.position);
        if (distToHead > 50.0 && _remainingTurns.length > 1) {
          final nextDist = calculateDistance(
            currentLocation,
            _remainingTurns[1].position,
          );
          if (nextDist < distToHead) {
            _remainingTurns.removeAt(0);
          }
        }
      }
    }

    // Reset the distance clamp whenever the head turn changes — covers both the
    // prune loop above and the stale-forward-step removal (which doesn't reset it).
    final currentHead = _remainingTurns.first;
    if (currentHead != _lastHeadTurn) {
      _lastDistanceToNextTurn = null;
      _lookaheadActive = false;
      _closestApproachToHead = null;
      _lastAnnounced = VoiceAnnouncement.none;
    }
    _lastHeadTurn = currentHead;

    final currentStep = _remainingTurns[0];
    final distanceToCurrentStep =
        calculateDistance(currentLocation, currentStep.position);

    if (currentStep.direction != TurnDirection.forward) {
      // Unified distance gate for ALL non-forward turns (replaces the
      // roundabout-only check). Engage at 1000 m, disengage at 1100 m.
      if (!_lookaheadActive && distanceToCurrentStep > 1000.0) {
        _nextTurnDirection = TurnDirection.forward;
        _distanceToNextTurn = distanceToCurrentStep;
        _roundaboutExit = null;
        _instructionText = 'Continue';
        _currentStreetName = currentStep.streetName;
        _arService.updateArrow(TurnDirection.forward, distanceToCurrentStep);
        _checkVoiceAnnouncement();
        notifyListeners();
        return;
      }

      if (_lookaheadActive && distanceToCurrentStep > 1100.0) {
        _lookaheadActive = false;
        _nextTurnDirection = TurnDirection.forward;
        _distanceToNextTurn = distanceToCurrentStep;
        _roundaboutExit = null;
        _instructionText = 'Continue';
        _currentStreetName = currentStep.streetName;
        _arService.updateArrow(TurnDirection.forward, distanceToCurrentStep);
        _checkVoiceAnnouncement();
        notifyListeners();
        return;
      }

      // Within lookahead range — show the turn directly.
      _lookaheadActive = true;
      double newDistance = distanceToCurrentStep;
      if (_lastDistanceToNextTurn != null &&
          newDistance < 500.0 &&
          newDistance > _lastDistanceToNextTurn! + 20.0 &&
          _closestApproachToHead != null &&
          newDistance <= _closestApproachToHead! + 30.0) {
        newDistance = _lastDistanceToNextTurn!;
      }
      _lastDistanceToNextTurn = newDistance;
      _distanceToNextTurn = newDistance;
      _nextTurnDirection = currentStep.direction;
      _instructionText = InstructionBuilder.buildInstruction(
        currentStep.maneuver,
        currentStep.exitNumber,
      );
      _currentStreetName = currentStep.streetName;
      _roundaboutExit = currentStep.exitNumber;
      _arService.updateArrow(currentStep.direction, distanceToCurrentStep);
    } else {
      // Current step is forward — scan ahead for the first non-forward turn within 1 km.
      final upcomingTurn = _remainingTurns.firstWhere(
        (t) => t.direction != TurnDirection.forward,
        orElse: () => currentStep,
      );
      final distanceToUpcoming =
          calculateDistance(currentLocation, upcomingTurn.position);

      double newDistance = distanceToUpcoming;
      if (_lastDistanceToNextTurn != null &&
          newDistance < 500.0 &&
          newDistance > _lastDistanceToNextTurn! + 20.0 &&
          _closestApproachToHead != null &&
          newDistance <= _closestApproachToHead! + 30.0) {
        newDistance = _lastDistanceToNextTurn!;
      }
      _lastDistanceToNextTurn = newDistance;
      _distanceToNextTurn = newDistance;

      final double lookaheadThreshold =
          _lookaheadActive ? 1100.0 : 1000.0;

      if (distanceToUpcoming <= lookaheadThreshold &&
          upcomingTurn.direction != TurnDirection.forward) {
        _lookaheadActive = true;
        _nextTurnDirection = upcomingTurn.direction;
        _instructionText = InstructionBuilder.buildInstruction(
          upcomingTurn.maneuver,
          upcomingTurn.exitNumber,
        );
        _currentStreetName = upcomingTurn.streetName;
        _roundaboutExit = upcomingTurn.exitNumber;
        _arService.updateArrow(upcomingTurn.direction, distanceToUpcoming);
      } else {
        _lookaheadActive = false;
        _nextTurnDirection = currentStep.direction;
        _instructionText = InstructionBuilder.buildInstruction(
          currentStep.maneuver,
          currentStep.exitNumber,
        );
        _currentStreetName = currentStep.streetName;
        _roundaboutExit = currentStep.exitNumber;
        _arService.updateArrow(currentStep.direction, distanceToUpcoming);
        if (upcomingTurn == currentStep && _remainingTurns.isNotEmpty) {
          final targetPoint =
              _destinationCoordinates ?? _remainingTurns.last.position;
          _distanceToNextTurn =
              calculateDistance(currentLocation, targetPoint);
        }
      }
    }

    _checkVoiceAnnouncement();
    notifyListeners();
  }

  void resetOverlay() {
    _nextTurnDirection = null;
    _distanceToNextTurn = null;
    _instructionText = 'Continue';
    _currentStreetName = null;
    _roundaboutExit = null;
    _remainingTurns = [];
    _lastDistanceToNextTurn = null;
    _lastHeadTurn = null;
    _lookaheadActive = false;
    _closestApproachToHead = null;
    _destinationCoordinates = null;
    _lastAnnounced = VoiceAnnouncement.none;
    _arService.clearOverlays();
    _voiceService.stop();
    notifyListeners();
  }

  void setDestination(LatLng? destination) {
    _destinationCoordinates = destination;
  }

  // Toggles the voice guidance mute button on the AR screen. Stops any
  // in-progress speech immediately when muting, rather than letting the
  // current announcement finish.
  void toggleVoiceGuidance() {
    voiceGuidanceEnabled = !voiceGuidanceEnabled;
    if (!voiceGuidanceEnabled) {
      _voiceService.stop();
    }
    notifyListeners();
  }

  // ── Static testing hooks (debug buttons) — no GPS/route required ──────────

  // Lets the debug direction buttons drive the real direction/exit state
  // (instead of a widget-local override) so testVoiceAnnouncement() below
  // speaks the same direction the arrow is currently showing.
  void testSetDirection(TurnDirection? direction, {int? exitNumber}) {
    // TEMPORARY - remove after voice guidance testing is complete
    _debugOverrideActive = true;
    _nextTurnDirection = direction;
    _roundaboutExit = exitNumber;
    notifyListeners();
  }

  // Forces distanceToNextTurn to a representative test value, clears the
  // announcement dedup so the press is treated as a fresh turn, then runs
  // the real announcement check — same path GPS updates use.
  void testVoiceAnnouncement(double distance) {
    // TEMPORARY - remove after voice guidance testing is complete
    _debugOverrideActive = true;
    _distanceToNextTurn = distance;
    _lastAnnounced = VoiceAnnouncement.none;
    _checkVoiceAnnouncement();
    notifyListeners();
  }

  // TEMPORARY - remove after voice guidance testing is complete
  // "Exit Test Mode" — resumes real GPS-driven overlay updates immediately.
  void exitTestMode() {
    _debugOverrideActive = false;
    notifyListeners();
  }

  // Closest zone first — defends against GPS jumps that could otherwise
  // skip straight past an intermediate zone without announcing it.
  void _checkVoiceAnnouncement() {
    if (!voiceGuidanceEnabled) return;

    final d = _distanceToNextTurn;
    if (d == null) return;

    if (d < 50 && _lastAnnounced != VoiceAnnouncement.red) {
      _voiceService.speak(
        _buildVoiceInstruction(includeDistance: false, useKm: false),
      );
      _lastAnnounced = VoiceAnnouncement.red;
    } else if (d >= 50 &&
        d <= 200 &&
        (_lastAnnounced == VoiceAnnouncement.none ||
            _lastAnnounced == VoiceAnnouncement.far200to1km ||
            _lastAnnounced == VoiceAnnouncement.far1km)) {
      _voiceService.speak(
        _buildVoiceInstruction(includeDistance: true, useKm: false),
      );
      _lastAnnounced = VoiceAnnouncement.yellow;
    } else if (d > 200 &&
        d <= 1000 &&
        (_lastAnnounced == VoiceAnnouncement.none ||
            _lastAnnounced == VoiceAnnouncement.far1km)) {
      _voiceService.speak(
        _buildVoiceInstruction(includeDistance: true, useKm: false),
      );
      _lastAnnounced = VoiceAnnouncement.far200to1km;
    } else if (d > 1000 && _lastAnnounced == VoiceAnnouncement.none) {
      _voiceService.speak(
        _buildVoiceInstruction(includeDistance: true, useKm: true),
      );
      _lastAnnounced = VoiceAnnouncement.far1km;
    }
  }

  String _buildVoiceInstruction({
    required bool includeDistance,
    required bool useKm,
  }) {
    final direction = switch (_nextTurnDirection) {
      TurnDirection.forward    => 'Continue straight',
      TurnDirection.left       => 'Turn left',
      TurnDirection.right      => 'Turn right',
      TurnDirection.keepLeft   => 'Keep left',
      TurnDirection.keepRight  => 'Keep right',
      TurnDirection.uTurn      => 'Make a U-turn',
      TurnDirection.roundabout => switch (_roundaboutExit) {
          1 => 'At the roundabout, take the first exit',
          2 => 'At the roundabout, take the second exit',
          3 => 'At the roundabout, take the third exit',
          4 => 'At the roundabout, take the fourth exit',
          null => 'At the roundabout, take the exit',
          _ => 'At the roundabout, take exit $_roundaboutExit',
        },
      null => 'Continue straight',
    };

    // Metres branch mirrors the rounding DynamicArrowWidget._distanceLabel
    // already applies to the on-screen "170 m" style label, so voice and the
    // AR overlay never read out different numbers for the same distance.
    final prefix = !includeDistance
        ? ''
        : useKm
            ? 'In ${_formatKmForSpeech(_distanceToNextTurn ?? 0)}, '
            : 'In ${(((_distanceToNextTurn ?? 0) / 10).round() * 10).clamp(10, 990)} metres, ';

    var instruction = '$prefix$direction';

    // Street name only on the direct-command (red) and first-heard (far1km)
    // announcements — yellow and far200to1km stay shorter.
    final includeStreet = (!includeDistance || useKm) && _currentStreetName != null;
    if (includeStreet) {
      instruction = '$instruction onto ${_sanitizeStreetNameForSpeech(_currentStreetName!)}';
    }

    return instruction;
  }

  // Rounds to one decimal place, then drops the decimal for whole-number
  // results so "1.0 kilometres" reads as "1 kilometre" instead — matches
  // how a person would actually say the distance aloud.
  String _formatKmForSpeech(double metres) {
    final formatted = (metres / 1000).toStringAsFixed(1);
    if (formatted.endsWith('.0')) {
      final whole = formatted.substring(0, formatted.length - 2);
      return whole == '1' ? '1 kilometre' : '$whole kilometres';
    }
    return '$formatted kilometres';
  }

  // Builds a speech-only copy of the street name — never touches
  // currentStreetName or anything used for on-screen text. Order matters:
  // slash/dash expansion first, then all-caps word spelling, so the inserted
  // "slash"/"dash" words (lowercase) can't be mistaken for section codes.
  String _sanitizeStreetNameForSpeech(String name) {
    var spoken = name.replaceAll('/', ' slash ');
    spoken = spoken.replaceAll('-', ' dash ');
    spoken = spoken.replaceAllMapped(
      RegExp(r'\b[A-Z]{2,4}\b'),
      (match) => match.group(0)!.split('').join(' '),
    );
    return spoken;
  }
}
