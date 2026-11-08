import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/theme/app_theme.dart';
import 'package:stork/core/widgets/stork_navigation_tile.dart';
import 'package:stork/features/settings/presentation/pages/settings_page.dart';
import 'package:stork/l10n/app_localizations.dart';

void main() {
  test('light and dark themes share a visual system', () {
    expect(AppTheme.lightTheme.brightness, Brightness.light);
    expect(AppTheme.darkTheme.brightness, Brightness.dark);
    expect(
      AppTheme.lightTheme.colorScheme.primary,
      isNot(AppTheme.darkTheme.colorScheme.primary),
    );
    expect(AppTheme.lightTheme.cardTheme.shape, isNotNull);
    expect(AppTheme.darkTheme.cardTheme.shape, isNotNull);
  });

  testWidgets('Settings retains the existing four destinations', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(StorkNavigationTile), findsNWidgets(4));
    expect(find.byIcon(Icons.router_outlined), findsOneWidget);
  });
}
