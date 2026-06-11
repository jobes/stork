import '../../../../l10n/app_localizations.dart';
import '../../domain/airport_metadata.dart';

extension AirportTypeL10n on AirportType {
  String toLocalizedName(AppLocalizations l10n) {
    switch (this) {
      case AirportType.airport:
        return l10n.airportTypeAirport;
      case AirportType.gliderSite:
        return l10n.airportTypeGliderSite;
      case AirportType.airfieldCivil:
        return l10n.airportTypeAirfieldCivil;
      case AirportType.internationalAirport:
        return l10n.airportTypeInternationalAirport;
      case AirportType.heliportMilitary:
        return l10n.airportTypeHeliportMilitary;
      case AirportType.militaryAerodrome:
        return l10n.airportTypeMilitaryAerodrome;
      case AirportType.ultralightFlyingSite:
        return l10n.airportTypeUltralightFlyingSite;
      case AirportType.heliportCivil:
        return l10n.airportTypeHeliportCivil;
      case AirportType.aerodromeClosed:
        return l10n.airportTypeAerodromeClosed;
      case AirportType.ifr:
        return l10n.airportTypeIfr;
      case AirportType.airfieldWater:
        return l10n.airportTypeAirfieldWater;
      case AirportType.landingStrip:
        return l10n.airportTypeLandingStrip;
      case AirportType.agriculturalLandingStrip:
        return l10n.airportTypeAgriculturalLandingStrip;
      case AirportType.altiport:
        return l10n.airportTypeAltiport;
      case AirportType.unknown:
        return l10n.airportTypeUnknown('Unknown');
    }
  }
}

extension FrequencyTypeL10n on FrequencyType {
  String toLocalizedName(AppLocalizations l10n) {
    switch (this) {
      case FrequencyType.approach:
        return l10n.frequencyTypeApproach;
      case FrequencyType.apron:
        return l10n.frequencyTypeApron;
      case FrequencyType.arrival:
        return l10n.frequencyTypeArrival;
      case FrequencyType.center:
        return l10n.frequencyTypeCenter;
      case FrequencyType.ctaf:
        return l10n.frequencyTypeCtaf;
      case FrequencyType.delivery:
        return l10n.frequencyTypeDelivery;
      case FrequencyType.departure:
        return l10n.frequencyTypeDeparture;
      case FrequencyType.fis:
        return l10n.frequencyTypeFis;
      case FrequencyType.gliding:
        return l10n.frequencyTypeGliding;
      case FrequencyType.ground:
        return l10n.frequencyTypeGround;
      case FrequencyType.info:
        return l10n.frequencyTypeInfo;
      case FrequencyType.multicom:
        return l10n.frequencyTypeMulticom;
      case FrequencyType.unicom:
        return l10n.frequencyTypeUnicom;
      case FrequencyType.radar:
        return l10n.frequencyTypeRadar;
      case FrequencyType.tower:
        return l10n.frequencyTypeTower;
      case FrequencyType.atis:
        return l10n.frequencyTypeAtis;
      case FrequencyType.radio:
        return l10n.frequencyTypeRadio;
      case FrequencyType.other:
        return l10n.frequencyTypeOther;
      case FrequencyType.airmet:
        return l10n.frequencyTypeAirmet;
      case FrequencyType.awos:
        return l10n.frequencyTypeAwos;
      case FrequencyType.lights:
        return l10n.frequencyTypeLights;
      case FrequencyType.volmet:
        return l10n.frequencyTypeVolmet;
      case FrequencyType.unknown:
        return l10n.frequencyTypeUnknown('Unknown');
    }
  }
}

extension RunwayCompositionL10n on RunwayComposition {
  String toLocalizedName(AppLocalizations l10n) {
    switch (this) {
      case RunwayComposition.asphalt:
        return l10n.surfaceAsphalt;
      case RunwayComposition.concrete:
        return l10n.surfaceConcrete;
      case RunwayComposition.grass:
        return l10n.surfaceGrass;
      case RunwayComposition.sand:
        return l10n.surfaceSand;
      case RunwayComposition.water:
        return l10n.surfaceWater;
      case RunwayComposition.bituminousTar:
        return l10n.surfaceBituminousTar;
      case RunwayComposition.brick:
        return l10n.surfaceBrick;
      case RunwayComposition.macadam:
        return l10n.surfaceMacadam;
      case RunwayComposition.stone:
        return l10n.surfaceStone;
      case RunwayComposition.coral:
        return l10n.surfaceCoral;
      case RunwayComposition.clay:
        return l10n.surfaceClay;
      case RunwayComposition.laterite:
        return l10n.surfaceLaterite;
      case RunwayComposition.gravel:
        return l10n.surfaceGravel;
      case RunwayComposition.earth:
        return l10n.surfaceEarth;
      case RunwayComposition.ice:
        return l10n.surfaceIce;
      case RunwayComposition.snow:
        return l10n.surfaceSnow;
      case RunwayComposition.protectiveLaminate:
        return l10n.surfaceProtectiveLaminate;
      case RunwayComposition.metal:
        return l10n.surfaceMetal;
      case RunwayComposition.landingMat:
        return l10n.surfaceLandingMat;
      case RunwayComposition.unknown:
        return l10n.surfaceUnknown;
      case RunwayComposition.wood:
        return l10n.surfaceWood;
    }
  }
}
