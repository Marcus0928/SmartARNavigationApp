// Bug: Settings screen's distance-unit toggle (km/miles) was persisted but
// never read anywhere — every display site had its own hardcoded km/m
// formatting. This is the single shared formatter every site now calls,
// keyed off SettingsViewModel.distanceUnit ('km' or 'miles'), so a unit
// change is reflected everywhere at once.
//
// Metres round to the nearest 10 below the long-distance threshold (matches
// the rounding ar_viewmodel.dart's voice announcements already use) so the
// number doesn't jitter with GPS noise during live turn-by-turn countdowns.
String formatDistance(double metres, String unit) {
  if (unit == 'miles') {
    final miles = metres / 1609.344;
    if (miles >= 0.1) {
      return '${miles.toStringAsFixed(1)} mi';
    }
    final feet = (metres * 3.28084 / 10).round() * 10;
    return '$feet ft';
  }
  if (metres >= 1000) {
    return '${(metres / 1000).toStringAsFixed(1)} km';
  }
  // Clamped below 1000 so a value in the 995-999m window rounds down to
  // 990m instead of up to 1000m, which would misleadingly read as if the
  // km branch above should have applied.
  final rounded = ((metres / 10).round() * 10).clamp(10, 990);
  return '$rounded m';
}
