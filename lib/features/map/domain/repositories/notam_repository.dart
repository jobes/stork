import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/notam.dart';

part 'notam_repository.freezed.dart';

@freezed
sealed class NotamFetchResult with _$NotamFetchResult {
  const NotamFetchResult._();

  const factory NotamFetchResult(
    List<Notam> notams, {
    @Default(<String>[]) List<String> failedLocations,
    @Default(<String>[]) List<String> partialLocations,
    DateTime? oldestFetch,
    DateTime? nextRefresh,
    @Default(false) bool isRefreshing,
  }) = _NotamFetchResult;

  bool get hasIssue =>
      failedLocations.isNotEmpty || partialLocations.isNotEmpty;
}

abstract class NotamRepository {
  NotamFetchResult cachedNotams(Iterable<String> locations);

  Future<NotamFetchResult> fetchNotamsByLocations(
    Iterable<String> locations, {
    bool force = false,
    bool Function()? isCurrent,
    void Function(NotamFetchResult)? onProgress,
  });
}
