import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';
import '../../../weather/presentation/providers/flight_weather_provider.dart';
import '../../../weather/presentation/providers/navigation_eta_provider.dart';
import '../utils/navigation_formatters.dart';

const _forecastHorizonDays = 4;

/// Single-step departure picker. Presets and the inline day strip avoid the
/// two consecutive system pickers previously used for date and time.
Future<void> showFlightDepartureDialog(BuildContext context) =>
    showDialog<void>(
      context: context,
      builder: (_) => const _FlightDepartureDialog(),
    );

class _FlightDepartureDialog extends ConsumerStatefulWidget {
  const _FlightDepartureDialog();

  @override
  ConsumerState<_FlightDepartureDialog> createState() =>
      _FlightDepartureDialogState();
}

class _FlightDepartureDialogState
    extends ConsumerState<_FlightDepartureDialog> {
  late DateTime _date;
  late TimeOfDay _time;
  late final TextEditingController _timeController;
  bool _useNow = false;

  @override
  void initState() {
    super.initState();
    final now = clock.now();
    final selected = ref.read(flightDepartureProvider);
    final horizon = now.add(const Duration(days: _forecastHorizonDays));
    final initial =
        selected != null && selected.isAfter(now) && !selected.isAfter(horizon)
        ? selected
        : now;
    _date = DateUtils.dateOnly(initial.toLocal());
    _time = TimeOfDay.fromDateTime(initial.toLocal());
    _useNow = selected == null || !selected.isAfter(now);
    _timeController = TextEditingController(text: _formatTime(_time));
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  DateTime get _departure =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  static String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  static TimeOfDay? _parseTime(String value) {
    final match = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').firstMatch(value);
    if (match == null) return null;
    return TimeOfDay(
      hour: int.parse(match.group(1)!),
      minute: int.parse(match.group(2)!),
    );
  }

  void _syncController() {
    _timeController.text = _formatTime(_time);
  }

  void _selectDateTime(DateTime value, {bool useNow = false}) {
    final local = value.toLocal();
    setState(() {
      _date = DateUtils.dateOnly(local);
      _time = TimeOfDay.fromDateTime(local);
      _useNow = useNow;
      _syncController();
    });
  }

  void _shiftTime(int minutes) {
    _selectDateTime(_departure.add(Duration(minutes: minutes)));
  }

  void _selectDay(DateTime day) {
    final now = clock.now();
    var time = _time;
    final candidate = DateTime(
      day.year,
      day.month,
      day.day,
      time.hour,
      time.minute,
    );
    if (candidate.isBefore(now)) {
      time = TimeOfDay.fromDateTime(now.add(const Duration(minutes: 5)));
    }
    setState(() {
      _date = DateUtils.dateOnly(day);
      _time = time;
      _useNow = false;
      _syncController();
    });
  }

  void _onTimeChanged(String value) {
    final parsed = _parseTime(value);
    setState(() {
      if (parsed != null) _time = parsed;
      _useNow = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = l10n.localeName;
    final now = clock.now();
    final departure = _departure;
    final destinationEta = departure.add(
      ref.watch(navigationEtaProvider).totalDuration,
    );
    final invalidTime = _parseTime(_timeController.text) == null;
    final outOfRange =
        departure.isBefore(now.subtract(const Duration(minutes: 1))) ||
        departure.isAfter(now.add(const Duration(days: _forecastHorizonDays)));
    final canApply = !invalidTime && !outOfRange;
    final days = [
      for (int index = 0; index <= _forecastHorizonDays; index++)
        DateUtils.dateOnly(now).add(Duration(days: index)),
    ];

    Widget preset(
      String label,
      VoidCallback onPressed, {
      bool selected = false,
    }) => ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onPressed(),
    );

    return BaseDetailsDialog(
      titleText: l10n.departureTimeTitle,
      icon: Icons.schedule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              DateFormat.yMMMMEEEEd(locale).format(_date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              _formatTime(_time),
              style: theme.textTheme.displaySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
          ),
          Center(
            child: Text(
              '${DateFormat.Hm(locale).format(departure.toUtc())} ${l10n.clockUtc}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              preset(
                l10n.departureNowPreset,
                () => _selectDateTime(clock.now(), useNow: true),
                selected: _useNow,
              ),
              preset(
                l10n.departureIn30Min,
                () => _selectDateTime(
                  clock.now().add(const Duration(minutes: 30)),
                ),
              ),
              preset(
                l10n.departureIn1Hour,
                () =>
                    _selectDateTime(clock.now().add(const Duration(hours: 1))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.departureLocalUtcHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final day = days[index];
                final selected = DateUtils.isSameDay(day, _date);
                final isToday = DateUtils.isSameDay(day, now);
                return ChoiceChip(
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => _selectDay(day),
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isToday
                            ? l10n.departureToday
                            : DateFormat.E(locale).format(day),
                        style: theme.textTheme.labelSmall,
                      ),
                      Text(
                        DateFormat.MMMd(locale).format(day),
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: () => _shiftTime(-5),
                icon: const Icon(Icons.remove),
                tooltip: l10n.departureShiftEarlier,
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                child: TextField(
                  controller: _timeController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                    LengthLimitingTextInputFormatter(5),
                  ],
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    errorText: invalidTime ? l10n.departureInvalidTime : null,
                    errorMaxLines: 2,
                    isDense: true,
                  ),
                  onChanged: _onTimeChanged,
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: () => _shiftTime(5),
                icon: const Icon(Icons.add),
                tooltip: l10n.departureShiftLater,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.flag_outlined, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.departureForecastEta(
                      formatNavigationTimeUtc(context, destinationEta),
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          if (outOfRange) ...[
            const SizedBox(height: 8),
            Text(
              l10n.departureOutOfRange,
              style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: canApply
                    ? () {
                        ref
                            .read(flightDepartureProvider.notifier)
                            .select(_useNow ? null : _departure.toUtc());
                        Navigator.pop(context);
                      }
                    : null,
                child: Text(l10n.departureSet),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
