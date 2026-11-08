import 'package:flutter/material.dart';

/// The consistent, responsive canvas used by every settings subpage.
///
/// Scrolling belongs to the page, not to each card. This allows long forms
/// (especially flight thresholds) to remain one uninterrupted workflow.
class StorkSettingsPageContent extends StatelessWidget {
  final List<Widget> children;

  const StorkSettingsPageContent({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          for (final child in children) ...[child, const SizedBox(height: 16)],
        ],
      ),
    );
  }
}

/// Group related controls without imposing any new navigation step.
///
/// The heading sits outside the surface so it doesn't compete with the
/// interactive labels inside it. Children keep their original callbacks.
class StorkSettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const StorkSettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}
