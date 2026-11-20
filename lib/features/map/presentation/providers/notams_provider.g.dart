// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notams_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notamLocations)
final notamLocationsProvider = NotamLocationsProvider._();

final class NotamLocationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          FutureOr<Set<String>>
        >
    with $FutureModifier<Set<String>>, $FutureProvider<Set<String>> {
  NotamLocationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notamLocationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notamLocationsHash();

  @$internal
  @override
  $FutureProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Set<String>> create(Ref ref) {
    return notamLocations(ref);
  }
}

String _$notamLocationsHash() => r'bac2950c2e4e70bd36d58592598287241372f58f';

@ProviderFor(Notams)
final notamsProvider = NotamsProvider._();

final class NotamsProvider
    extends $AsyncNotifierProvider<Notams, NotamFetchResult> {
  NotamsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notamsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notamsHash();

  @$internal
  @override
  Notams create() => Notams();
}

String _$notamsHash() => r'656327bdd77c9fbfc6b4bbfc295724e885410bf4';

abstract class _$Notams extends $AsyncNotifier<NotamFetchResult> {
  FutureOr<NotamFetchResult> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<NotamFetchResult>, NotamFetchResult>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<NotamFetchResult>, NotamFetchResult>,
              AsyncValue<NotamFetchResult>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
