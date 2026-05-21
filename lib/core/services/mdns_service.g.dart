// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mdns_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(discoveredDevices)
final discoveredDevicesProvider = DiscoveredDevicesProvider._();

final class DiscoveredDevicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CannelloniDevice>>,
          List<CannelloniDevice>,
          Stream<List<CannelloniDevice>>
        >
    with
        $FutureModifier<List<CannelloniDevice>>,
        $StreamProvider<List<CannelloniDevice>> {
  DiscoveredDevicesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'discoveredDevicesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$discoveredDevicesHash();

  @$internal
  @override
  $StreamProviderElement<List<CannelloniDevice>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CannelloniDevice>> create(Ref ref) {
    return discoveredDevices(ref);
  }
}

String _$discoveredDevicesHash() => r'a0be82328f10352edb18ffbfe7e4af9c675fa59c';
