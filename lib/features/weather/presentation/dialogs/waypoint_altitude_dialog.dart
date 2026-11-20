import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/number_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';
import '../../../navigation/domain/models/navigation_point.dart';
import '../../../navigation/presentation/providers/navigation_provider.dart';
import '../../../settings/domain/models/speed_unit.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/forecast_profile.dart';
import '../../domain/forecast_route.dart';
import '../providers/flight_weather_provider.dart';

typedef _AltitudeResult = ({int? altitude});

/// Edits the forecast altitude for a waypoint. A `null` altitude means the
/// waypoint should use the selected aircraft's default.
Future<void> showWaypointAltitudeDialog(
  BuildContext context,
  WidgetRef ref, {
  required NavigationPoint waypoint,
  required int waypointIndex,
  required int? defaultFeet,
  ForecastRoutePoint? forecastPoint,
  DateTime? eta,
  ForecastProfile? series,
  ForecastReference? reference,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<_AltitudeResult>(
    context: context,
    builder: (_) => _WaypointAltitudeDialog(
      waypoint: waypoint,
      waypointName: waypoint.name,
      initial: waypoint.weatherAltitudeFeet,
      defaultFeet: defaultFeet,
      forecastPoint: forecastPoint,
      eta: eta,
      series: series,
      reference: reference,
    ),
  );
  if (result == null) return;
  try {
    final points =
        ref.read(navigationProvider).value?.points ?? const <NavigationPoint>[];
    final currentIndex = points.indexOf(waypoint);
    if (currentIndex < 0) throw StateError('Waypoint was removed');
    await ref
        .read(navigationProvider.notifier)
        .updatePointWeatherAltitude(currentIndex, result.altitude);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.weatherSaveFailed)));
    }
  }
}

class _WaypointAltitudeDialog extends ConsumerStatefulWidget {
  const _WaypointAltitudeDialog({
    required this.waypoint,
    required this.waypointName,
    required this.initial,
    required this.defaultFeet,
    required this.forecastPoint,
    required this.eta,
    required this.series,
    required this.reference,
  });

  final NavigationPoint waypoint;
  final String waypointName;
  final int? initial;
  final int? defaultFeet;
  final ForecastRoutePoint? forecastPoint;
  final DateTime? eta;
  final ForecastProfile? series;
  final ForecastReference? reference;

  @override
  ConsumerState<_WaypointAltitudeDialog> createState() =>
      _WaypointAltitudeDialogState();
}

class _WaypointAltitudeDialogState
    extends ConsumerState<_WaypointAltitudeDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _controller;
  late bool _useDefault;

  @override
  void initState() {
    super.initState();
    _useDefault = widget.initial == null;
    _controller = TextEditingController(
      text: (widget.initial ?? widget.defaultFeet)?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _selectedFeet =>
      _useDefault ? widget.defaultFeet : int.tryParse(_controller.text.trim());

  void _selectPreset(int feet) {
    setState(() {
      _useDefault = false;
      _controller.text = feet.toString();
    });
  }

  void _shiftAltitude(int delta) {
    final current = _selectedFeet ?? widget.defaultFeet ?? 0;
    _selectPreset(current + delta);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final number = NumberFormat.decimalPattern(l10n.localeName);
    final settings = ref.watch(appSettingsProvider).value;
    final speedUnit = settings?.windSpeedUnit ?? SpeedUnit.kmh;
    final feet = _selectedFeet;
    final route =
        ref.watch(navigationProvider).value?.points ??
        const <NavigationPoint>[];
    final currentIndex = route.indexOf(widget.waypoint);
    final point = widget.forecastPoint == null || currentIndex < 0
        ? null
        : forecastPointsByWaypoint(
            ref.watch(flightWeatherPlanProvider),
          )[currentIndex];
    final eta = widget.eta ?? point?.eta;
    final series = widget.series;
    final reference = point == null
        ? null
        : ref
              .watch(routeForecastReferenceProvider(point.id))
              .unwrapPrevious()
              .value;
    final forecast =
        series != null && eta != null && feet != null && reference != null
        ? series.atReference(
            eta,
            altitudeFeet: feet.toDouble(),
            reference: reference,
          )
        : null;
    final wind = forecast?.wind;
    final presets = <int>{?widget.defaultFeet, 1000, 2000, 3000, 5000};
    final defaultHint = widget.defaultFeet == null
        ? null
        : <Widget>[
            const SizedBox(height: 2),
            Text(
              l10n.altitudeAircraftDefault(number.format(widget.defaultFeet!)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ];

    return BaseDetailsDialog(
      titleText: l10n.weatherPlannedAltitude,
      icon: Icons.height,
      showCloseButton: false,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.waypointName,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            ...?defaultHint,
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text(l10n.altitudeDefaultOption),
                ),
                ButtonSegment(
                  value: false,
                  label: Text(l10n.altitudeCustomOption),
                ),
              ],
              selected: {_useDefault},
              onSelectionChanged: (selection) =>
                  setState(() => _useDefault = selection.first),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: _useDefault ? null : () => _shiftAltitude(-100),
                  icon: const Icon(Icons.remove),
                  tooltip: l10n.altitudeDecrease,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    enabled: !_useDefault,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      suffixText: l10n.weatherAltitudeFt,
                      isDense: true,
                    ),
                    validator: (value) {
                      if (_useDefault) return null;
                      final parsed = int.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed < -1000 || parsed > 30000) {
                        return l10n.weatherInvalidAltitude;
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _useDefault ? null : () => _shiftAltitude(100),
                  icon: const Icon(Icons.add),
                  tooltip: l10n.altitudeIncrease,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in presets)
                  ChoiceChip(
                    label: Text(l10n.altitudeChipValue(number.format(preset))),
                    selected: feet == preset,
                    showCheckmark: false,
                    onSelected: (_) => _selectPreset(preset),
                  ),
              ],
            ),
            if (wind != null) ...[
              const SizedBox(height: 12),
              Text(
                l10n.altitudeWindPreview(
                  '${(wind.directionFrom.round() % 360).toString().padLeft(3, '0')}° · '
                  '${context.formatNumber(speedUnit.convertFromMs(wind.speedMs), 0)} '
                  '${speedUnit.getAbbreviation(l10n)}',
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    if (!_useDefault && !_form.currentState!.validate()) {
                      return;
                    }
                    Navigator.pop(context, (
                      altitude: _useDefault
                          ? null
                          : int.parse(_controller.text.trim()),
                    ));
                  },
                  child: Text(l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
