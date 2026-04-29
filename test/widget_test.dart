import 'package:flutter_test/flutter_test.dart';

import 'package:smart_ar_navigation/core/enums/navigation_status.dart';
import 'package:smart_ar_navigation/core/enums/turn_direction.dart';
import 'package:smart_ar_navigation/core/utils/location_utils.dart';
import 'package:smart_ar_navigation/models/turn_instruction.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('TurnDirection enum', () {
    test('contains all expected values', () {
      expect(TurnDirection.values, containsAll([
        TurnDirection.forward,
        TurnDirection.left,
        TurnDirection.right,
        TurnDirection.keepLeft,
        TurnDirection.keepRight,
        TurnDirection.uTurn,
      ]));
    });
  });

  group('NavigationStatus enum', () {
    test('contains all expected values', () {
      expect(NavigationStatus.values, containsAll([
        NavigationStatus.idle,
        NavigationStatus.loading,
        NavigationStatus.navigating,
        NavigationStatus.rerouting,
        NavigationStatus.arrived,
      ]));
    });
  });

  group('calculateDistance', () {
    test('returns 0 for identical points', () {
      const point = LatLng(3.0738, 101.5077);
      expect(calculateDistance(point, point), 0.0);
    });

    test('returns positive distance for different points', () {
      const a = LatLng(3.0738, 101.5077);
      const b = LatLng(3.0800, 101.5150);
      expect(calculateDistance(a, b), greaterThan(0));
    });
  });

  group('findNextTurn', () {
    const currentLocation = LatLng(3.0738, 101.5077);

    test('returns null for empty turns list', () {
      expect(findNextTurn(currentLocation, []), isNull);
    });

    test('returns null when all turns are within 10m', () {
      final turns = [
        const TurnInstruction(
          direction: TurnDirection.left,
          distanceFromPrev: 50,
          streetName: 'Jalan Test',
          position: LatLng(3.0738, 101.5077), // same as currentLocation → 0m
        ),
      ];
      expect(findNextTurn(currentLocation, turns), isNull);
    });

    test('returns the first turn that is >= 10m away', () {
      final farTurn = TurnInstruction(
        direction: TurnDirection.right,
        distanceFromPrev: 100,
        streetName: 'Jalan Far',
        position: const LatLng(3.0800, 101.5150),
      );
      expect(findNextTurn(currentLocation, [farTurn]), equals(farTurn));
    });
  });
}
