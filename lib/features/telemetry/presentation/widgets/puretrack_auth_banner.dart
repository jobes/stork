import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/puretrack_auth_service.dart';
import '../providers/puretrack_auth_provider.dart';

class PureTrackAuthBanner extends ConsumerWidget {
  const PureTrackAuthBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(pureTrackProvider);
    if (authState != PureTrackAuthState.tokenInvalid) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.errorContainer,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              try {
                context.push('/settings/traffic');
              } catch (_) {
                try {
                  context.push('/settings');
                } catch (_) {}
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: theme.colorScheme.onErrorContainer,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.pureTrackSessionExpiredBanner,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
