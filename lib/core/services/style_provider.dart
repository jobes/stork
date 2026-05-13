import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'style_service.dart';

part 'style_provider.g.dart';

@riverpod
Future<String> mapStyle(Ref ref) {
  return StyleService.loadStyle();
}
