import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'style_service.dart';

import '../../features/settings/presentation/providers/settings_provider.dart';

part 'style_provider.g.dart';

@riverpod
Future<String> mapStyle(Ref ref) async {
  final fontSize = ref.watch(
    appSettingsProvider.select((s) => (s.value?.mapFontSize ?? 1.0) * 1.5),
  );
  return StyleService.loadStyle(fontSize: fontSize);
}
