import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'features/settings/presentation/providers/display_preferences_provider.dart';
import 'l10n/app_localizations.dart';

import 'package:wakelock_plus/wakelock_plus.dart';

import 'core/startup/application_bootstrap.dart';
import 'core/startup/application_runtime.dart';
import 'core/startup/first_frame_startup.dart';
import 'core/startup/deferred_startup_tasks.dart';
import 'core/startup/startup_page.dart';
import 'core/services/protomaps_resolver.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'package:stork/core/utils/time_utils.dart';

void main() {
  runZonedGuarded(
    () {
      appStopwatch.start();
      SentryWidgetsFlutterBinding.ensureInitialized();
      runApp(
        FirstFrameStartup(
          appBuilder: (_) => const ProviderScope(child: StorkApp()),
        ),
      );
    },
    (error, stackTrace) {
      debugPrint('Unhandled application error: $error\n$stackTrace');
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
    },
  );
}

class StorkApp extends ConsumerStatefulWidget {
  const StorkApp({super.key});

  @override
  ConsumerState<StorkApp> createState() => _StorkAppState();
}

class _StorkAppState extends ConsumerState<StorkApp>
    with WidgetsBindingObserver {
  bool _bootstrapStarted = false;
  bool _onlineScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(deferredStartupTasksProvider).hold();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(WakelockPlus.enable());
      setState(() => _bootstrapStarted = true);
    });
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

  Future<void> _refreshCatalog(DeferredStartupTasks tasks) async {
    await tasks.waitFor(StartupTask.catalog);
    if (!mounted) return;
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      await ProtomapsResolver.refreshForNextLaunch(prefs);
    } catch (error) {
      debugPrint('Could not refresh map catalog: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(displayPreferencesProvider).value;
    final bootstrap = _bootstrapStarted
        ? ref.watch(applicationBootstrapProvider)
        : const AsyncLoading<PreparedApplication>();
    if (_bootstrapStarted) {
      ref.listen(applicationBootstrapProvider, (_, next) {
        if (next case AsyncError(:final error, :final stackTrace)) {
          debugPrint('Application startup failed: $error\n$stackTrace');
        }
      });
    }
    final ready = bootstrap is AsyncData<PreparedApplication>;
    if (ready && !_onlineScheduled) {
      _onlineScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        bootstrap.requireValue.releaseMapPreparation?.call();
        final tasks = ref.read(deferredStartupTasksProvider);
        tasks.releaseAfterFirstFrame();
        unawaited(_refreshCatalog(tasks));
      });
    }
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: preferences?.language.locale,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: preferences?.themeMode ?? ThemeMode.system,
      routerConfig: appRouter,
      builder: (context, child) => ready
          ? ref.read(applicationRuntimeProvider).value == true
                ? SentryWidget(child: child!)
                : child!
          : StartupPage(
              failed: bootstrap.hasError && !bootstrap.isLoading,
              onRetry: () {
                retryApplicationBootstrap(
                  ProviderScope.containerOf(context, listen: false),
                );
              },
            ),
      debugShowCheckedModeBanner: false,
    );
  }
}
