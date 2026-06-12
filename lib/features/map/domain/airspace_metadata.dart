import '../../../../l10n/app_localizations.dart';
import 'airport_metadata.dart';

enum AirspaceClass {
  a,
  b,
  c,
  d,
  e,
  f,
  g,
  unclassified,
  unknown;

  static AirspaceClass fromInt(int val) => switch (val) {
    0 => AirspaceClass.a,
    1 => AirspaceClass.b,
    2 => AirspaceClass.c,
    3 => AirspaceClass.d,
    4 => AirspaceClass.e,
    5 => AirspaceClass.f,
    6 => AirspaceClass.g,
    8 => AirspaceClass.unclassified,
    _ => AirspaceClass.unknown,
  };

  String toLocalizedName(AppLocalizations l10n) => switch (this) {
    AirspaceClass.a => l10n.airspaceClassA,
    AirspaceClass.b => l10n.airspaceClassB,
    AirspaceClass.c => l10n.airspaceClassC,
    AirspaceClass.d => l10n.airspaceClassD,
    AirspaceClass.e => l10n.airspaceClassE,
    AirspaceClass.f => l10n.airspaceClassF,
    AirspaceClass.g => l10n.airspaceClassG,
    AirspaceClass.unclassified => l10n.airspaceClassUnclassified,
    _ => l10n.airspaceClassUnknown,
  };
}

enum AirspaceType {
  other, // 0
  restricted, // 1
  danger, // 2
  prohibited, // 3
  ctr, // 4
  tmz, // 5
  rmz, // 6
  tma, // 7
  tra, // 8
  tsa, // 9
  fir, // 10
  uir, // 11
  adiz, // 12
  atz, // 13
  matz, // 14
  airway, // 15
  mtr, // 16
  alert, // 17
  warning, // 18
  protected, // 19
  htz, // 20
  gliding, // 21
  trp, // 22
  tiz, // 23
  tia, // 24
  mta, // 25
  cta, // 26
  acc, // 27
  sport, // 28
  lowOverflight, // 29
  mrt, // 30
  tfr, // 31
  vfr, // 32
  fis, // 33
  lta, // 34
  uta, // 35
  mctr, // 36
  unknown;

  static AirspaceType fromInt(int val) {
    if (val >= 0 && val < AirspaceType.values.length - 1) {
      return AirspaceType.values[val];
    }
    return AirspaceType.unknown;
  }

  String toLocalizedName(AppLocalizations l10n) => switch (this) {
    AirspaceType.other => l10n.airspaceTypeOther,
    AirspaceType.restricted => l10n.airspaceTypeRestricted,
    AirspaceType.danger => l10n.airspaceTypeDanger,
    AirspaceType.prohibited => l10n.airspaceTypeProhibited,
    AirspaceType.ctr => l10n.airspaceTypeCtr,
    AirspaceType.tmz => l10n.airspaceTypeTmz,
    AirspaceType.rmz => l10n.airspaceTypeRmz,
    AirspaceType.tma => l10n.airspaceTypeTma,
    AirspaceType.tra => l10n.airspaceTypeTra,
    AirspaceType.tsa => l10n.airspaceTypeTsa,
    AirspaceType.fir => l10n.airspaceTypeFir,
    AirspaceType.uir => l10n.airspaceTypeUir,
    AirspaceType.adiz => l10n.airspaceTypeAdiz,
    AirspaceType.atz => l10n.airspaceTypeAtz,
    AirspaceType.matz => l10n.airspaceTypeMatz,
    AirspaceType.airway => l10n.airspaceTypeAirway,
    AirspaceType.mtr => l10n.airspaceTypeMtr,
    AirspaceType.alert => l10n.airspaceTypeAlert,
    AirspaceType.warning => l10n.airspaceTypeWarning,
    AirspaceType.protected => l10n.airspaceTypeProtected,
    AirspaceType.htz => l10n.airspaceTypeHtz,
    AirspaceType.gliding => l10n.airspaceTypeGliding,
    AirspaceType.trp => l10n.airspaceTypeTrp,
    AirspaceType.tiz => l10n.airspaceTypeTiz,
    AirspaceType.tia => l10n.airspaceTypeTia,
    AirspaceType.mta => l10n.airspaceTypeMta,
    AirspaceType.cta => l10n.airspaceTypeCta,
    AirspaceType.acc => l10n.airspaceTypeAcc,
    AirspaceType.sport => l10n.airspaceTypeSport,
    AirspaceType.lowOverflight => l10n.airspaceTypeLowOverflight,
    AirspaceType.mrt => l10n.airspaceTypeMrt,
    AirspaceType.tfr => l10n.airspaceTypeTfr,
    AirspaceType.vfr => l10n.airspaceTypeVfr,
    AirspaceType.fis => l10n.airspaceTypeFis,
    AirspaceType.lta => l10n.airspaceTypeLta,
    AirspaceType.uta => l10n.airspaceTypeUta,
    AirspaceType.mctr => l10n.airspaceTypeMctr,
    _ => l10n.airspaceTypeUnknown,
  };
}

