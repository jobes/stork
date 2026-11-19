import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'startup_timing.dart';

/// Configuration precedes services that capture API keys at creation.
final applicationConfigurationProvider = FutureProvider<void>(
  (_) => measureStartup('Configuration', () => dotenv.load(fileName: '.env')),
  retry: (_, _) => null,
);

/// Starts after the first loader frame, alongside local map preparation.
final applicationRuntimeProvider = FutureProvider<bool>((ref) async {
  await ref.watch(applicationConfigurationProvider.future);
  return measureStartup('Monitoring', _initializeMonitoring);
}, retry: (_, _) => null);

Future<bool> _initializeMonitoring() async {
  final dsn = dotenv.env['SENTRY_DSN']?.trim();
  if (dsn == null || dsn.isEmpty) return false;

  try {
    // main() already mounted the loader in a guarded zone. Initializing without
    // appRunner installs the SDK integrations without mounting a second app.
    await SentryFlutter.init((options) {
      options.dsn = dsn;
      options.environment = kReleaseMode ? 'release' : 'debug';
      options.tracesSampleRate = 1.0;
      options.replay.onErrorSampleRate = kReleaseMode ? 1.0 : 0.0;
    });
    await Sentry.addBreadcrumb(
      Breadcrumb(
        message: 'app session started',
        category: 'app',
        level: SentryLevel.info,
      ),
    );
    return true;
  } catch (error) {
    debugPrint('Sentry init failed; running without monitoring: $error');
    return false;
  }
}
