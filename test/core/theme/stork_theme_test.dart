import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/services/cannelloni_service_io.dart';
import 'package:stork/core/theme/app_theme.dart';
import 'package:stork/core/widgets/stork_navigation_tile.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/presentation/pages/settings_page.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/l10n/app_localizations.dart';

class _Settings extends AppSettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

class _DisconnectedGateway extends CannelloniService {
  @override
  bool build() => false;
}

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

  testWidgets('Settings shows the four sections and the gateway state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsProvider.overrideWith(_Settings.new),
          cannelloniServiceProvider.overrideWith(_DisconnectedGateway.new),
        ],
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
    expect(
      tester
          .widgetList<StorkNavigationTile>(find.byType(StorkNavigationTile))
          .map((tile) => tile.title),
      [
        'Map',
        'Units and limits',
        'Traffic and alerts',
        'Instruments and connection',
      ],
    );
    expect(find.text('Gateway disconnected'), findsOneWidget);
  });
}
