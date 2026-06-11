import '../../../../l10n/app_localizations.dart';
import '../../domain/airport_metadata.dart';

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
