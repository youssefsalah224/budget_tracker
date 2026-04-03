import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/simulation/domain/simulation_result.dart';

class CacheService {
  static const String _kKey = 'simulation_result_v1';

  Future<void> writeSimulation(SimulationResult result) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kKey, jsonEncode(result.toJson()));
    } catch (_) {}
  }

  Future<SimulationResult?> readSimulation() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kKey);
      if (raw == null) {
        return null;
      }
      return SimulationResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
