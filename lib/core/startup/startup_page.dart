import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

class StartupPage extends StatelessWidget {
  const StartupPage({super.key, this.failed = false, this.onRetry});
  final bool failed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: StartupContent(
      l10n: AppLocalizations.of(context)!,
      colors: Theme.of(context).colorScheme,
      failed: failed,
      onRetry: onRetry,
      progress: const SizedBox(width: 164, child: LinearProgressIndicator()),
    ),
  );
}

/// Shared by the very first, unthemed frame and the application's loader.
/// Keep the normal loading branch independent of Theme/MaterialApp/router.
class StartupContent extends StatelessWidget {
  const StartupContent({
    super.key,
    required this.l10n,
    required this.colors,
    required this.progress,
    this.failed = false,
    this.onRetry,
  });

  final AppLocalizations l10n;
  final ColorScheme colors;
  final Widget progress;
  final bool failed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: colors.surface,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.appTitle.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
                color: colors.onSurface,
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            colors.brightness == Brightness.dark
                                ? 'assets/images/app_icon_dark.png'
                                : 'assets/images/app_icon.png',
                            width: 96,
                            height: 96,
                            excludeFromSemantics: true,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          failed ? l10n.startupFailed : l10n.startupPreparing,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          failed
                              ? l10n.startupFailedDescription
                              : l10n.startupDescription,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            height: 1.35,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 28),
                        if (failed)
                          FilledButton(
                            onPressed: onRetry,
                            child: Text(l10n.startupRetry),
                          )
                        else
                          progress,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Text(
              l10n.startupFooter,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                height: 1.35,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
