// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dronecan_firmware_update_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Lets the user choose a firmware image from the local file system.

@ProviderFor(firmwareFilePicker)
final firmwareFilePickerProvider = FirmwareFilePickerProvider._();

/// Lets the user choose a firmware image from the local file system.

final class FirmwareFilePickerProvider
    extends
        $FunctionalProvider<
          FirmwareFilePicker,
          FirmwareFilePicker,
          FirmwareFilePicker
        >
    with $Provider<FirmwareFilePicker> {
  /// Lets the user choose a firmware image from the local file system.
  FirmwareFilePickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firmwareFilePickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firmwareFilePickerHash();

  @$internal
  @override
  $ProviderElement<FirmwareFilePicker> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirmwareFilePicker create(Ref ref) {
    return firmwareFilePicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirmwareFilePicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirmwareFilePicker>(value),
    );
  }
}

String _$firmwareFilePickerHash() =>
    r'd320735be3caf21d63360244165dc3e4295cbbab';

/// Drives the firmware update of a single DroneCAN node.

@ProviderFor(DroneCanFirmwareUpdateNotifier)
final droneCanFirmwareUpdateProvider = DroneCanFirmwareUpdateNotifierFamily._();

/// Drives the firmware update of a single DroneCAN node.
final class DroneCanFirmwareUpdateNotifierProvider
    extends
        $NotifierProvider<
          DroneCanFirmwareUpdateNotifier,
          DroneCanFirmwareUpdateState
        > {
  /// Drives the firmware update of a single DroneCAN node.
  DroneCanFirmwareUpdateNotifierProvider._({
    required DroneCanFirmwareUpdateNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'droneCanFirmwareUpdateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$droneCanFirmwareUpdateNotifierHash();

  @override
  String toString() {
    return r'droneCanFirmwareUpdateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DroneCanFirmwareUpdateNotifier create() => DroneCanFirmwareUpdateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DroneCanFirmwareUpdateState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DroneCanFirmwareUpdateState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DroneCanFirmwareUpdateNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$droneCanFirmwareUpdateNotifierHash() =>
    r'1c8db972089b75186f7fdfaa4638bdda326e6cd9';

/// Drives the firmware update of a single DroneCAN node.

final class DroneCanFirmwareUpdateNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          DroneCanFirmwareUpdateNotifier,
          DroneCanFirmwareUpdateState,
          DroneCanFirmwareUpdateState,
          DroneCanFirmwareUpdateState,
          int
        > {
  DroneCanFirmwareUpdateNotifierFamily._()
    : super(
        retry: null,
        name: r'droneCanFirmwareUpdateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Drives the firmware update of a single DroneCAN node.

  DroneCanFirmwareUpdateNotifierProvider call(int nodeId) =>
      DroneCanFirmwareUpdateNotifierProvider._(argument: nodeId, from: this);

  @override
  String toString() => r'droneCanFirmwareUpdateProvider';
}

/// Drives the firmware update of a single DroneCAN node.

abstract class _$DroneCanFirmwareUpdateNotifier
    extends $Notifier<DroneCanFirmwareUpdateState> {
  late final _$args = ref.$arg as int;
  int get nodeId => _$args;

  DroneCanFirmwareUpdateState build(int nodeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<DroneCanFirmwareUpdateState, DroneCanFirmwareUpdateState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                DroneCanFirmwareUpdateState,
                DroneCanFirmwareUpdateState
              >,
              DroneCanFirmwareUpdateState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
