class InstructionBuilder {
  static String buildInstruction(String maneuver, int? exitNumber) {
    switch (maneuver) {
      case 'turn-left':
        return 'Turn Left';
      case 'turn-right':
        return 'Turn Right';
      case 'turn-sharp-left':
        return 'Turn Left';
      case 'turn-sharp-right':
        return 'Turn Right';
      case 'keep-left':
      case 'fork-left':
        return 'Keep Left';
      case 'keep-right':
      case 'fork-right':
        return 'Keep Right';
      case 'straight':
        return 'Continue';
      case 'uturn-left':
      case 'uturn-right':
        return 'Make a U-Turn';
      case 'roundabout-left':
      case 'roundabout-right':
        return exitNumber != null ? 'Take Exit $exitNumber' : 'Take the Exit';
      case 'merge':
        return 'Continue';
      case 'ramp-left':
        return 'Keep Left';
      case 'ramp-right':
        return 'Keep Right';
      default:
        return 'Continue';
    }
  }
}
