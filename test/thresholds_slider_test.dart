import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/settings/domain/range_thresholds.dart';
import 'package:stork/features/settings/presentation/widgets/thresholds_slider.dart';
import 'package:stork/l10n/app_localizations.dart';

ThresholdState mockEvaluate(double value) => ThresholdState.operational;

void main() {
  testWidgets(
    'ThresholdsSlider changes activeThumbIndex during panning and clears it on pan end',
    (WidgetTester tester) async {
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
                  evaluate: mockEvaluate,
                  onChanged: (values) {
                    updatedValues = values;
                  },
                  unitLabel: 'kph',
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

      // Start gesture near the 40.0 thumb by getting the center of ThresholdsSlider and offsetting left
      final sliderCenter = tester.getCenter(find.byType(ThresholdsSlider));
      final gesture = await tester.startGesture(
        sliderCenter + const Offset(-30.0, 0.0),
      );
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
    },
  );

  testWidgets(
    'ThresholdsSlider changes activeThumbIndex during panning and clears it on pan cancel',
    (WidgetTester tester) async {
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
                  evaluate: mockEvaluate,
                  onChanged: (_) {},
                  unitLabel: 'kph',
                ),
              ),
            ),
          ),
        ),
      );

      // Start gesture near the 40.0 thumb by getting the center of ThresholdsSlider and offsetting left
      final sliderCenter = tester.getCenter(find.byType(ThresholdsSlider));
      final gesture = await tester.startGesture(
        sliderCenter + const Offset(-30.0, 0.0),
      );
      await tester.pump();

      // Update gesture (move slightly to trigger onPanUpdate which calls setState and repaints)
      await gesture.moveBy(const Offset(30.0, 0.0));
      await tester.pump();

      // The painter should now have activeThumbIndex as 1 after the rebuild
      var customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(ThresholdsSlider),
          matching: find.byType(CustomPaint),
        ),
      );
      var painter = customPaint.painter as dynamic;
      expect(painter.activeThumbIndex, equals(1));

      // Cancel gesture (triggers onPanCancel, which should call setState to repaint)
      await gesture.cancel();
      await tester.pump();

      // After gesture is canceled, activeThumbIndex must be null in the painter
      customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(ThresholdsSlider),
          matching: find.byType(CustomPaint),
        ),
      );
      painter = customPaint.painter as dynamic;
      expect(painter.activeThumbIndex, isNull);
    },
  );

  testWidgets(
    '_MultiThumbPainter shouldRepaint responds correctly to localeTag changes',
    (WidgetTester tester) async {
      // 1. Pump in 'en' locale
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
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
                  evaluate: mockEvaluate,
                  onChanged: (_) {},
                  unitLabel: 'kph',
                ),
              ),
            ),
          ),
        ),
      );

      final customPaintEn = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(ThresholdsSlider),
          matching: find.byType(CustomPaint),
        ),
      );
      final painterEn = customPaintEn.painter as dynamic;
      expect(painterEn.localeTag, equals('en'));

      // 2. Pump again with the same locale ('en') to get a second painter with identical state
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
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
                  evaluate: mockEvaluate,
                  onChanged: (_) {},
                  unitLabel: 'kph',
                ),
              ),
            ),
          ),
        ),
      );

      final customPaintEn2 = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(ThresholdsSlider),
          matching: find.byType(CustomPaint),
        ),
      );
      final painterEn2 = customPaintEn2.painter as dynamic;
      expect(painterEn.shouldRepaint(painterEn2), isFalse);

      // 3. Pump with a different locale ('sk')
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('sk'),
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
                  evaluate: mockEvaluate,
                  onChanged: (_) {},
                  unitLabel: 'kph',
                ),
              ),
            ),
          ),
        ),
      );

      final customPaintSk = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(ThresholdsSlider),
          matching: find.byType(CustomPaint),
        ),
      );
      final painterSk = customPaintSk.painter as dynamic;
      expect(painterSk.localeTag, equals('sk'));

      // 4. Verify that shouldRepaint returns true when compared against the 'en' painter
      expect(painterSk.shouldRepaint(painterEn), isTrue);
    },
  );

  testWidgets('ThresholdsSlider handles zero/negative width without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 0.0,
              child: ThresholdsSlider(
                values: const [20.0, 40.0, 60.0],
                min: 0.0,
                max: 100.0,
                evaluate: mockEvaluate,
                onChanged: (_) {},
                unitLabel: 'kph',
              ),
            ),
          ),
        ),
      ),
    );

    // Verify it doesn't crash on initial layout and paint
    expect(find.byType(ThresholdsSlider), findsOneWidget);

    // Attempt a gesture.
    final sliderCenter = tester.getCenter(find.byType(ThresholdsSlider));
    final gesture = await tester.startGesture(sliderCenter);
    await tester.pump();
    await gesture.moveBy(const Offset(10.0, 0.0));
    await tester.pump();
    await gesture.up();
    await tester.pump();
  });

  testWidgets(
    'ThresholdsSlider handles invalid range (max <= min) without crashing',
    (WidgetTester tester) async {
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
                  min: 100.0,
                  max: 50.0,
                  evaluate: mockEvaluate,
                  onChanged: (_) {},
                  unitLabel: 'kph',
                ),
              ),
            ),
          ),
        ),
      );

      // Verify it doesn't crash on layout and paint
      expect(find.byType(ThresholdsSlider), findsOneWidget);

      // Attempt a gesture
      final sliderCenter = tester.getCenter(find.byType(ThresholdsSlider));
      final gesture = await tester.startGesture(sliderCenter);
      await tester.pump();
      await gesture.moveBy(const Offset(30.0, 0.0));
      await tester.pump();
      await gesture.up();
      await tester.pump();
    },
  );
}
