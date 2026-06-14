import '../../../l10n/app_localizations.dart';
import '../../../core/constants/api_constants.dart';
import '../domain/airport_metadata.dart';
import '../domain/airspace_metadata.dart';

extension AirportTypeL10n on AirportType {
  String toLocalizedName(AppLocalizations l10n) => switch (this) {
        AirportType.airport => l10n.airportTypeAirport,
        AirportType.gliderSite => l10n.airportTypeGliderSite,
        AirportType.airfieldCivil => l10n.airportTypeAirfieldCivil,
        AirportType.internationalAirport => l10n.airportTypeInternationalAirport,
        AirportType.heliportMilitary => l10n.airportTypeHeliportMilitary,
        AirportType.militaryAerodrome => l10n.airportTypeMilitaryAerodrome,
        AirportType.ultralightFlyingSite => l10n.airportTypeUltralightFlyingSite,
        AirportType.heliportCivil => l10n.airportTypeHeliportCivil,
        AirportType.aerodromeClosed => l10n.airportTypeAerodromeClosed,
        AirportType.ifr => l10n.airportTypeIfr,
        AirportType.airfieldWater => l10n.airportTypeAirfieldWater,
        AirportType.landingStrip => l10n.airportTypeLandingStrip,
        AirportType.agriculturalLandingStrip => l10n.airportTypeAgriculturalLandingStrip,
        AirportType.altiport => l10n.airportTypeAltiport,
        AirportType.unknown => l10n.airportTypeUnknown('Unknown'),
      };
}

extension FrequencyTypeL10n on FrequencyType {
  String toLocalizedName(AppLocalizations l10n) => switch (this) {
        FrequencyType.approach => l10n.frequencyTypeApproach,
        FrequencyType.apron => l10n.frequencyTypeApron,
        FrequencyType.arrival => l10n.frequencyTypeArrival,
        FrequencyType.center => l10n.frequencyTypeCenter,
        FrequencyType.ctaf => l10n.frequencyTypeCtaf,
        FrequencyType.delivery => l10n.frequencyTypeDelivery,
        FrequencyType.departure => l10n.frequencyTypeDeparture,
        FrequencyType.fis => l10n.frequencyTypeFis,
        FrequencyType.gliding => l10n.frequencyTypeGliding,
        FrequencyType.ground => l10n.frequencyTypeGround,
        FrequencyType.info => l10n.frequencyTypeInfo,
        FrequencyType.multicom => l10n.frequencyTypeMulticom,
        FrequencyType.unicom => l10n.frequencyTypeUnicom,
        FrequencyType.radar => l10n.frequencyTypeRadar,
        FrequencyType.tower => l10n.frequencyTypeTower,
        FrequencyType.atis => l10n.frequencyTypeAtis,
        FrequencyType.radio => l10n.frequencyTypeRadio,
        FrequencyType.other => l10n.frequencyTypeOther,
        FrequencyType.airmet => l10n.frequencyTypeAirmet,
        FrequencyType.awos => l10n.frequencyTypeAwos,
        FrequencyType.lights => l10n.frequencyTypeLights,
        FrequencyType.volmet => l10n.frequencyTypeVolmet,
        FrequencyType.unknown => l10n.frequencyTypeUnknown('Unknown'),
      };
}

extension RunwayCompositionL10n on RunwayComposition {
  String toLocalizedName(AppLocalizations l10n) => switch (this) {
        RunwayComposition.asphalt => l10n.surfaceAsphalt,
        RunwayComposition.concrete => l10n.surfaceConcrete,
        RunwayComposition.grass => l10n.surfaceGrass,
        RunwayComposition.sand => l10n.surfaceSand,
        RunwayComposition.water => l10n.surfaceWater,
        RunwayComposition.bituminousTar => l10n.surfaceBituminousTar,
        RunwayComposition.brick => l10n.surfaceBrick,
        RunwayComposition.macadam => l10n.surfaceMacadam,
        RunwayComposition.stone => l10n.surfaceStone,
        RunwayComposition.coral => l10n.surfaceCoral,
        RunwayComposition.clay => l10n.surfaceClay,
        RunwayComposition.laterite => l10n.surfaceLaterite,
        RunwayComposition.gravel => l10n.surfaceGravel,
        RunwayComposition.earth => l10n.surfaceEarth,
        RunwayComposition.ice => l10n.surfaceIce,
        RunwayComposition.snow => l10n.surfaceSnow,
        RunwayComposition.protectiveLaminate => l10n.surfaceProtectiveLaminate,
        RunwayComposition.metal => l10n.surfaceMetal,
        RunwayComposition.landingMat => l10n.surfaceLandingMat,
        RunwayComposition.unknown => l10n.surfaceUnknown,
        RunwayComposition.wood => l10n.surfaceWood,
      };
}

extension AirspaceClassL10n on AirspaceClass {
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

extension AirspaceTypeL10n on AirspaceType {
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

extension AirspaceActivityL10n on AirspaceActivity {
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

extension ReferenceDatumL10n on ReferenceDatum {
  String toLocalizedName(AppLocalizations l10n) => switch (this) {
        ReferenceDatum.gnd => 'GND',
        ReferenceDatum.msl => 'MSL',
        ReferenceDatum.std => 'STD',
        _ => 'unknown',
      };
}

extension AirspaceLimitFormatting on AirspaceLimit {
  String formatLimit(AppLocalizations l10n) {
    if (unit == OpenAipUnit.flightLevel) {
      return 'FL ${value.round()}';
    }
    return '${value.round()} ${unit.symbol} ${referenceDatum.toLocalizedName(l10n)}';
  }
}

extension AirportImageFormatting on AirportImage {
  String getThumbnailUrl(String apiKey) {
    return '${ApiConstants.openAipImageBaseUrl}/$filename?width=200&height=200&apiKey=$apiKey';
  }

  String getFullSizeUrl(String apiKey) {
    return '${ApiConstants.openAipImageBaseUrl}/$filename?apiKey=$apiKey';
  }
}
