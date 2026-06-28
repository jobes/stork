import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'black_box_repository_provider.dart';

part 'unique_filters_provider.g.dart';

@riverpod
Future<List<String>> uniquePilotIds(Ref ref) async {
  final repo = ref.watch(blackBoxRepositoryProvider);
  return repo.getUniquePilotIds();
}

@riverpod
Future<List<String>> uniqueAirplaneIds(Ref ref) async {
  final repo = ref.watch(blackBoxRepositoryProvider);
  return repo.getUniqueAirplaneIds();
}
