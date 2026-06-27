import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/pilot.dart';

import '../../../../core/providers/shared_preferences_provider.dart';

part 'pilot_repository.g.dart';

class PilotRepository {
  final SharedPreferences _prefs;

  PilotRepository(this._prefs);

  static const _keyPilots = 'app_pilots';

  Future<List<Pilot>> getPilots() async {
    final jsonString = _prefs.getString(_keyPilots);
    if (jsonString != null) {
      try {
        final List<dynamic> decodedList = json.decode(jsonString);
        return decodedList
            .map((item) => Pilot.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('PilotRepository: Failed to parse pilots JSON: $e');
        // On error, return empty list instead of crashing
        return [];
      }
    }
    return [];
  }

  Future<void> savePilots(List<Pilot> pilots) async {
    final success = await _prefs.setString(
      _keyPilots,
      json.encode(pilots.map((p) => p.toJson()).toList()),
    );
    if (!success) {
      throw StateError('Failed to save pilots to SharedPreferences.');
    }
  }

  Future<Pilot?> getPilot(String id) async {
    final pilots = await getPilots();
    for (final pilot in pilots) {
      if (pilot.id == id) return pilot;
    }
    return null;
  }

  Future<void> savePilot(Pilot pilot) async {
    final pilots = await getPilots();
    final index = pilots.indexWhere((p) => p.id == pilot.id);
    if (index >= 0) {
      pilots[index] = pilot;
    } else {
      pilots.add(pilot);
    }
    await savePilots(pilots);
  }

  Future<void> deletePilot(String id) async {
    final pilots = await getPilots();
    pilots.removeWhere((p) => p.id == id);
    await savePilots(pilots);
  }
}

@riverpod
Future<PilotRepository> pilotRepository(Ref ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return PilotRepository(prefs);
}
