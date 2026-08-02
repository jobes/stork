import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../telemetry/presentation/providers/gdl90_provider.dart';
import '../providers/settings_provider.dart';

class Gdl90SettingsCard extends ConsumerStatefulWidget {
  const Gdl90SettingsCard({super.key});

  @override
  ConsumerState<Gdl90SettingsCard> createState() => _Gdl90SettingsCardState();
}

class _Gdl90SettingsCardState extends ConsumerState<Gdl90SettingsCard> {
  late TextEditingController _ipController;
  late TextEditingController _portController;
  late final FocusNode _ipFocusNode;
  late final FocusNode _portFocusNode;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController();
    _portController = TextEditingController();
    _ipFocusNode = FocusNode();
    _portFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _ipFocusNode.dispose();
    _portFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isGdl90Active =
        ref.watch(gdl90HeartbeatActiveProvider).value ?? false;

    return settingsAsync.when(
      data: (settings) {
        // Populate fields only while the user is not editing them, so a
        // rebuild never overwrites text the user is currently typing.
        if (_ipController.text.isEmpty && !_ipFocusNode.hasFocus) {
          _ipController.text = settings.gdl90BindIp;
        }
        if (_portController.text.isEmpty && !_portFocusNode.hasFocus) {
          _portController.text = settings.gdl90UdpPort.toString();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text(
                l10n.gdl90EnableTitle,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(l10n.gdl90EnableDesc),
              value: settings.gdl90Enabled,
              onChanged: (val) {
                ref.read(appSettingsProvider.notifier).updateGdl90Enabled(val);
              },
            ),
            if (settings.gdl90Enabled) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                child: Row(
                  children: [
                    Text(
                      '${l10n.gdl90StatusTitle}: ',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isGdl90Active ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isGdl90Active
                          ? l10n.gdl90StatusActive
                          : l10n.gdl90StatusInactive,
                      style: TextStyle(
                        color: isGdl90Active
                            ? Colors.green
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _ipController,
                        focusNode: _ipFocusNode,
                        decoration: InputDecoration(
                          labelText: l10n.gdl90BindIpTitle,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (val) async {
                          final result = await ref
                              .read(appSettingsProvider.notifier)
                              .updateGdl90BindIp(val);
                          if (result is SettingsUpdateSuccess) {
                            final saved = ref.read(appSettingsProvider).value;
                            if (saved != null) {
                              _ipController.text = saved.gdl90BindIp;
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _portController,
                        focusNode: _portFocusNode,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.gdl90PortTitle,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (val) async {
                          final parsedPort = int.tryParse(val);
                          if (parsedPort == null) return;
                          final result = await ref
                              .read(appSettingsProvider.notifier)
                              .updateGdl90UdpPort(parsedPort);
                          if (result is SettingsUpdateSuccess) {
                            final saved = ref.read(appSettingsProvider).value;
                            if (saved != null) {
                              _portController.text = saved.gdl90UdpPort
                                  .toString();
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.gdl90TargetExpiryTitle,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${settings.gdl90TargetExpirySeconds} s',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: settings.gdl90TargetExpirySeconds.toDouble().clamp(
                        10.0,
                        300.0,
                      ),
                      min: 10.0,
                      max: 300.0,
                      divisions: 29, // 10s steps
                      onChanged: (val) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .updateGdl90TargetExpirySeconds(val.round());
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
