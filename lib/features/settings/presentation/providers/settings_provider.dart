import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/app_settings.dart';

part 'settings_provider.g.dart';

@riverpod
Future<SharedPreferences> sharedPreferences(Ref ref) {
  return SharedPreferences.getInstance();
}

@riverpod
class AppSettingsNotifier extends _$AppSettingsNotifier {
  @override
  FutureOr<AppSettings> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return AppSettings(
      mapFontSize: prefs.getDouble('mapFontSize') ?? 1.0,
      mapDefaultZoom: prefs.getDouble('mapDefaultZoom') ?? 6.0,
      mapOverviewZoom: prefs.getDouble('mapOverviewZoom') ?? 10.0,
      mapFollowZoom: prefs.getDouble('mapFollowZoom') ?? 12.0,
    );
  }

  Future<void> updateFontSize(double fontSize) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setDouble('mapFontSize', fontSize);
    state = state.whenData((settings) => settings.copyWith(mapFontSize: fontSize));
  }

  Future<void> updateDefaultZoom(double zoom) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setDouble('mapDefaultZoom', zoom);
    state = state.whenData((settings) => settings.copyWith(mapDefaultZoom: zoom));
  }

  Future<void> updateOverviewZoom(double zoom) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setDouble('mapOverviewZoom', zoom);
    state = state.whenData((settings) => settings.copyWith(mapOverviewZoom: zoom));
  }

  Future<void> updateFollowZoom(double zoom) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setDouble('mapFollowZoom', zoom);
    state = state.whenData((settings) => settings.copyWith(mapFollowZoom: zoom));
  }
}
