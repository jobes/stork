import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Cache of [NumberFormat] instances keyed by `"$locale-$decimals"`.
final _NumberFormatCache _cache = _NumberFormatCache();

class _NumberFormatCache {
  final Map<String, NumberFormat> _map = {};

  NumberFormat _get(String locale, int decimals) {
    final key = '$locale-$decimals';
    return _map.putIfAbsent(
      key,
      () => NumberFormat.decimalPattern(locale)
        ..minimumFractionDigits = decimals
        ..maximumFractionDigits = decimals,
    );
  }
}

/// Extension on [BuildContext] for formatting numbers with the current locale's
/// decimal separator (`.` in English, `,` in Slovak, etc.).
///
/// ```dart
/// Text(context.formatNumber(12.5, 1)) // → "12,5" in sk locale
/// ```
extension NumberFormatting on BuildContext {
  /// Formats [value] with exactly [decimals] fractional digits using the locale
  /// obtained from [Localizations.localeOf].
  String formatNumber(double value, int decimals) {
    final locale = Localizations.localeOf(this).toString();
    return _cache._get(locale, decimals).format(value);
  }
}

/// Formats a number with an explicit locale string.
///
/// Useful in providers/notifiers where a [BuildContext] is not available.
///
/// ```dart
/// formatNumberForLocale('sk', 12.5, 1) // → "12,5"
/// ```
String formatNumberForLocale(String locale, double value, int decimals) {
  return _cache._get(locale, decimals).format(value);
}
