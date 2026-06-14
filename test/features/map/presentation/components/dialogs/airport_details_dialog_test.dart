import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stork/features/map/presentation/components/dialogs/airport_details_dialog.dart';
import 'package:stork/features/map/presentation/providers/airport_metadata_provider.dart';
import 'package:stork/features/map/domain/airport_metadata.dart';
import 'package:stork/l10n/app_localizations.dart';

void main() {
  testWidgets('AirportDetailsDialog localized fallback title (loading state) - en vs sk', (WidgetTester tester) async {
    final completer = Completer<AirportMetadata?>();

    // ENGLISH locale
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          airportMetadataProvider('123', 'US').overrideWith((ref) => completer.future),
          openAipApiKeyProvider.overrideWith((ref) => 'test-key'),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(
            body: AirportDetailsDialog(
              airportId: '123',
              countryCode: 'US',
              fallbackName: '', // Empty fallbackName triggers the localized fallback title
            ),
          ),
        ),
      ),
    );

    // Verify it is loading, and show localized fallback title "Airport"
    expect(find.text('Airport'), findsOneWidget);

    // SLOVAK locale
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          airportMetadataProvider('123', 'US').overrideWith((ref) => completer.future),
          openAipApiKeyProvider.overrideWith((ref) => 'test-key'),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('sk'),
          home: const Scaffold(
            body: AirportDetailsDialog(
              airportId: '123',
              countryCode: 'US',
              fallbackName: '',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Letisko'), findsOneWidget);
  });

  testWidgets('AirportDetailsDialog localized fallback title (error state) - en vs sk', (WidgetTester tester) async {
    // ENGLISH locale
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          airportMetadataProvider('123', 'US').overrideWith((ref) async => throw Exception('error')),
          openAipApiKeyProvider.overrideWith((ref) => 'test-key'),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(
            body: AirportDetailsDialog(
              airportId: '123',
              countryCode: 'US',
              fallbackName: '',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Airport'), findsOneWidget);

    // SLOVAK locale
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          airportMetadataProvider('123', 'US').overrideWith((ref) async => throw Exception('error')),
          openAipApiKeyProvider.overrideWith((ref) => 'test-key'),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('sk'),
          home: const Scaffold(
            body: AirportDetailsDialog(
              airportId: '123',
              countryCode: 'US',
              fallbackName: '',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Letisko'), findsOneWidget);
  });

  testWidgets('AirportDetailsDialog localized badges - en vs sk', (WidgetTester tester) async {
    final metadata = AirportMetadata(
      id: '123',
      name: 'Test Airport',
      icaoCode: 'LZIB',
      type: AirportType.airport,
      trafficType: const [],
      country: 'SK',
      frequencies: [
        AirportFrequency(
          id: 'freq1',
          value: '123.45',
          unit: OpenAipUnit.mhz,
          type: FrequencyType.tower,
          name: 'TWR',
          primary: true,
          publicUse: true,
        ),
      ],
      runways: [
        AirportRunway(
          id: 'rwy1',
          designator: '31',
          trueHeading: 310,
          alignedTrueNorth: true,
          operations: 0,
          mainRunway: true,
          turnDirection: 0,
          takeOffOnly: false,
          landingOnly: false,
          pilotCtrlLighting: false,
          surface: RunwaySurface(
            composition: const [RunwayComposition.grass],
            mainComposite: RunwayComposition.grass,
            condition: 0,
          ),
        ),
      ],
      images: const [],
    );

    // ENGLISH locale
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          airportMetadataProvider('123', 'US').overrideWith((ref) async => metadata),
          openAipApiKeyProvider.overrideWith((ref) => 'test-key'),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(
            body: AirportDetailsDialog(
              airportId: '123',
              countryCode: 'US',
              fallbackName: '',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('TUNE'), findsOneWidget);
    expect(find.text('Main runway'), findsOneWidget);

    // SLOVAK locale
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          airportMetadataProvider('123', 'US').overrideWith((ref) async => metadata),
          openAipApiKeyProvider.overrideWith((ref) => 'test-key'),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('sk'),
          home: const Scaffold(
            body: AirportDetailsDialog(
              airportId: '123',
              countryCode: 'US',
              fallbackName: '',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('NALADIŤ'), findsOneWidget);
    expect(find.text('Hlavná dráha'), findsOneWidget);
  });
}
