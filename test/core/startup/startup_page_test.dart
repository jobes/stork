import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/startup/application_bootstrap.dart';
import 'package:stork/core/startup/application_runtime.dart';
import 'package:stork/core/startup/first_frame_startup.dart';
import 'package:stork/core/startup/startup_page.dart';
import 'package:stork/core/startup/map_startup_provider.dart';
import 'package:stork/core/theme/app_theme.dart';
import 'package:stork/features/map/presentation/pages/map_page.dart';
import 'package:stork/features/settings/presentation/providers/display_preferences_provider.dart';
import 'package:stork/l10n/app_localizations.dart';
import 'package:stork/main.dart';

class _Preferences extends DisplayPreferencesNotifier {
  @override
  Future<DisplayPreferences> build() async =>
      (themeMode: ThemeMode.light, language: AppLanguage.slovak, saving: false);
}

void main() {
  setUpAll(() async {
    for (final entry in {
      'Roboto': ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf'],
      'MaterialIcons': ['MaterialIcons-Regular.otf'],
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final name in entry.value) {
        loader.addFont(
          File('test/visual/fonts/$name')
              .readAsBytes()
              .then(ByteData.sublistView),
        );
      }
      await loader.load();
    }
  });
  testWidgets(
    'first frame has our loader without constructing a Material app',
    (tester) async {
      await tester.pumpWidget(
        FirstFrameStartup(
          appBuilder: (_) => const MaterialApp(home: SizedBox.shrink()),
        ),
      );
      expect(find.byType(StartupContent), findsOneWidget);
      expect(find.byType(MaterialApp), findsNothing);
      expect(find.byType(Theme), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('loader paints before runtime configuration starts', (
    tester,
  ) async {
    final pending = Completer<void>();
    var runtimeStarts = 0;
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
      (_) async => const StandardMessageCodec().encodeMessage([null]),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          displayPreferencesProvider.overrideWith(_Preferences.new),
          applicationConfigurationProvider.overrideWith((_) {
            runtimeStarts++;
            return pending.future;
          }),
        ],
        child: const StorkApp(),
      ),
    );
    expect(find.byType(StartupPage), findsOneWidget);
    expect(runtimeStarts, 0);
    await tester.pump();
    expect(runtimeStarts, 1);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Pripravujeme mapu'), findsOneWidget);
    expect(find.byType(MapPage), findsNothing);
    await tester.pump(
      MapStartup.preparationBudget - const Duration(seconds: 10),
    );
    expect(find.text('Príprava sa nepodarila'), findsOneWidget);
    expect(find.text('Skúsiť znova'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete();
    await tester.pump();
  });

  testWidgets('first frame paints the loader before starting preparation', (
    tester,
  ) async {
    final pending = Completer<PreparedApplication>();
    var starts = 0;
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
      (_) async => const StandardMessageCodec().encodeMessage([null]),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          displayPreferencesProvider.overrideWith(_Preferences.new),
          applicationRuntimeProvider.overrideWith((_) async => false),
          applicationBootstrapProvider.overrideWith((_) {
            starts++;
            return pending.future;
          }),
        ],
        child: const StorkApp(),
      ),
    );
    expect(find.byType(StartupPage), findsOneWidget);
    expect(starts, 0);
    expect(find.byType(MapPage), findsNothing);
    await tester.pump();
    expect(starts, 1);
    await tester.pump(const Duration(seconds: 10));
    expect(find.byType(MapPage), findsNothing);
    expect(find.text('Pripravujeme mapu'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(const PreparedApplication());
    await tester.pump();
  });

  testWidgets('failed preparation can be retried without creating the map', (
    tester,
  ) async {
    final pending = Completer<PreparedApplication>();
    var starts = 0;
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
      (_) async => const StandardMessageCodec().encodeMessage([null]),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          displayPreferencesProvider.overrideWith(_Preferences.new),
          applicationRuntimeProvider.overrideWith((_) async => false),
          applicationBootstrapProvider.overrideWith((_) {
            starts++;
            return starts == 1
                ? Future.error(StateError('local data unavailable'))
                : pending.future;
          }),
        ],
        child: const StorkApp(),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Príprava sa nepodarila'), findsOneWidget);
    await tester.tap(find.text('Skúsiť znova'));
    await tester.pump();
    await tester.pump();
    expect(starts, 2);
    expect(find.text('Pripravujeme mapu'), findsOneWidget);
    expect(find.byType(MapPage), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(const PreparedApplication());
    await tester.pump();
  });

  for (final (name, size, dark, scale, failed) in [
    ('portrait-light', const Size(390, 844), false, 1.0, false),
    ('portrait-dark', const Size(390, 844), true, 1.0, false),
    ('landscape-large-text', const Size(844, 390), false, 1.5, false),
    ('portrait-error', const Size(320, 568), true, 1.5, true),
  ]) {
    testWidgets('startup layout $name fits without overflow', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const capture = ValueKey('startup-capture');
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          locale: const Locale('sk'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (_, child) => MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(scale),
            ),
            child: child!,
          ),
          home: RepaintBoundary(
            key: capture,
            child: StartupPage(failed: failed, onRetry: () {}),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('STORK NAV'), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as AssetImage).assetName,
        dark ? 'assets/images/app_icon_dark.png' : 'assets/images/app_icon.png',
      );
      if (const bool.fromEnvironment('STORK_CAPTURE_STARTUP')) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(capture),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('/tmp/stork-startup-$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
