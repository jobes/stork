import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:stork/features/settings/presentation/widgets/number_input.dart';

void main() {
  testWidgets('NumberInput parses decimal inputs in German locale correctly', (
    WidgetTester tester,
  ) async {
    double? lastChangedValue;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de', 'DE'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('de', 'DE'), Locale('en', 'US')],
        home: Scaffold(
          body: Center(
            child: NumberInput(
              initialValue: 1.5,
              min: 0.0,
              max: 10.0,
              step: 0.5,
              decimalPlaces: 1,
              onChanged: (val) {
                lastChangedValue = val;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // The initial controller text is formatted with the German locale, which
    // uses a comma as the decimal separator.
    expect(find.text('1,5'), findsOneWidget);

    // Enter a new value using a comma: "2,5"
    await tester.enterText(find.byType(TextField), '2,5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Verify that value was successfully parsed via NumberFormat.decimalPattern and changed to 2.5
    expect(lastChangedValue, equals(2.5));
    expect(find.text('2,5'), findsOneWidget);

    // Enter another valid value using a comma: "3,8"
    await tester.enterText(find.byType(TextField), '3,8');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(lastChangedValue, equals(3.8));

    // Test fallback on parse exception (e.g. invalid string 'abc')
    // It should keep/restore the last valid value (3.8)
    await tester.enterText(find.byType(TextField), 'abc');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(lastChangedValue, equals(3.8));
    expect(find.text('3,8'), findsOneWidget);
  });

  testWidgets(
    'NumberInput parses decimal inputs in US English locale correctly',
    (WidgetTester tester) async {
      double? lastChangedValue;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en', 'US'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('de', 'DE'), Locale('en', 'US')],
          home: Scaffold(
            body: Center(
              child: NumberInput(
                initialValue: 1.5,
                min: 0.0,
                max: 10.0,
                step: 0.5,
                decimalPlaces: 1,
                onChanged: (val) {
                  lastChangedValue = val;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1.5'), findsOneWidget);

      // Enter a new value with a period: "3.5"
      await tester.enterText(find.byType(TextField), '3.5');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Verify that value was successfully parsed and changed to 3.5
      expect(lastChangedValue, equals(3.5));
      expect(find.text('3.5'), findsOneWidget);
    },
  );
}
