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


  Future<void> initializeOverlay(RouteModel route) async {
    _remainingTurns = List.from(route.turns);

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
    if (_remainingTurns.isEmpty) return;

    // Drop turns the user has already passed (within 10m).
    _remainingTurns.removeWhere(
      (turn) => calculateDistance(currentLocation, turn.position) < 10.0,
    );

    final next = findNextTurn(currentLocation, _remainingTurns);

    if (next == null) {
      _nextTurnDirection = TurnDirection.forward;
      _distanceToNextTurn = 0;
      _instructionText = 'Continue';
      _currentStreetName = null;
      _roundaboutExit = null;
      notifyListeners();
      return;
    }

    final distance = calculateDistance(currentLocation, next.position);
    _nextTurnDirection = next.direction;
    _distanceToNextTurn = distance;
    _instructionText = InstructionBuilder.buildInstruction(
      next.maneuver,
      next.exitNumber,
    );
    _currentStreetName = next.streetName;
    _roundaboutExit = next.exitNumber;
    _arService.updateArrow(next.direction, distance);
    notifyListeners();
  }

  void resetOverlay() {
    _nextTurnDirection = null;
    _distanceToNextTurn = null;
    _instructionText = 'Continue';
    _currentStreetName = null;
    _roundaboutExit = null;
    _remainingTurns = [];
    _arService.clearOverlays();
    notifyListeners();
  }
}
