import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/theme/app_theme.dart';
import 'package:stork/features/settings/presentation/widgets/stork_settings_section.dart';

void main() {
  for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
    testWidgets('section preserves all controls with no extra navigation', (
      tester,
    ) async {
      var count = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: StorkSettingsPageContent(
              children: [
                StorkSettingsSection(
                  title: 'Test group',
                  children: [
                    SwitchListTile(
                      title: const Text('Toggle'),
                      value: true,
                      onChanged: (_) => count++,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Test group'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      await tester.tap(find.text('Toggle'));
      expect(count, 1);
    });
  }
}
