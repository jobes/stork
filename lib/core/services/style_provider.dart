import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'style_service.dart';
import '../../features/map/presentation/providers/map_style_data.dart';
import '../../features/map/presentation/providers/map_style_preparer.dart';

import '../../features/settings/presentation/providers/settings_provider.dart';

part 'style_provider.g.dart';

@riverpod
Future<PreparedMapStyle> mapStyle(Ref ref) async {
  final fontSize = await ref.watch(
    appSettingsProvider.selectAsync((s) => s.mapFontSize),
  );
  final baseStyle = await StyleService.loadStyle(fontSize: fontSize * 1.5);
  if (!ref.mounted) throw StateError('Style preparation was disposed');
  return MapStyleData(ref).prepare(baseStyle);
}
