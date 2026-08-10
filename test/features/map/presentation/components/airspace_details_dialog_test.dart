import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stork/features/map/domain/airspace_metadata.dart';
import 'package:stork/features/map/domain/models/airspace_activity_status.dart';
import 'package:stork/features/map/domain/models/openaip_unit.dart';
import 'package:stork/features/map/presentation/components/dialogs/airspace_details_dialog.dart';
import 'package:stork/features/map/presentation/providers/airspace_metadata_provider.dart';
import 'package:stork/features/map/presentation/providers/airspace_activity_provider.dart';
import 'package:stork/l10n/app_localizations.dart';

AirspaceMetadata _metadata() {
  return AirspaceMetadata(
    id: 'asp_test1',
    name: 'R 33',
    icaoClass: AirspaceClass.d,
    type: AirspaceType.tsa,
    country: 'SK',
    limitLower: AirspaceLimit(
      value: 0,
      unit: OpenAipUnit.meters,
      referenceDatum: ReferenceDatum.gnd,
    ),
    limitUpper: AirspaceLimit(
      value: 95,
      unit: OpenAipUnit.flightLevel,
      referenceDatum: ReferenceDatum.std,
    ),
  );
}

AupAirspaceActivity _activity(
  AirspaceActivityStatus status, {
  DateTime? validFrom,
  DateTime? validTo,
}) {
  return AupAirspaceActivity(
    airspaceId: 'asp_test1',
    designator: 'LZR33',
    name: 'R 33',
    status: status,
    validFrom: validFrom ?? DateTime.utc(2026, 8, 2, 8),
    validTo: validTo ?? DateTime.utc(2026, 8, 2, 16),
    source: 'SVK_LZPS',
    updatedAt: DateTime.utc(2026, 8, 2, 4),
  );
}

Map<dynamic, dynamic> _feature() {
  return {
    'type': 'Feature',
    'properties': {
      'source_id': 'asp_test1',
      'country': 'SK',
      'name_label': 'TEST\nR 33',
    },
  };
}

Widget _buildApp(
  AirspaceActivityStatus? status, {
  String locale = 'en',
  AupAirspaceActivity? activity,
}) {
  final Map<String, AupAirspaceActivity> activities = activity != null
      ? {'asp_test1': activity}
      : (status != null ? {'asp_test1': _activity(status)} : const {});

  return ProviderScope(
    overrides: [
      airspaceMetadataProvider(
        'asp_test1',
        'SK',
      ).overrideWith((ref) async => _metadata()),
      airspaceActivityProvider.overrideWithValue(activities),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(locale),
      home: Scaffold(body: AirspaceDetailsDialog(features: [_feature()])),
    ),
  );
}

void main() {
  testWidgets(
    'AirspaceDetailsDialog renders Active status badge and time window',
    (WidgetTester tester) async {
      // Fixed "now" inside the 08:00–16:00 UTC validity window.
      await withClock(Clock.fixed(DateTime.utc(2026, 8, 2, 12)), () async {
        await tester.pumpWidget(_buildApp(AirspaceActivityStatus.active));
        await tester.pumpAndSettle();

        expect(find.text('Active'), findsOneWidget);
        expect(find.text('R 33'), findsWidgets);
        expect(find.text('SVK_LZPS'), findsOneWidget);
        // Time window label + formatted HH:mm UTC – HH:mm UTC.
        expect(find.text('Validity: '), findsOneWidget);
        expect(find.textContaining('08:00 UTC'), findsOneWidget);
        expect(find.textContaining('16:00 UTC'), findsOneWidget);
      });
    },
  );

  testWidgets(
    'AirspaceDetailsDialog renders Inactive when the validity window expired',
    (WidgetTester tester) async {
      final expired = _activity(
        AirspaceActivityStatus.active,
        validFrom: DateTime.utc(2026, 8, 2, 8),
        validTo: DateTime.utc(2026, 8, 2, 16),
      );
      // Fixed "now" after the validity window ended -> effective status is
      // Inactive even though the AUP entry itself is marked active.
      await withClock(Clock.fixed(DateTime.utc(2026, 8, 2, 18)), () async {
        await tester.pumpWidget(_buildApp(null, activity: expired));
        await tester.pumpAndSettle();

        expect(find.text('Inactive'), findsOneWidget);
        expect(find.text('Active'), findsNothing);
        // The window itself is still displayed.
        expect(find.textContaining('16:00 UTC'), findsOneWidget);
      });
    },
  );

  testWidgets('AirspaceDetailsDialog renders Inactive status badge', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildApp(AirspaceActivityStatus.inactive));
    await tester.pumpAndSettle();

    expect(find.text('Inactive'), findsOneWidget);
    expect(find.textContaining('08:00 UTC'), findsOneWidget);
  });

  testWidgets(
    'AirspaceDetailsDialog renders Unknown status badge (Slovak locale)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(AirspaceActivityStatus.unknown, locale: 'sk'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aktivita neznáma'), findsOneWidget);
      // The validity row is rendered even for unknown status; match the full
      // rendered label ('Platnosť: ') as produced by _buildInfoRow.
      expect(find.text('Platnosť: '), findsOneWidget);
      expect(find.textContaining('08:00 UTC'), findsOneWidget);
    },
  );

  testWidgets(
    'AirspaceDetailsDialog shows no status badge when activity is unknown',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildApp(null));
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsNothing);
      expect(find.text('Inactive'), findsNothing);
      expect(find.text('Activity Unknown'), findsNothing);
    },
  );

  testWidgets(
    'AirspaceDetailCard refreshes the status badge when time crosses a '
    'validity boundary',
    (WidgetTester tester) async {
      // Mutable "now" so the fixed validity window (08:00–16:00 UTC) can be
      // crossed while the dialog stays open.
      var now = DateTime.utc(2026, 8, 2, 7); // Before the window.
      await withClock(Clock(() => now), () async {
        await tester.pumpWidget(
          _buildApp(null, activity: _activity(AirspaceActivityStatus.active)),
        );
        await tester.pumpAndSettle();

        // Before the window -> effective status is Inactive.
        expect(find.text('Inactive'), findsOneWidget);
        expect(find.text('Active'), findsNothing);

        // Move into the validity window; the periodic 30 s refresh must flip
        // the badge without any new fetch.
        now = DateTime.utc(2026, 8, 2, 12);
        await tester.pump(const Duration(seconds: 31));
        await tester.pump();

        expect(find.text('Active'), findsOneWidget);
        expect(find.text('Inactive'), findsNothing);
      });
    },
  );
}
