import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/dronecan_devices/domain/models/dronecan_parameter.dart';
import 'package:stork/features/dronecan_devices/presentation/dialogs/dronecan_parameter_edit_dialog.dart';
import 'package:stork/l10n/app_localizations.dart';

void main() {
  for (final input in ['1e309', '-1e309', '3.5e38', '-3.5e38']) {
    testWidgets('rejects real overflow $input without node bounds', (
      tester,
    ) async {
      final result = await _submit(tester, input);

      expect(result(), isNull);
      expect(find.text('Enter a valid number.'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  }

  for (final input in ['3.4028234663852886e38', '-3.4028234663852886e38']) {
    testWidgets('accepts finite float32 boundary $input', (tester) async {
      final result = await _submit(tester, input);

      expect(result(), DroneCanParamValue.real(double.parse(input)));
      expect(find.byType(TextField), findsNothing);
    });
  }

  testWidgets('preserves bounds checks for finite real values', (tester) async {
    final result = await _submit(tester, '11', bounded: true);

    expect(result(), isNull);
    expect(find.text('Value must be between -10 and 10.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '1,25');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(result(), const DroneCanParamValue.real(1.25));
  });
}

Future<DroneCanParamValue? Function()> _submit(
  WidgetTester tester,
  String input, {
  bool bounded = false,
}) async {
  DroneCanParamValue? result;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDroneCanParameterEditDialog(
                context,
                parameter: DroneCanParameter(
                  index: 0,
                  name: 'REAL_PARAM',
                  value: const DroneCanParamValue.real(0),
                  minValue: bounded ? -10 : null,
                  maxValue: bounded ? 10 : null,
                ),
              );
            },
            child: const Text('Edit'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Edit'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), input);
  await tester.tap(find.widgetWithText(FilledButton, 'Save'));
  await tester.pumpAndSettle();
  return () => result;
}
