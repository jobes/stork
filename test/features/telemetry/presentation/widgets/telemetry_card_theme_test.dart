import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/theme/app_theme.dart';
import 'package:stork/features/settings/data/repositories/settings_repository.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/domain/models/range_thresholds.dart';
import 'package:stork/features/telemetry/presentation/widgets/telemetry_card.dart';

class _SettingsRepo implements SettingsRepository {
  _SettingsRepo(this.settings);
  AppSettings settings;

  @override
  Future<AppSettings> getSettings() async => settings;

  @override
  Future<void> saveSettings(AppSettings next) async {
    settings = next;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required ThemeData theme,
  required ThresholdState state,
  bool draggable = false,
  VoidCallback? onTap,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      key: ValueKey(draggable),
      overrides: [
        settingsRepositoryProvider.overrideWith(
          (ref) async =>
              _SettingsRepo(AppSettings(areWidgetsDraggable: draggable)),
        ),
      ],
      child: MaterialApp(
        theme: theme,
        home: Scaffold(
          body: TelemetryCard(
            state: state,
            disableAnimations: true,
            onTap: onTap,
            child: const Text('108'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

BoxDecoration _decoration(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration!
        as BoxDecoration;

void main() {
  testWidgets('neutral overlay inherits the shared theme', (tester) async {
    await _pumpCard(
      tester,
      theme: AppTheme.darkTheme,
      state: ThresholdState.operational,
    );
    final d = _decoration(tester);
    expect(d.border!.top.color, AppTheme.darkTheme.colorScheme.outlineVariant);
    expect(d.border!.top.width, 2);
    expect((d.gradient! as LinearGradient).colors, [
      AppTheme.darkTheme.colorScheme.surfaceContainerLow,
      AppTheme.darkTheme.colorScheme.surface,
    ]);
  });

  testWidgets('critical and warning borders do not inherit brand primary', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      theme: AppTheme.darkTheme,
      state: ThresholdState.maxError,
    );
    expect(_decoration(tester).border!.top.color, Colors.redAccent.shade400);
    expect(
      (_decoration(tester).gradient! as LinearGradient).colors.map((c) => c.a),
      everyElement(1.0),
    );
    await _pumpCard(
      tester,
      theme: AppTheme.darkTheme,
      state: ThresholdState.maxWarning,
    );
    expect(_decoration(tester).border!.top.color, Colors.orangeAccent);
    expect(
      (_decoration(tester).gradient! as LinearGradient).colors.map((c) => c.a),
      everyElement(1.0),
    );
  });

  testWidgets('card tap is suppressed in layout edit mode', (tester) async {
    var taps = 0;
    await _pumpCard(
      tester,
      theme: AppTheme.lightTheme,
      state: ThresholdState.operational,
      onTap: () => taps++,
    );
    await tester.tap(find.text('108'));
    expect(taps, 1);

    await _pumpCard(
      tester,
      theme: AppTheme.lightTheme,
      state: ThresholdState.operational,
      draggable: true,
      onTap: () => taps++,
    );
    await tester.tap(find.text('108'));
    expect(taps, 1);
  });
}
