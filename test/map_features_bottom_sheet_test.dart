import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stork/features/map/presentation/components/map_features_bottom_sheet.dart';
import 'package:stork/features/map/presentation/components/airport_details_dialog.dart';
import 'package:stork/features/map/presentation/components/airspace_details_dialog.dart';
import 'package:stork/features/map/presentation/providers/airport_metadata_provider.dart';
import 'package:stork/features/map/presentation/providers/airspace_metadata_provider.dart';
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
}
