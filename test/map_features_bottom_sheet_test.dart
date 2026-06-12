import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stork/features/map/presentation/components/map_features_bottom_sheet.dart';
import 'package:stork/features/map/presentation/components/airport_details_dialog.dart';
import 'package:stork/features/map/presentation/components/airspace_details_dialog.dart';
import 'package:stork/features/map/presentation/providers/airport_metadata_provider.dart';
import 'package:stork/features/map/presentation/providers/airspace_metadata_provider.dart';
import 'package:stork/features/map/domain/airspace_metadata.dart';
import 'package:stork/features/map/domain/airport_metadata.dart';
import 'package:stork/l10n/app_localizations.dart';

void main() {
  testWidgets('MapFeaturesBottomSheet passes correct fallbackName - null name_label', (WidgetTester tester) async {
    final features = [
      {
        'layerType': 'airport',
        'properties': {
          'source_id': '123',
          'country': 'US',
        }
      }
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          airportMetadataProvider('123', 'US').overrideWith((ref) async => null),
          openAipApiKeyProvider.overrideWith((ref) => 'test-key'),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MapFeaturesBottomSheet(features: features),
          ),
        ),
      ),
    );

    // Tap on the ListTile to show dialog
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    final dialog = tester.widget<AirportDetailsDialog>(find.byType(AirportDetailsDialog));
    expect(dialog.fallbackName, equals(''));
  });

  testWidgets('MapFeaturesBottomSheet passes correct fallbackName - single line name_label', (WidgetTester tester) async {
    final features = [
      {
        'layerType': 'airport',
        'properties': {
          'source_id': '123',
          'country': 'US',
          'name_label': 'My Airport',
        }
      }
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          airportMetadataProvider('123', 'US').overrideWith((ref) async => null),
          openAipApiKeyProvider.overrideWith((ref) => 'test-key'),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MapFeaturesBottomSheet(features: features),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    final dialog = tester.widget<AirportDetailsDialog>(find.byType(AirportDetailsDialog));
    expect(dialog.fallbackName, equals('My Airport'));
  });

  testWidgets('MapFeaturesBottomSheet passes correct fallbackName - multi line name_label', (WidgetTester tester) async {
    final features = [
      {
        'layerType': 'airport',
        'properties': {
          'source_id': '123',
          'country': 'US',
          'name_label': 'Primary Name\nSecondary Name',
        }
      }
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          airportMetadataProvider('123', 'US').overrideWith((ref) async => null),
          openAipApiKeyProvider.overrideWith((ref) => 'test-key'),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MapFeaturesBottomSheet(features: features),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    final dialog = tester.widget<AirportDetailsDialog>(find.byType(AirportDetailsDialog));
    expect(dialog.fallbackName, equals('Secondary Name'));
  });

  testWidgets('MapFeaturesBottomSheet passes correct fallbackName - non-string name_label', (WidgetTester tester) async {
    final features = [
      {
        'layerType': 'airport',
        'properties': {
          'source_id': '123',
          'country': 'US',
          'name_label': 98765,
        }
      }
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          airportMetadataProvider('123', 'US').overrideWith((ref) async => null),
          openAipApiKeyProvider.overrideWith((ref) => 'test-key'),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MapFeaturesBottomSheet(features: features),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    final dialog = tester.widget<AirportDetailsDialog>(find.byType(AirportDetailsDialog));
    expect(dialog.fallbackName, equals('98765'));
  });

  testWidgets('MapFeaturesBottomSheet does not show airport details when only airspace is present', (WidgetTester tester) async {
    final features = [
      {
        'layerType': 'airspace',
        'properties': {
          'source_id': 'abc-airspace',
          'country': 'US',
          'name': 'Restricted Airspace',
        }
      }
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          openAipApiKeyProvider.overrideWith((ref) => 'test-key'),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MapFeaturesBottomSheet(features: features),
          ),
        ),
      ),
    );

    // Verify "Airport Details" is NOT present, but "Airspaces" IS present
    expect(find.text('Airport Details'), findsNothing);
    expect(find.text('Airspaces'), findsOneWidget);
  });

  testWidgets('AirspaceDetailsDialog sorts airspaces descending by height', (WidgetTester tester) async {
    final features = [
      {
        'layerType': 'airspace',
        'properties': {
          'source_id': 'asp-low',
          'country': 'SK',
          'name_label': 'Low Airspace',
          'upper_limit_value': 2000,
          'upper_limit_unit': 'ft',
          'lower_limit_value': 0,
          'lower_limit_unit': 'ft',
        }
      },
      {
        'layerType': 'airspace',
        'properties': {
          'source_id': 'asp-high',
          'country': 'SK',
          'name_label': 'High Airspace',
          'upper_limit_value': 120,
          'upper_limit_unit': 'FL',
          'lower_limit_value': 5000,
          'lower_limit_unit': 'ft',
        }
      },
      {
        'layerType': 'airspace',
        'properties': {
          'source_id': 'asp-medium',
          'country': 'SK',
          'name_label': 'Medium Airspace',
          'upper_limit_value': 5000,
          'upper_limit_unit': 'ft',
          'lower_limit_value': 2000,
          'lower_limit_unit': 'ft',
        }
      },
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          airspaceMetadataProvider('asp-high', 'SK').overrideWith((ref) async => null),
          airspaceMetadataProvider('asp-medium', 'SK').overrideWith((ref) async => null),
          airspaceMetadataProvider('asp-low', 'SK').overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AirspaceDetailsDialog(features: features),
          ),
        ),
      ),
    );

    expect(find.text('High Airspace'), findsOneWidget);
    expect(find.text('Medium Airspace'), findsOneWidget);
    expect(find.text('Low Airspace'), findsOneWidget);

    final highTop = tester.getTopLeft(find.text('High Airspace')).dy;
    final mediumTop = tester.getTopLeft(find.text('Medium Airspace')).dy;
    final lowTop = tester.getTopLeft(find.text('Low Airspace')).dy;

    // Descending order means highest top is physically on top (smaller dy value)
    expect(highTop < mediumTop, isTrue);
    expect(mediumTop < lowTop, isTrue);
  });

  testWidgets('AirspaceDetailsDialog sorts airspaces with equal ceilings by lower floor (lower floor first)', (WidgetTester tester) async {
    final features = [
      {
        'layerType': 'airspace',
        'properties': {
          'source_id': 'asp-higher-floor',
          'country': 'SK',
          'name_label': 'Higher Floor Airspace',
          'upper_limit_value': 5000,
          'upper_limit_unit': 'ft',
          'lower_limit_value': 2000,
          'lower_limit_unit': 'ft',
        }
      },
      {
        'layerType': 'airspace',
        'properties': {
          'source_id': 'asp-lower-floor',
          'country': 'SK',
          'name_label': 'Lower Floor Airspace',
          'upper_limit_value': 5000,
          'upper_limit_unit': 'ft',
          'lower_limit_value': 1000,
          'lower_limit_unit': 'ft',
        }
      },
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          airspaceMetadataProvider('asp-higher-floor', 'SK').overrideWith((ref) async => null),
          airspaceMetadataProvider('asp-lower-floor', 'SK').overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AirspaceDetailsDialog(features: features),
          ),
        ),
      ),
    );

    expect(find.text('Lower Floor Airspace'), findsOneWidget);
    expect(find.text('Higher Floor Airspace'), findsOneWidget);

    final lowerFloorTop = tester.getTopLeft(find.text('Lower Floor Airspace')).dy;
    final higherFloorTop = tester.getTopLeft(find.text('Higher Floor Airspace')).dy;

    // Lower floor should be placed first, so its dy should be smaller
    expect(lowerFloorTop < higherFloorTop, isTrue);
  });

  testWidgets('AirspaceDetailsDialog _buildLoading shows localized fallback name', (WidgetTester tester) async {
    final features = [
      {
        'layerType': 'airspace',
        'properties': {
          'source_id': 'asp-loading',
          'country': 'SK',
          'name_label': '',
        }
      },
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Keep the metadata in loading state by returning a pending future
          airspaceMetadataProvider('asp-loading', 'SK').overrideWith((ref) {
            final completer = Completer<AirspaceMetadata?>();
            return completer.future;
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: AirspaceDetailsDialog(features: features),
          ),
        ),
      ),
    );

    // Verify it shows "Airspace" (from English l10n.airspace)
    expect(find.text('Airspace'), findsOneWidget);
    expect(find.text('Loading airspace details...'), findsOneWidget);
  });

  testWidgets('AirspaceDetailsDialog _buildLoading shows Slovak localized fallback name', (WidgetTester tester) async {
    final features = [
      {
        'layerType': 'airspace',
        'properties': {
          'source_id': 'asp-loading',
          'country': 'SK',
          'name_label': '',
        }
      },
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Keep the metadata in loading state by returning a pending future
          airspaceMetadataProvider('asp-loading', 'SK').overrideWith((ref) {
            final completer = Completer<AirspaceMetadata?>();
            return completer.future;
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('sk'),
          home: Scaffold(
            body: AirspaceDetailsDialog(features: features),
          ),
        ),
      ),
    );

    // Verify it shows "Letecký priestor" (from Slovak l10n.airspace)
    expect(find.text('Letecký priestor'), findsOneWidget);
    expect(find.text('Načítavam detaily leteckých priestorov...'), findsOneWidget);
  });

  testWidgets('AirspaceDetailsDialog renders with Flexible limit texts and overflow ellipsis', (WidgetTester tester) async {
    final features = [
      {
        'layerType': 'airspace',
        'properties': {
          'source_id': 'asp-limits-test',
          'country': 'SK',
          'name_label': 'Limits Test Airspace',
        }
      },
    ];

    final mockMetadata = AirspaceMetadata(
      id: 'asp-limits-test',
      name: 'Limits Test Airspace',
      icaoClass: AirspaceClass.c,
      type: AirspaceType.ctr,
      country: 'SK',
      limitLower: AirspaceLimit(
        value: 1000.0,
        unit: OpenAipUnit.feet,
        referenceDatum: ReferenceDatum.gnd,
      ),
      limitUpper: AirspaceLimit(
        value: 99999.0,
        unit: OpenAipUnit.feet,
        referenceDatum: ReferenceDatum.msl,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          airspaceMetadataProvider('asp-limits-test', 'SK').overrideWith((ref) async => mockMetadata),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: AirspaceDetailsDialog(features: features),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify metadata text is shown
    expect(find.text('Limits Test Airspace'), findsOneWidget);

    // Verify limit texts exist
    expect(find.text('1000 ft GND'), findsOneWidget);
    expect(find.text('99999 ft MSL'), findsOneWidget);

    // Find the limits row text widgets
    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    final limitLowerText = textWidgets.firstWhere((t) => t.data == '1000 ft GND');
    final limitUpperText = textWidgets.firstWhere((t) => t.data == '99999 ft MSL');

    expect(limitLowerText.overflow, equals(TextOverflow.ellipsis));
    expect(limitLowerText.maxLines, equals(1));
    expect(limitLowerText.softWrap, isFalse);

    expect(limitUpperText.overflow, equals(TextOverflow.ellipsis));
    expect(limitUpperText.maxLines, equals(1));
    expect(limitUpperText.softWrap, isFalse);
  });
}
