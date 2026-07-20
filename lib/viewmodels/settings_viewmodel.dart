import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends ChangeNotifier {
  static const _keyNavMode = 'navigation_mode';
  static const _keyDistanceUnit = 'distance_unit';
  static const _keyShowSpeed = 'show_speed';
  static const _keyShowETA = 'show_eta';
  static const _keyArrowSize = 'arrow_size';
  static const _keyOverlayOpacity = 'overlay_opacity';
  static const _keyAvoidTolls = 'avoid_tolls';
  static const _keyAutoBrightness = 'auto_brightness';

  String _navigationMode = 'AR';
  String _distanceUnit = 'km';
  bool _showSpeed = true;
  bool _showETA = true;
  String _arrowSize = 'Medium';
  double _overlayOpacity = 1.0;
  bool _avoidTolls = false;
  bool _autoBrightness = true;

  String get navigationMode => _navigationMode;
  String get distanceUnit => _distanceUnit;
  bool get showSpeed => _showSpeed;
  bool get showETA => _showETA;
  String get arrowSize => _arrowSize;
  double get overlayOpacity => _overlayOpacity;
  bool get avoidTolls => _avoidTolls;
  bool get autoBrightness => _autoBrightness;

  SettingsViewModel() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _navigationMode = prefs.getString(_keyNavMode) ?? 'AR';
    _distanceUnit = prefs.getString(_keyDistanceUnit) ?? 'km';
    _showSpeed = prefs.getBool(_keyShowSpeed) ?? true;
    _showETA = prefs.getBool(_keyShowETA) ?? true;
    _arrowSize = prefs.getString(_keyArrowSize) ?? 'Medium';
    _overlayOpacity = prefs.getDouble(_keyOverlayOpacity) ?? 1.0;
    _avoidTolls = prefs.getBool(_keyAvoidTolls) ?? false;
    _autoBrightness = prefs.getBool(_keyAutoBrightness) ?? true;
    notifyListeners();
  }

  Future<void> setNavigationMode(String mode) async {
    _navigationMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNavMode, mode);
  }

  Future<void> setDistanceUnit(String unit) async {
    _distanceUnit = unit;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDistanceUnit, unit);
  }

  Future<void> setShowSpeed(bool value) async {
    _showSpeed = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowSpeed, value);
  }

  Future<void> setShowETA(bool value) async {
    _showETA = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowETA, value);
  }

  Future<void> setArrowSize(String size) async {
    _arrowSize = size;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyArrowSize, size);
  }

  Future<void> setOverlayOpacity(double opacity) async {
    _overlayOpacity = opacity.clamp(0.5, 1.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyOverlayOpacity, _overlayOpacity);
  }

  Future<void> setAvoidTolls(bool value) async {
    _avoidTolls = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAvoidTolls, value);
  }

  Future<void> setAutoBrightness(bool value) async {
    _autoBrightness = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoBrightness, value);
  }
}
