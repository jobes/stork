import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/navigation/presentation/widgets/route_waypoint_tile.dart';
import 'package:stork/features/navigation/domain/models/navigation_leg.dart';
import 'package:stork/features/navigation/domain/models/navigation_point.dart';
import 'package:stork/features/settings/domain/models/speed_unit.dart';
import 'package:stork/l10n/localizations.dart';

const _point = NavigationPoint(latitude: 48.17, longitude: 17.21, name: 'LZIB');

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: appLocalizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

RouteWaypointTile _tile({required NavigationLeg leg}) => RouteWaypointTile(
  index: 0,
  count: 2,
  point: leg.point,
  leg: leg,
  weather: null,
  speedUnit: SpeedUnit.kmh,
  defaultAltitudeFeet: null,
  onTap: null,
  onRemove: () {},
  onAltitude: () {},
);

void main() {
  testWidgets('shows leg and total durations for a timed waypoint', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        _tile(
          leg: NavigationLeg(
            point: _point,
            legDistanceMeters: 12000,
            legDuration: const Duration(minutes: 12),
            cumulativeDistanceMeters: 12000,
            cumulativeDuration: const Duration(minutes: 12),
            eta: DateTime.utc(2026, 11, 16, 10, 12),
          ),
        ),
      ),
    );

    expect(find.textContaining('· 12 min'), findsNWidgets(2));
  });

  testWidgets('hides durations when the forecast blocks progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        _tile(
          leg: NavigationLeg(
            point: _point,
            legDistanceMeters: 12000,
            legDuration: Duration.zero,
            cumulativeDistanceMeters: 12000,
            cumulativeDuration: Duration.zero,
          ),
        ),
      ),
    );

    expect(find.textContaining('min'), findsNothing);
    expect(find.textContaining('---'), findsWidgets);
  });
}
