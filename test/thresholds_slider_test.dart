import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/settings/presentation/widgets/thresholds_slider.dart';
import 'package:stork/l10n/app_localizations.dart';


void main() {
  testWidgets('ThresholdsSlider changes activeThumbIndex during panning and clears it on pan end', (WidgetTester tester) async {
    List<double> updatedValues = [];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: ThresholdsSlider(
                values: const [20.0, 40.0, 60.0],
                min: 0.0,
                max: 100.0,
                onChanged: (values) {
                  updatedValues = values;
                },
              ),
            ),
          ),
        ),
      ),
    );

    // Initial state: activeThumbIndex should be null
    var customPaint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(ThresholdsSlider),
        matching: find.byType(CustomPaint),
      ),
    );
    var painter = customPaint.painter as dynamic;
    expect(painter.activeThumbIndex, isNull);

    // Start gesture at the center of the slider (corresponding to 50.0 value, near the 40.0 thumb at index 1)
    final gesture = await tester.startGesture(tester.getCenter(find.byType(ThresholdsSlider)));
    await tester.pump();

    // Update gesture (move slightly to trigger onPanUpdate which calls setState and repaints)
    await gesture.moveBy(const Offset(30.0, 0.0));
    await tester.pump();

    expect(updatedValues, isNotEmpty);

    // The painter should now have activeThumbIndex as 1 after the rebuild
    customPaint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(ThresholdsSlider),
        matching: find.byType(CustomPaint),
      ),
    );
    painter = customPaint.painter as dynamic;
    expect(painter.activeThumbIndex, equals(1));

    // End gesture (triggers onPanEnd, which now calls setState to repaint)
    await gesture.up();
    await tester.pump();

    // After gesture ends, activeThumbIndex must be null in the painter
    customPaint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(ThresholdsSlider),
        matching: find.byType(CustomPaint),
      ),
    );
    painter = customPaint.painter as dynamic;
    expect(painter.activeThumbIndex, isNull);
  });
}
