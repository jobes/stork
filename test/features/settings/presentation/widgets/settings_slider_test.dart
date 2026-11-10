import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/settings/presentation/widgets/settings_widgets.dart';

Future<void> _pumpSlider(
  WidgetTester tester,
  ScrollController scroll,
  ValueChanged<double> onChanged,
) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListView(
          controller: scroll,
          children: [
            const SizedBox(height: 160),
            SettingsSlider(
              value: 52,
              min: 0,
              max: 100,
              divisions: 10,
              onChanged: onChanged,
            ),
            const SizedBox(height: 1000),
          ],
        ),
      ),
    ),
  );
}

void main() {
  for (final startOnThumb in [false, true]) {
    testWidgets(
      'scrolling from the slider preserves the value (thumb: $startOnThumb)',
      (tester) async {
        final scroll = ScrollController();
        addTearDown(scroll.dispose);
        final changes = <double>[];
        await _pumpSlider(tester, scroll, changes.add);

        final slider = tester.getRect(find.byType(SettingsSlider));
        final start = startOnThumb
            ? slider.center
            : Offset(slider.left + slider.width * .75, slider.center.dy);
        final gesture = await tester.startGesture(start);
        // Reproduce the tap-down deadline before the vertical scroll begins.
        await tester.pump(const Duration(milliseconds: 150));
        await gesture.moveBy(const Offset(3, -35));
        await tester.pump(const Duration(milliseconds: 16));
        await gesture.moveBy(const Offset(5, -95));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(scroll.offset, greaterThan(0));
        expect(changes, isEmpty);
      },
    );
  }

  testWidgets(
    'a tap preserves the value and a horizontal thumb drag changes it',
    (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final changes = <double>[];
      await _pumpSlider(tester, scroll, changes.add);

      final slider = tester.getRect(find.byType(SettingsSlider));
      await tester.tapAt(
        Offset(slider.left + slider.width * .75, slider.center.dy),
      );
      await tester.tapAt(slider.center);
      await tester.pumpAndSettle();
      expect(changes, isEmpty);

      await tester.dragFrom(slider.center, Offset(slider.width * .25, 0));
      await tester.pumpAndSettle();
      expect(changes, isNotEmpty);
      expect(changes.last, greaterThan(52));
      expect(scroll.offset, 0);
    },
  );
}
