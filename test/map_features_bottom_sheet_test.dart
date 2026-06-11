import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stork/features/map/presentation/components/map_features_bottom_sheet.dart';
import 'package:stork/features/map/presentation/components/airport_details_dialog.dart';
import 'package:stork/features/map/presentation/providers/airport_metadata_provider.dart';
import 'package:stork/l10n/app_localizations.dart';

void main() {
  testWidgets('MapFeaturesBottomSheet passes correct fallbackName - null name_label', (WidgetTester tester) async {
    final features = [
      {
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
}
