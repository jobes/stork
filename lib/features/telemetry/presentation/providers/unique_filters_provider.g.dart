// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unique_filters_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(uniquePilotIds)
final uniquePilotIdsProvider = UniquePilotIdsProvider._();

final class UniquePilotIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  UniquePilotIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uniquePilotIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uniquePilotIdsHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return uniquePilotIds(ref);
  }
}

String _$uniquePilotIdsHash() => r'e7a788a0e11ce53ecedad391aecab3b8944d95dd';

@ProviderFor(uniqueAirplaneIds)
final uniqueAirplaneIdsProvider = UniqueAirplaneIdsProvider._();

final class UniqueAirplaneIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  UniqueAirplaneIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uniqueAirplaneIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uniqueAirplaneIdsHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return uniqueAirplaneIds(ref);
  }
}

String _$uniqueAirplaneIdsHash() => r'a7a69ce3cfbb1dc24745c191ca67091af027a652';
