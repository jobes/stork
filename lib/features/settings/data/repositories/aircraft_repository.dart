import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/aircraft.dart';

import '../../../../core/providers/shared_preferences_provider.dart';

part 'aircraft_repository.g.dart';

class AircraftRepository {
  final SharedPreferences _prefs;

  AircraftRepository(this._prefs);

  static const _keyAircrafts = 'app_aircrafts';

  Future<List<Aircraft>> getAircrafts() async {
    final jsonString = _prefs.getString(_keyAircrafts);
    if (jsonString != null) {
      try {
        final List<dynamic> decodedList = json.decode(jsonString);
        return decodedList
            .map((item) => Aircraft.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('AircraftRepository: Failed to parse aircrafts JSON: $e');
        // On error, return empty list instead of crashing
        return [];
      }
    }
    return [];
  }

  Future<void> saveAircrafts(List<Aircraft> aircrafts) async {
    final success = await _prefs.setString(
      _keyAircrafts,
      json.encode(aircrafts.map((a) => a.toJson()).toList()),
    );
    if (!success) {
      throw StateError('Failed to save aircrafts to SharedPreferences.');
    }
  }

  Future<Aircraft?> getAircraft(String id) async {
    final aircrafts = await getAircrafts();
    for (final aircraft in aircrafts) {
      if (aircraft.id == id) return aircraft;
    }
    return null;
  }

  Future<void> saveAircraft(Aircraft aircraft) async {
    final aircrafts = await getAircrafts();
    final index = aircrafts.indexWhere((a) => a.id == aircraft.id);
    if (index >= 0) {
      aircrafts[index] = aircraft;
    } else {
      aircrafts.add(aircraft);
    }
    await saveAircrafts(aircrafts);
  }

  Future<void> deleteAircraft(String id) async {
    final aircrafts = await getAircrafts();
    aircrafts.removeWhere((a) => a.id == id);
    await saveAircrafts(aircrafts);
  }
}

@riverpod
Future<AircraftRepository> aircraftRepository(Ref ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return AircraftRepository(prefs);
}
