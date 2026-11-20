import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/stork_colors.dart';
import 'startup_page.dart';
import 'startup_timing.dart';

/// Paints our own loader before compiling/building the full application shell.
/// Merely scheduling full preparation post-frame can still contend with the
/// raster thread; wait until this small first frame has actually rasterized.
class FirstFrameStartup extends StatefulWidget {
  const FirstFrameStartup({super.key, required this.appBuilder});
  final WidgetBuilder appBuilder;

  @override
  State<FirstFrameStartup> createState() => _FirstFrameStartupState();
}

class _FirstFrameStartupState extends State<FirstFrameStartup> {
  bool _showApplication = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_afterFirstPaint());
    });
  }

  Future<void> _afterFirstPaint() async {
    await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
    if (mounted) {
      startupMilestone('First loader frame');
      setState(() => _showApplication = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showApplication) return widget.appBuilder(context);
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    final dark = dispatcher.platformBrightness == Brightness.dark;
    final locale = basicLocaleListResolution(
      dispatcher.locales,
      AppLocalizations.supportedLocales,
    );
    final colors = dark
        ? const ColorScheme.dark(
            primary: StorkColors.darkPrimary,
            surface: StorkColors.darkSurface,
            onSurface: Colors.white,
            onSurfaceVariant: Color(0xFFD1D5DB),
          )
        : const ColorScheme.light(
            primary: StorkColors.lightPrimary,
            surface: StorkColors.lightSurface,
            onSurface: Color(0xFF182934),
            onSurfaceVariant: Color(0xFF526976),
          );
    return MediaQuery.fromView(
      view: View.of(context),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: colors.onSurface,
          ),
          child: StartupContent(
            l10n: lookupAppLocalizations(locale),
            colors: colors,
            progress: Semantics(
              label: lookupAppLocalizations(locale).startupPreparing,
              child: SizedBox(
                width: 164,
                height: 3,
                child: ColoredBox(
                  color: colors.primary.withValues(alpha: 0.24),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
