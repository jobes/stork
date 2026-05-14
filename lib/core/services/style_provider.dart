import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'style_service.dart';

import '../../features/settings/presentation/providers/settings_provider.dart';

part 'style_provider.g.dart';

@riverpod
Future<String> mapStyle(Ref ref) async {
  final settingsAsync = ref.watch(appSettingsProvider);
  final fontSize = settingsAsync.value?.mapFontSize ?? 1.0;
  return StyleService.loadStyle(fontSize: fontSize);
}
