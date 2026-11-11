// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'instrument_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The same instrument state drives its card and the map status indicator.
/// The dialog also reads the individual measurements behind the alert.

@ProviderFor(instrumentStatus)
final instrumentStatusProvider = InstrumentStatusFamily._();

/// The same instrument state drives its card and the map status indicator.
/// The dialog also reads the individual measurements behind the alert.

final class InstrumentStatusProvider
    extends
        $FunctionalProvider<
          InstrumentStatus,
          InstrumentStatus,
          InstrumentStatus
        >
    with $Provider<InstrumentStatus> {
  /// The same instrument state drives its card and the map status indicator.
  /// The dialog also reads the individual measurements behind the alert.
  InstrumentStatusProvider._({
    required InstrumentStatusFamily super.from,
    required TelemetryInstrument super.argument,
  }) : super(
         retry: null,
         name: r'instrumentStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$instrumentStatusHash();

  @override
  String toString() {
    return r'instrumentStatusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<InstrumentStatus> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  InstrumentStatus create(Ref ref) {
    final argument = this.argument as TelemetryInstrument;
    return instrumentStatus(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InstrumentStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InstrumentStatus>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InstrumentStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$instrumentStatusHash() => r'2950fb62e1230900bf0adc389800bf5f137d4847';

/// The same instrument state drives its card and the map status indicator.
/// The dialog also reads the individual measurements behind the alert.

final class InstrumentStatusFamily extends $Family
    with $FunctionalFamilyOverride<InstrumentStatus, TelemetryInstrument> {
  InstrumentStatusFamily._()
    : super(
        retry: null,
        name: r'instrumentStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The same instrument state drives its card and the map status indicator.
  /// The dialog also reads the individual measurements behind the alert.

  InstrumentStatusProvider call(TelemetryInstrument instrument) =>
      InstrumentStatusProvider._(argument: instrument, from: this);

  @override
  String toString() => r'instrumentStatusProvider';
}
