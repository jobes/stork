import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/theme/app_theme.dart';
import 'package:stork/core/widgets/stork_detail_surface.dart';

void main() {
  for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
    testWidgets(
      'dialog panels use theme-neutral surfaces in ${theme.brightness}',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: Center(child: StorkDetailSurface(child: Text('Detail'))),
            ),
          ),
        );
        final surface = tester.widget<Container>(
          find
              .ancestor(
                of: find.text('Detail'),
                matching: find.byType(Container),
              )
              .first,
        );
        final decoration = surface.decoration! as BoxDecoration;
        expect(decoration.color, theme.colorScheme.surfaceContainerLow);
        expect(decoration.border!.top.color, theme.colorScheme.outlineVariant);
        expect(find.text('Detail'), findsOneWidget);
      },
    );
  }
}
