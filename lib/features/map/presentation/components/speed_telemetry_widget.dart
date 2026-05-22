import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/cannelloni_service_io.dart'
    if (dart.library.html) '../../../../core/services/cannelloni_service_stub.dart';
import '../../../telemetry/presentation/providers/telemetry_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/domain/range_thresholds.dart';

class SpeedTelemetryWidget extends ConsumerWidget {
  const SpeedTelemetryWidget({super.key});

  Color _getBorderColor(ThresholdState state, bool isDark) {
    switch (state) {
      case ThresholdState.inactive:
      case ThresholdState.operational:
        return isDark
            ? Colors.white.withAlpha(
                76,
              ) // Increased visibility in dark mode (30% alpha)
            : Colors.black.withAlpha(
                51,
              ); // Increased visibility in light mode (20% alpha)
      case ThresholdState.minError:
      case ThresholdState.maxError:
        return isDark ? Colors.redAccent.shade200 : Colors.red.shade600;
      case ThresholdState.minWarning:
      case ThresholdState.maxWarning:
        return isDark ? Colors.orangeAccent : Colors.orange.shade700;
    }
  }

  double _getBorderWidth(ThresholdState state) {
    return 2.0; // Constant width prevents layout shifting between states
  }

  List<BoxShadow> _getBoxShadow(ThresholdState state, bool isDark) {
    switch (state) {
      case ThresholdState.inactive:
      case ThresholdState.operational:
        return [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ];
      case ThresholdState.minError:
      case ThresholdState.maxError:
        final color = isDark ? Colors.redAccent : Colors.red.shade700;
        return [
          BoxShadow(
            color: color.withAlpha(102), // Glow effect
            blurRadius: 16,
            spreadRadius: 3,
          ),
        ];
      case ThresholdState.minWarning:
      case ThresholdState.maxWarning:
        final color = isDark ? Colors.amber : Colors.orange.shade800;
        return [
          BoxShadow(
            color: color.withAlpha(102), // Glow effect
            blurRadius: 16,
            spreadRadius: 3,
          ),
        ];
    }
  }

  Widget _buildSpeedRow(String value, Color valueColor, Color unitColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: valueColor,
          ),
        ),
        const SizedBox(width: 4),
        Text('KM/H', style: TextStyle(fontSize: 12, color: unitColor)),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);
    final isConnected = ref.watch(cannelloniServiceProvider);
    final settings = ref.watch(appSettingsProvider).value;
    final thresholds =
        settings?.flightSpeedThresholds ?? const RangeThresholds();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTextColor = isDark
        ? Colors.grey.shade300
        : Colors.grey.shade700;

    final speedValueColor = isDark ? Colors.white : Colors.black;

    final double? ias = telemetry.indicatedAirSpeed;
    final double? gs = telemetry.speed;

    ThresholdState speedState = ThresholdState.inactive;
    if (!isConnected) {
      if (gs != null) {
        speedState = thresholds.evaluate(gs);
      }
    } else {
      if (ias != null) {
        speedState = thresholds.evaluate(ias);
      } else if (gs != null) {
        speedState = thresholds.evaluate(gs);
      }
    }

    List<Widget> columnChildren = [];

    if (!isConnected) {
      // Offline mode: Show only GS or ---
      final speedText = gs != null ? gs.toStringAsFixed(0).padLeft(3) : '---';
      columnChildren.add(
        _buildSpeedRow(speedText, speedValueColor, defaultTextColor),
      );
    } else {
      // Connected mode
      if (ias != null && gs != null) {
        columnChildren.add(
          _buildSpeedRow(
            ias.toStringAsFixed(0).padLeft(3),
            speedValueColor,
            defaultTextColor,
          ),
        );
        columnChildren.add(
          Text(
            'GS ${gs.toStringAsFixed(0).padLeft(3)} KM/H',
            style: TextStyle(
              fontSize: 12,
              color: defaultTextColor,
              fontFamily: 'monospace',
            ),
          ),
        );
      } else if (ias == null && gs != null) {
        columnChildren.add(
          _buildSpeedRow(
            gs.toStringAsFixed(0).padLeft(3),
            speedValueColor,
            defaultTextColor,
          ),
        );
        columnChildren.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(51),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'GPS ONLY',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else if (ias != null && gs == null) {
        columnChildren.add(
          _buildSpeedRow(
            ias.toStringAsFixed(0).padLeft(3),
            speedValueColor,
            defaultTextColor,
          ),
        );
        columnChildren.add(
          Row(
            children: [
              const Icon(Icons.satellite_alt, size: 12, color: Colors.red),
              const SizedBox(width: 4),
              const Text(
                'NO GPS',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      } else {
        // Neither available
        columnChildren.add(
          _buildSpeedRow('---', speedValueColor, defaultTextColor),
        );
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _getBoxShadow(speedState, isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withAlpha(76)
                  : Colors.white.withAlpha(128),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getBorderColor(speedState, isDark),
                width: _getBorderWidth(speedState),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: columnChildren,
            ),
          ),
        ),
      ),
    );
  }
}
