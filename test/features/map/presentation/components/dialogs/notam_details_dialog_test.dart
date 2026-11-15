import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/map/domain/models/notam.dart';
import 'package:stork/features/map/domain/repositories/notam_repository.dart';
import 'package:stork/features/map/presentation/components/dialogs/notam_details_dialog.dart';
import 'package:stork/features/map/presentation/providers/notams_provider.dart';
import 'package:stork/l10n/app_localizations.dart';

class _Notams extends Notams {
  _Notams(this.initial, {this.save});

  final List<Notam> initial;
  final Completer<bool>? save;
  int attempts = 0;

  @override
  Future<NotamFetchResult> build() async => NotamFetchResult(initial);

  void publish(List<Notam> notams) =>
      state = AsyncData(NotamFetchResult(notams));

  @override
  Future<bool> hideNotam(Notam notam) async {
    attempts++;
    final saved = save == null ? attempts == 2 : await save!.future;
    if (saved) {
      publish(
        state.requireValue.notams
            .where((item) => item.key != notam.key)
            .toList(),
      );
    }
    return saved;
  }
}

Future<void> _openDialog(
  WidgetTester tester,
  _Notams notams,
  List<Notam> selected,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [notamsProvider.overrideWith(() => notams)],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => NotamDetailsDialog(notams: selected),
              ),
              child: const Text('Open NOTAM'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open NOTAM'));
  await tester.pumpAndSettle();
}

void main() {
  final start = DateTime.utc(2026, 11, 15);
  final first = Notam(id: 'A1234/26', from: start);
  final second = Notam(id: 'A1235/26', from: start);
  final unrelated = Notam(id: 'A1236/26', from: start);

  testWidgets('shows save failure and lets the pilot retry hiding a NOTAM', (
    tester,
  ) async {
    final notams = _Notams([first]);
    await _openDialog(tester, notams, [first]);

    final hide = find.widgetWithText(ElevatedButton, 'Hide');
    await tester.ensureVisible(hide);
    await tester.tap(hide);
    await tester.pumpAndSettle();

    expect(find.text('Could not save the preference.'), findsOneWidget);
    expect(find.byType(NotamDetailsDialog), findsOneWidget);
    expect(tester.widget<ElevatedButton>(hide).onPressed, isNotNull);

    await tester.tap(hide);
    await tester.pumpAndSettle();

    expect(notams.attempts, 2);
    expect(find.byType(NotamDetailsDialog), findsNothing);
  });

  testWidgets('closes when the other selected NOTAM disappears during save', (
    tester,
  ) async {
    final save = Completer<bool>();
    final notams = _Notams([first, second], save: save);
    await _openDialog(tester, notams, [first, second]);

    final hide = find.widgetWithText(ElevatedButton, 'Hide').first;
    await tester.ensureVisible(hide);
    await tester.tap(hide);
    notams.publish([first, unrelated]);
    await tester.pump();
    save.complete(true);
    await tester.pumpAndSettle();

    expect(find.byType(NotamDetailsDialog), findsNothing);
  });

  testWidgets('duplicate Hide completions only close the NOTAM dialog', (
    tester,
  ) async {
    final save = Completer<bool>();
    final notams = _Notams([first], save: save);
    await _openDialog(tester, notams, [first]);

    final hide = find.widgetWithText(ElevatedButton, 'Hide');
    await tester.ensureVisible(hide);
    await tester.tap(hide);
    await tester.tap(hide);
    expect(notams.attempts, 2);

    save.complete(true);
    await tester.pumpAndSettle();

    expect(find.byType(NotamDetailsDialog), findsNothing);
    expect(find.text('Open NOTAM'), findsOneWidget);
  });

  testWidgets('stays open when another selected NOTAM appears during save', (
    tester,
  ) async {
    final save = Completer<bool>();
    final notams = _Notams([first], save: save);
    await _openDialog(tester, notams, [first, second]);

    final hide = find.widgetWithText(ElevatedButton, 'Hide');
    await tester.ensureVisible(hide);
    await tester.tap(hide);
    notams.publish([first, second]);
    await tester.pump();
    save.complete(true);
    await tester.pumpAndSettle();

    expect(find.byType(NotamDetailsDialog), findsOneWidget);
    expect(find.textContaining(second.id), findsOneWidget);
    expect(find.textContaining(first.id), findsNothing);
  });
}
