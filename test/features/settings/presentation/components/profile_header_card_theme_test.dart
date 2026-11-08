import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/theme/app_theme.dart';
import 'package:stork/features/settings/domain/models/aircraft.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/domain/models/pilot.dart';
import 'package:stork/features/settings/presentation/components/profile_header_card.dart';
import 'package:stork/l10n/app_localizations.dart';

void main() {
  testWidgets('profile header follows shared theme and preserves selectors', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProfileHeaderCard(
              settings: const AppSettings(),
              activePilot: null,
              activeAircraft: null,
              aircraftHoursAsync: null,
              pilotsAsync: const AsyncData<List<Pilot>>(<Pilot>[]),
              aircraftsAsync: const AsyncData<List<Aircraft>>(<Aircraft>[]),
              unlockedPilotId: null,
              onPilotUnlocked: (_) {},
            ),
          ),
        ),
      ),
    );

    final color = AppTheme.lightTheme.colorScheme.primary;
    final containers = tester.widgetList<Container>(
      find.descendant(
        of: find.byType(ProfileHeaderCard),
        matching: find.byType(Container),
      ),
    );
    expect(
      containers.any((container) {
        final decoration = container.decoration;
        return decoration is BoxDecoration && decoration.color == color;
      }),
      isTrue,
    );
    // Both pilot and aircraft selectors still expose their dropdown affordance.
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNWidgets(2));
  });
}
