import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/core/router/app_router.dart';
import 'package:stork/core/services/cannelloni_service.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/presentation/pages/data_sources_page.dart';
import 'package:stork/features/settings/presentation/pages/settings_page.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/l10n/app_localizations.dart';

import '../../../../helpers/source_logo_http.dart';

class _Settings extends AppSettingsNotifier {
  @override
  AppSettings build() => const AppSettings(autoSelectDevice: false);
}

class _Gateway extends CannelloniService {
  @override
  bool build() => false;
}

void main() {
  testWidgets('sources tile, back button and direct route use the app router', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await withSourceLogos(SourceLogoState.failed, () async {
      appRouter.go('/settings');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsProvider.overrideWith(_Settings.new),
            cannelloniServiceProvider.overrideWith(_Gateway.new),
          ],
          child: MaterialApp.router(
            routerConfig: appRouter,
            locale: const Locale('sk'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Zdroje dát'), 200);
      await tester.tap(find.text('Zdroje dát'));
      await tester.pumpAndSettle();
      expect(find.byType(DataSourcesPage), findsOneWidget);
      expect(
        appRouter.routerDelegate.currentConfiguration.last.matchedLocation,
        '/settings/data-sources',
      );
      expect(find.text('Mapy a terén'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(
        appRouter.routerDelegate.currentConfiguration.uri.path,
        '/settings',
      );

      appRouter.go('/settings/data-sources');
      await tester.pumpAndSettle();
      expect(find.byType(DataSourcesPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
