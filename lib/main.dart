import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'l10n/app_localizations.dart';

import 'package:wakelock_plus/wakelock_plus.dart';

import 'core/services/map_assets_server.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'package:stork/core/services/cannelloni_service.dart';
import 'package:stork/core/utils/time_utils.dart';

Future<void> main() async {
  appStopwatch.start();
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  if (!kIsWeb) {
    await MapAssetsServer.start();
  }
  runApp(const ProviderScope(child: StorkApp()));
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
    // Initial enable of the wakelock
    WakelockPlus.enable();
    // Warm up the Cannelloni service at startup so it runs in the background
    ref.read(cannelloniServiceProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-enable wakelock when returning to the app to ensure it's active
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
