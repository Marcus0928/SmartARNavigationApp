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

class ARViewModel extends ChangeNotifier {
  final ARService _arService;

  ARViewModel({required ARService arService}) : _arService = arService;

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
    _remainingTurns = List.from(route.turns);

    // Discard a phantom U-turn at step 1: Google may produce one when the
    // origin snaps to the wrong road side because no heading was available.
    // If we do have heading (driver is moving) and a subsequent step exists,
    // the U-turn is almost certainly spurious.
    if (_remainingTurns.length > 1 &&
        _remainingTurns.first.direction == TurnDirection.uTurn &&
        heading != null) {
      _remainingTurns.removeAt(0);
    }

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
    if (_remainingTurns.isEmpty) {
      _nextTurnDirection = TurnDirection.forward;
      _distanceToNextTurn = 0;
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
      } else {
        break;
      }
    }

    if (_remainingTurns.isEmpty) {
      _nextTurnDirection = TurnDirection.forward;
      _distanceToNextTurn = 0;
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
        notifyListeners();
        return;
      }

      // Within lookahead range — show the turn directly.
      _lookaheadActive = true;
      double newDistance = distanceToCurrentStep;
      if (_lastDistanceToNextTurn != null &&
          newDistance < 500.0 &&
          newDistance > _lastDistanceToNextTurn! + 20.0) {
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
          newDistance > _lastDistanceToNextTurn! + 20.0) {
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
          _distanceToNextTurn = calculateDistance(
            currentLocation,
            _remainingTurns.last.position,
          );
        }
      }
    }

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
    _arService.clearOverlays();
    notifyListeners();
  }
}
