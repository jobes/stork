import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stork/core/widgets/linux_window_icon.dart';

void main() {
  const channel = MethodChannel('com.inskycore.stork/window_icon');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Widget app(ThemeMode mode) => MaterialApp(
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    themeMode: mode,
    builder: (_, child) => LinuxWindowIcon(child: child!),
    home: const SizedBox(),
  );

  testWidgets('switches icon with application theme without restarting', (
    tester,
  ) async {
    await tester.pumpWidget(app(ThemeMode.light));
    await tester.pumpAndSettle();
    expect(calls.single.method, 'setDarkIcon');
    expect(calls.single.arguments, false);

    await tester.pumpWidget(app(ThemeMode.dark));
    await tester.pumpAndSettle();
    expect(calls.map((call) => call.arguments), [false, true]);

    await tester.pumpWidget(app(ThemeMode.dark));
    await tester.pumpAndSettle();
    expect(calls, hasLength(2));

    await tester.pumpWidget(app(ThemeMode.light));
    await tester.pumpAndSettle();
    expect(calls.map((call) => call.arguments), [false, true, false]);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('follows system brightness in system theme mode', (tester) async {
    final dispatcher = tester.binding.platformDispatcher;
    addTearDown(dispatcher.clearPlatformBrightnessTestValue);
    dispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpWidget(app(ThemeMode.system));
    await tester.pumpAndSettle();
    dispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    dispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(calls.map((call) => call.arguments), [false, true, false]);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('does not invoke the Linux channel on Android', (tester) async {
    await tester.pumpWidget(app(ThemeMode.dark));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
