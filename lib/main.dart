import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'features/settings/presentation/providers/display_preferences_provider.dart';
import 'l10n/localizations.dart';

import 'package:wakelock_plus/wakelock_plus.dart';

import 'core/startup/application_bootstrap.dart';
import 'core/startup/application_runtime.dart';
import 'core/startup/first_frame_startup.dart';
import 'core/startup/deferred_startup_tasks.dart';
import 'core/startup/startup_page.dart';
import 'core/startup/map_startup_provider.dart';
import 'core/startup/startup_timing.dart';
import 'core/services/protomaps_resolver.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/widgets/linux_window_icon.dart';

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
  int? _handoffAttempt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    appRouter.routerDelegate.addListener(_onRouteChanged);
    ref.read(deferredStartupTasksProvider).hold();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(mapStartupProvider.notifier).start();
      unawaited(WakelockPlus.enable());
      setState(() => _bootstrapStarted = true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRouter.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final startup = ref.read(mapStartupProvider);
      if (_handoffAttempt == startup.attempt &&
          appRouter.routerDelegate.currentConfiguration.uri.path != '/') {
        ref.read(mapStartupProvider.notifier).ready(startup.attempt);
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
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
    final startup = ref.watch(mapStartupProvider);
    if (_bootstrapStarted) {
      ref.listen(applicationBootstrapProvider, (_, next) {
        if (next case AsyncError(:final error, :final stackTrace)) {
          debugPrint('Application startup failed: $error\n$stackTrace');
          ref.read(mapStartupProvider.notifier).fail(startup.attempt, error);
        }
      });
    }
    final prepared =
        bootstrap is AsyncData<PreparedApplication> && !bootstrap.isLoading;
    // Start monitoring once local preparation is complete, alongside the native
    // map rather than competing with the FIR parser and local reads. Its stable
    // wrapper is already mounted and monitoring never gates map readiness.
    if (prepared) ref.watch(applicationRuntimeProvider);
    if (prepared && _handoffAttempt != startup.attempt) {
      _handoffAttempt = startup.attempt;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            ref.read(mapStartupProvider).attempt != startup.attempt) {
          return;
        }
        bootstrap.requireValue.releaseMapPreparation?.call();
        final gate = ref.read(mapStartupProvider.notifier);
        gate.rendering(startup.attempt);
        // A deep link to another page has no native map to wait for.
        if (appRouter.routerDelegate.currentConfiguration.uri.path != '/') {
          gate.ready(startup.attempt);
        }
      });
    }
    if (startup.ready && !_onlineScheduled) {
      _onlineScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        startupMilestone('Interactive');
        final tasks = ref.read(deferredStartupTasksProvider);
        tasks.releaseAfterFirstFrame();
        unawaited(_refreshCatalog(tasks));
      });
    }
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: preferences?.language.locale,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: preferences?.themeMode ?? ThemeMode.system,
      routerConfig: appRouter,
      builder: (context, child) => LinuxWindowIcon(
        child: SentryWidget(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (prepared)
                ExcludeSemantics(
                  excluding: !startup.ready,
                  child: ExcludeFocus(
                    excluding: !startup.ready,
                    child: IgnorePointer(
                      key: const ValueKey('startup-interaction-gate'),
                      ignoring: !startup.ready,
                      child: child!,
                    ),
                  ),
                ),
              if (!startup.ready)
                StartupPage(
                  failed:
                      startup.failed ||
                      (bootstrap.hasError && !bootstrap.isLoading),
                  onRetry: () {
                    ref.read(mapStartupProvider.notifier).start();
                    retryApplicationBootstrap(
                      ProviderScope.containerOf(context, listen: false),
                      retryPending: true,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
