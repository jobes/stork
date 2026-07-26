import '../../../../l10n/app_localizations.dart';
import '../../domain/models/aircraft_type.dart';

extension AircraftTypeLocalizationExtension on AircraftType {
  String getLabel(AppLocalizations l10n) {
    switch (this) {
      case AircraftType.glider:
        return l10n.gliderType;
      case AircraftType.towPlane:
        return l10n.towPlaneType;
      case AircraftType.helicopter:
        return l10n.helicopterType;
      case AircraftType.skydiver:
        return l10n.skydiverType;
      case AircraftType.dropPlane:
        return l10n.dropPlaneType;
      case AircraftType.hangGlider:
        return l10n.hangGliderType;
      case AircraftType.paraglider:
        return l10n.paragliderType;
      case AircraftType.poweredAircraft:
        return l10n.poweredAircraftType;
      case AircraftType.jet:
        return l10n.jetType;
      case AircraftType.balloon:
        return l10n.balloonType;
      case AircraftType.airship:
        return l10n.airshipType;
      case AircraftType.uav:
        return l10n.uavType;
      case AircraftType.other:
        return l10n.otherType;
    }
  }
}
