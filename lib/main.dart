import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'l10n/app_localizations.dart';

import 'package:wakelock_plus/wakelock_plus.dart';

import 'core/services/map_assets_server.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'package:stork/core/services/cannelloni_service.dart';
import 'package:stork/core/utils/time_utils.dart';
import 'package:stork/features/map/domain/utils/fir_utils.dart';
import 'package:stork/features/map/presentation/providers/airspace_activity_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/black_box_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';

Future<void> main() async {
  appStopwatch.start();
  SentryWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  Future<void> runStartup() async {
    await FirUtils.initialize();
    if (!kIsWeb) {
      await MapAssetsServer.start();
    }
  }

  final sentryDsn = dotenv.env['SENTRY_DSN']?.trim();
  if (sentryDsn == null || sentryDsn.isEmpty) {
    await runStartup();
    runApp(const ProviderScope(child: StorkApp()));
  } else {
    try {
      await SentryFlutter.init(
        (options) {
          options.dsn = sentryDsn;
          options.environment = kReleaseMode ? 'release' : 'debug';
          options.tracesSampleRate = 1.0;
          options.replay.onErrorSampleRate = 1.0;
        },
        appRunner: () async {
          await runStartup();
          runApp(SentryWidget(child: const ProviderScope(child: StorkApp())));
        },
      );
    } catch (error) {
      debugPrint(
        'Sentry init failed (DSN set but unusable); running without Sentry: '
        '$error',
      );
      await runStartup();
      runApp(const ProviderScope(child: StorkApp()));
    }
  }
}

class StorkApp extends ConsumerStatefulWidget {
  const StorkApp({super.key});

  @override
  ConsumerState<StorkApp> createState() => _StorkAppState();
}

class _StorkAppState extends ConsumerState<StorkApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: 'app session started',
        category: 'app',
        level: SentryLevel.info,
      ),
    );
    ref.read(cannelloniServiceProvider);
    ref.read(blackBoxServiceProvider);
    ref.read(gpsListenerProvider);
    ref.read(airspaceActivityProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WakelockPlus.enable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('sk')],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