enum AirspaceActivity {
  none,
  parachuting,
  aerobatics,
  aeroclub,
  ulm,
  gliding,
  unknown;

  static AirspaceActivity fromInt(int val) {
    if (val >= 0 && val < AirspaceActivity.values.length - 1) {
      return AirspaceActivity.values[val];
    }
    return AirspaceActivity.unknown;
  }

  String toLocalizedName(AppLocalizations l10n) => switch (this) {
    AirspaceActivity.none => l10n.airspaceActivityNone,
    AirspaceActivity.parachuting => l10n.airspaceActivityParachuting,
    AirspaceActivity.aerobatics => l10n.airspaceActivityAerobatics,
    AirspaceActivity.aeroclub => l10n.airspaceActivityAeroclub,
    AirspaceActivity.ulm => l10n.airspaceActivityUlm,
    AirspaceActivity.gliding => l10n.airspaceActivityGliding,
    _ => l10n.airspaceActivityUnknown,
  };
}

enum ReferenceDatum {
  gnd, // 0
  msl, // 1
  std, // 2
  unknown;

  static ReferenceDatum fromInt(int val) => switch (val) {
    0 => ReferenceDatum.gnd,
    1 => ReferenceDatum.msl,
    2 => ReferenceDatum.std,
    _ => ReferenceDatum.unknown,
  };

  String toLocalizedName(AppLocalizations l10n) => switch (this) {
    ReferenceDatum.gnd => 'GND',
    ReferenceDatum.msl => 'MSL',
    ReferenceDatum.std => 'STD',
    _ => 'unknown',
  };
}

class AirspaceLimit {
  final double value;
  final OpenAipUnit unit;
  final ReferenceDatum referenceDatum;

  AirspaceLimit({
    required this.value,
    required this.unit,
    required this.referenceDatum,
  });

  factory AirspaceLimit.fromJson(Map<String, Object?> json) {
    return AirspaceLimit(
      value: (json['value'] as num? ?? 0.0).toDouble(),
      unit: OpenAipUnit.fromInt((json['unit'] as num? ?? 0).toInt()),
      referenceDatum: ReferenceDatum.fromInt(
        (json['referenceDatum'] as num? ?? 0).toInt(),
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'value': value,
      'unit': unit.toInt(),
      'referenceDatum': referenceDatum.index,
    };
  }

  String formatLimit(AppLocalizations l10n) {
    if (unit == OpenAipUnit.flightLevel) {
      return 'FL ${value.round()}';
    }
    return '${value.round()} ${unit.symbol} ${referenceDatum.toLocalizedName(l10n)}';
  }
}

class AirspaceMetadata {
  final String id;
  final String name;
  final AirspaceClass icaoClass;
  final AirspaceType type;
  final String country;
  final AirspaceLimit limitLower;
  final AirspaceLimit limitUpper;
  final AirspaceActivity? activity;
  final bool? byNotam;
  final bool? onDemand;
  final bool? onRequest;

  AirspaceMetadata({
    required this.id,
    required this.name,
    required this.icaoClass,
    required this.type,
    required this.country,
    required this.limitLower,
    required this.limitUpper,
    this.activity,
    this.byNotam,
    this.onDemand,
    this.onRequest,
  });

  factory AirspaceMetadata.fromJson(Map<String, Object?> json) {
    final lowerLimitJson = json['lowerLimit'];
    final upperLimitJson = json['upperLimit'];

    return AirspaceMetadata(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      icaoClass: AirspaceClass.fromInt(
        (json['icaoClass'] as num? ?? -1).toInt(),
      ),
      type: AirspaceType.fromInt((json['type'] as num? ?? -1).toInt()),
      country: (json['country'] ?? '').toString(),
      limitLower: AirspaceLimit.fromJson(
        lowerLimitJson is Map<String, Object?> ? lowerLimitJson : const {},
      ),
      limitUpper: AirspaceLimit.fromJson(
        upperLimitJson is Map<String, Object?> ? upperLimitJson : const {},
      ),
      activity: json['activity'] != null
          ? AirspaceActivity.fromInt((json['activity'] as num).toInt())
          : null,
      byNotam: json['byNotam'] as bool?,
      onDemand: json['onDemand'] as bool?,
      onRequest: json['onRequest'] as bool?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      '_id': id,
      'name': name,
      'icaoClass': icaoClass == AirspaceClass.unclassified
          ? 8
          : icaoClass.index,
      'type': type.index,
      'country': country,
      'limitLower': limitLower.toJson(),
      'limitUpper': limitUpper.toJson(),
      if (activity != null) 'activity': activity!.index,
      if (byNotam != null) 'byNotam': byNotam,
      if (onDemand != null) 'onDemand': onDemand,
      if (onRequest != null) 'onRequest': onRequest,
    };
  }
}
