import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/settings/presentation/widgets/max_range_input.dart';
import 'package:stork/l10n/app_localizations.dart';

void main() {
  testWidgets('MaxRangeInput loads localized suffix correctly and triggers callbacks in English', (WidgetTester tester) async {
    final controller = TextEditingController(text: '100');
    final focusNode = FocusNode();
    bool submitted = false;
    bool incremented = false;
    bool decremented = false;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Center(
            child: MaxRangeInput(
              currentValue: 100.0,
              controller: controller,
              focusNode: focusNode,
              onSubmitted: () {
                submitted = true;
              },
              onIncrement: () {
                incremented = true;
              },
              onDecrement: () {
                decremented = true;
              },
            ),
          ),
        ),
      ),
    );

    // Verify it renders the TextField with localized suffixText
    expect(find.byType(TextField), findsOneWidget);
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.decoration?.suffixText, equals(' km/h'));

    // Test increment callback
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();
    expect(incremented, isTrue);

    // Test decrement callback
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pump();
    expect(decremented, isTrue);
  });

  testWidgets('MaxRangeInput loads localized suffix correctly in Slovak', (WidgetTester tester) async {
    final controller = TextEditingController(text: '100');
    final focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('sk'),
        home: Scaffold(
          body: Center(
            child: MaxRangeInput(
              currentValue: 100.0,
              controller: controller,
              focusNode: focusNode,
              onSubmitted: () {},
              onIncrement: () {},
              onDecrement: () {},
            ),
          ),
        ),
      ),
    );

    // Verify it renders the TextField with localized suffixText in Slovak
    expect(find.byType(TextField), findsOneWidget);
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.decoration?.suffixText, equals(' km/h'));
  });
}
