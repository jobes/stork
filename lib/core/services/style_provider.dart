import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'style_service.dart';
import '../../features/map/presentation/providers/map_camera_provider.dart';

import '../../features/settings/presentation/providers/settings_provider.dart';

part 'style_provider.g.dart';

@riverpod
Future<String> mapStyle(Ref ref) async {
  final fontSize = await ref.watch(
    appSettingsProvider.selectAsync((s) => s.mapFontSize),
  );
  final baseStyle = await StyleService.loadStyle(fontSize: fontSize * 1.5);
  if (!ref.mounted) return baseStyle;
  return ref.watch(mapCameraProvider.notifier).prepareStyle(baseStyle);
}
