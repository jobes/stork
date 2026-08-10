import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../telemetry/data/puretrack_auth_service.dart';
import '../../../telemetry/presentation/providers/puretrack_auth_provider.dart';

class PureTrackSettingsCard extends ConsumerStatefulWidget {
  const PureTrackSettingsCard({super.key});

  @override
  ConsumerState<PureTrackSettingsCard> createState() =>
      _PureTrackSettingsCardState();
}

class _PureTrackSettingsCardState extends ConsumerState<PureTrackSettingsCard> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = ref.read(pureTrackAuthServiceProvider);
      if (authService.currentUsername != null) {
        _usernameController.text = authService.currentUsername!;
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final l10n = AppLocalizations.of(context)!;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = l10n.pureTrackStatusError;
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    final result = await ref
        .read(pureTrackProvider.notifier)
        .login(username, password);

    if (!result.isSuccess && mounted) {
      setState(() {
        _errorMessage = result.errorMessage ?? l10n.pureTrackStatusError;
      });
    }
  }

  Future<void> _handleLogout() async {
    await ref.read(pureTrackProvider.notifier).logout();
    if (!mounted) return;
    _passwordController.clear();
    setState(() {
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(pureTrackProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final pureTrackEnabled = settingsAsync.value?.pureTrackEnabled ?? true;
    final authService = ref.read(pureTrackAuthServiceProvider);
    if (_usernameController.text.isEmpty &&
        authService.currentUsername != null) {
      _usernameController.text = authService.currentUsername!;
    }
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final isAuthenticated = authState == PureTrackAuthState.authenticated;
    final isAuthenticating = authState == PureTrackAuthState.authenticating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(
            l10n.pureTrackEnableTitle,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(l10n.pureTrackEnableDesc),
          value: pureTrackEnabled,
          onChanged: (val) {
            ref.read(appSettingsProvider.notifier).updatePureTrackEnabled(val);
          },
        ),
        if (pureTrackEnabled)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.satellite_alt_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.pureTrackTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              l10n.pureTrackDescription,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(context, authState, l10n),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!isAuthenticated) ...[
                    TextField(
                      controller: _usernameController,
                      enabled: !isAuthenticating,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l10n.pureTrackUsername,
                        prefixIcon: const Icon(Icons.person_outline),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      enabled: !isAuthenticating,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: l10n.pureTrackPassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isAuthenticating ? null : _handleLogin,
                        child: isAuthenticating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.pureTrackLogin),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _usernameController.text.isNotEmpty
                                  ? _usernameController.text
                                  : l10n.pureTrackStatusConnected,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout),
                        label: Text(l10n.pureTrackLogout),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    PureTrackAuthState state,
    AppLocalizations l10n,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color bgColor;
    final Color textColor;
    final String label;

    switch (state) {
      case PureTrackAuthState.authenticated:
        bgColor = colorScheme.primaryContainer;
        textColor = colorScheme.onPrimaryContainer;
        label = l10n.pureTrackStatusConnected;
        break;
      case PureTrackAuthState.authenticating:
        bgColor = colorScheme.secondaryContainer;
        textColor = colorScheme.onSecondaryContainer;
        label = l10n.pureTrackStatusAuthenticating;
        break;
      case PureTrackAuthState.tokenInvalid:
        bgColor = colorScheme.tertiaryContainer;
        textColor = colorScheme.onTertiaryContainer;
        label = l10n.pureTrackStatusTokenInvalid;
        break;
      case PureTrackAuthState.error:
        bgColor = colorScheme.errorContainer;
        textColor = colorScheme.onErrorContainer;
        label = l10n.pureTrackStatusError;
        break;
      case PureTrackAuthState.unauthenticated:
        bgColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurfaceVariant;
        label = l10n.pureTrackStatusDisconnected;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
