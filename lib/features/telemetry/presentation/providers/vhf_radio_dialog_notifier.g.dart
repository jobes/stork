// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vhf_radio_dialog_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VhfRadioDialogNotifier)
final vhfRadioDialogProvider = VhfRadioDialogNotifierFamily._();

final class VhfRadioDialogNotifierProvider
    extends $NotifierProvider<VhfRadioDialogNotifier, VhfRadioDialogUiState> {
  VhfRadioDialogNotifierProvider._({
    required VhfRadioDialogNotifierFamily super.from,
    required (
      int,
      int, {
      int initialActiveKhz,
      int initialStandbyKhz,
      String initialActiveName,
      String initialStandbyName,
      int initialVolume,
      int initialSquelch,
      int initialVox,
      int initialIntercom,
      List<int> initialMicGain,
      bool initialIsDual,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'vhfRadioDialogProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$vhfRadioDialogNotifierHash();

  @override
  String toString() {
    return r'vhfRadioDialogProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  VhfRadioDialogNotifier create() => VhfRadioDialogNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VhfRadioDialogUiState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VhfRadioDialogUiState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is VhfRadioDialogNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$vhfRadioDialogNotifierHash() =>
    r'886fbfa1a848c8a9338a1e14fd49c5a031837d27';

final class VhfRadioDialogNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          VhfRadioDialogNotifier,
          VhfRadioDialogUiState,
          VhfRadioDialogUiState,
          VhfRadioDialogUiState,
          (
            int,
            int, {
            int initialActiveKhz,
            int initialStandbyKhz,
            String initialActiveName,
            String initialStandbyName,
            int initialVolume,
            int initialSquelch,
            int initialVox,
            int initialIntercom,
            List<int> initialMicGain,
            bool initialIsDual,
          })
        > {
  VhfRadioDialogNotifierFamily._()
    : super(
        retry: null,
        name: r'vhfRadioDialogProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  VhfRadioDialogNotifierProvider call(
    int nodeId,
    int radioInstance, {
    required int initialActiveKhz,
    required int initialStandbyKhz,
    required String initialActiveName,
    required String initialStandbyName,
    required int initialVolume,
    required int initialSquelch,
    required int initialVox,
    required int initialIntercom,
    required List<int> initialMicGain,
    required bool initialIsDual,
  }) => VhfRadioDialogNotifierProvider._(
    argument: (
      nodeId,
      radioInstance,
      initialActiveKhz: initialActiveKhz,
      initialStandbyKhz: initialStandbyKhz,
      initialActiveName: initialActiveName,
      initialStandbyName: initialStandbyName,
      initialVolume: initialVolume,
      initialSquelch: initialSquelch,
      initialVox: initialVox,
      initialIntercom: initialIntercom,
      initialMicGain: initialMicGain,
      initialIsDual: initialIsDual,
    ),
    from: this,
  );

  @override
  String toString() => r'vhfRadioDialogProvider';
}

abstract class _$VhfRadioDialogNotifier
    extends $Notifier<VhfRadioDialogUiState> {
  late final _$args =
      ref.$arg
          as (
            int,
            int, {
            int initialActiveKhz,
            int initialStandbyKhz,
            String initialActiveName,
            String initialStandbyName,
            int initialVolume,
            int initialSquelch,
            int initialVox,
            int initialIntercom,
            List<int> initialMicGain,
            bool initialIsDual,
          });
  int get nodeId => _$args.$1;
  int get radioInstance => _$args.$2;
  int get initialActiveKhz => _$args.initialActiveKhz;
  int get initialStandbyKhz => _$args.initialStandbyKhz;
  String get initialActiveName => _$args.initialActiveName;
  String get initialStandbyName => _$args.initialStandbyName;
  int get initialVolume => _$args.initialVolume;
  int get initialSquelch => _$args.initialSquelch;
  int get initialVox => _$args.initialVox;
  int get initialIntercom => _$args.initialIntercom;
  List<int> get initialMicGain => _$args.initialMicGain;
  bool get initialIsDual => _$args.initialIsDual;

  VhfRadioDialogUiState build(
    int nodeId,
    int radioInstance, {
    required int initialActiveKhz,
    required int initialStandbyKhz,
    required String initialActiveName,
    required String initialStandbyName,
    required int initialVolume,
    required int initialSquelch,
    required int initialVox,
    required int initialIntercom,
    required List<int> initialMicGain,
    required bool initialIsDual,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<VhfRadioDialogUiState, VhfRadioDialogUiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VhfRadioDialogUiState, VhfRadioDialogUiState>,
              VhfRadioDialogUiState,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(
        _$args.$1,
        _$args.$2,
        initialActiveKhz: _$args.initialActiveKhz,
        initialStandbyKhz: _$args.initialStandbyKhz,
        initialActiveName: _$args.initialActiveName,
        initialStandbyName: _$args.initialStandbyName,
        initialVolume: _$args.initialVolume,
        initialSquelch: _$args.initialSquelch,
        initialVox: _$args.initialVox,
        initialIntercom: _$args.initialIntercom,
        initialMicGain: _$args.initialMicGain,
        initialIsDual: _$args.initialIsDual,
      ),
    );
  }
}
