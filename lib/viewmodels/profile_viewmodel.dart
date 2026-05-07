import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileViewModel extends ChangeNotifier {
  static const _kName     = 'profile_name';
  static const _kEmail    = 'profile_email';
  static const _kDrives   = 'stats_total_drives';
  static const _kDistance = 'stats_total_distance_km';
  static const _kPlaces   = 'profile_saved_places';

  String _name = '';
  String _email = '';
  int _totalDrives = 0;
  double _totalDistanceKm = 0.0;
  bool _isSaving = false;
  Map<String, String> _savedPlaces = {};

  String get name => _name;
  String get email => _email;
  int get totalDrives => _totalDrives;
  double get totalDistanceKm => _totalDistanceKm;
  bool get isSaving => _isSaving;

  ProfileViewModel() {
    loadProfile();
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString(_kName) ?? '';
    _email = prefs.getString(_kEmail) ?? '';
    _totalDrives = prefs.getInt(_kDrives) ?? 0;
    _totalDistanceKm = prefs.getDouble(_kDistance) ?? 0.0;
    _savedPlaces = _decodePlaces(prefs.getString(_kPlaces));
    notifyListeners();
  }

  Future<void> saveProfile(String name, String email) async {
    _name = name.trim();
    _email = email.trim();
    _isSaving = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, _name);
    await prefs.setString(_kEmail, _email);
    _isSaving = false;
    notifyListeners();
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  Future<void> incrementDriveCount() async {
    _totalDrives++;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDrives, _totalDrives);
  }

  Future<void> addDistance(double km) async {
    _totalDistanceKm += km;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kDistance, _totalDistanceKm);
  }

  // ── Places ────────────────────────────────────────────────────────────────

  Future<void> savePlace(String type, String address) async {
    _savedPlaces[type.toLowerCase()] = address;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPlaces, jsonEncode(_savedPlaces));
  }

  String? getPlace(String type) => _savedPlaces[type.toLowerCase()];

  List<Map<String, String>> getSavedPlaces() => _savedPlaces.entries
      .map((e) => {'type': e.key, 'address': e.value})
      .toList();

  // ── Internal ──────────────────────────────────────────────────────────────

  Map<String, String> _decodePlaces(String? json) {
    if (json == null) return {};
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }
}
