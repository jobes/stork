import 'dart:math' as math;

/// Single point in track history used to calculate turn rate over time.
class TrackHistoryPoint {
  final DateTime timestamp;
  final double trackRad;

  const TrackHistoryPoint({
    required this.timestamp,
    required this.trackRad,
  });
}

/// Result of a 3D threat volume evaluation for a single target.
class CasThreatEvaluation {
  final bool isCollisionThreat;
  final double? tCpa; // Time to Closest Point of Approach in seconds
  final double? minDistance; // Minimum distance at CPA in meters
  final double turnRate; // Computed turn rate in rad/s
  final bool isCircling; // Sustained turn rate >= 12 deg/s over 5+ seconds

  const CasThreatEvaluation({
    required this.isCollisionThreat,
    this.tCpa,
    this.minDistance,
    required this.turnRate,
    required this.isCircling,
  });
}

class CasEvaluator {
  static const double minOmegaThreshold = 0.01; // rad/s (~0.5 deg/s)
  static const double circlingOmegaThreshold = 0.20944; // rad/s (12 deg/s)
  static const double metersPerDegreeLat = 111139.0;

  /// Normalizes an angle difference to [-pi, pi]
  static double normalizeAngle(double angleRad) {
    var a = angleRad % (2 * math.pi);
    if (a > math.pi) a -= 2 * math.pi;
    if (a < -math.pi) a += 2 * math.pi;
    return a;
  }

  /// Calculates turn rate omega (rad/s) from recent track history points.
  static double calculateTurnRate(List<TrackHistoryPoint> history) {
    if (history.length < 2) return 0.0;
    
    // Pick latest point and oldest point within 10 seconds window
    final latest = history.last;
    TrackHistoryPoint? prev;
    for (int i = history.length - 2; i >= 0; i--) {
      final point = history[i];
      final dt = latest.timestamp.difference(point.timestamp).inMilliseconds / 1000.0;
      if (dt >= 1.0 && dt <= 10.0) {
        prev = point;
        break;
      }
    }
    prev ??= history.first;

    final dt = latest.timestamp.difference(prev.timestamp).inMilliseconds / 1000.0;
    if (dt < 0.5 || dt > 10.0) return 0.0;

    final diff = normalizeAngle(latest.trackRad - prev.trackRad);
    return diff / dt;
  }

  /// Detects whether turn rate is sustained (>= 12 deg/s over 5+ seconds in consistent direction).
  static bool detectCircling(List<TrackHistoryPoint> history) {
    if (history.length < 2) return false;

    final latest = history.last;
    final cutoff = latest.timestamp.subtract(const Duration(seconds: 5));
    final relevant = history.where((p) => !p.timestamp.isBefore(cutoff)).toList();

    if (relevant.length < 2) return false;
    final totalSpan = latest.timestamp.difference(relevant.first.timestamp).inMilliseconds / 1000.0;
    if (totalSpan < 4.0) return false;

    double sumRates = 0.0;
    int rateCount = 0;
    bool? isPositive;
    for (int i = 1; i < relevant.length; i++) {
      final dt = relevant[i].timestamp.difference(relevant[i - 1].timestamp).inMilliseconds / 1000.0;
      if (dt <= 0) continue;

      final diff = normalizeAngle(relevant[i].trackRad - relevant[i - 1].trackRad);
      final rate = diff / dt;

      final sign = rate > 0;
      if (isPositive == null) {
        isPositive = sign;
      } else if (isPositive != sign) {
        return false; // Turn direction reversed
      }

      sumRates += rate.abs();
      rateCount++;
    }

    if (rateCount == 0 || isPositive == null) return false;
    final avgRate = sumRates / rateCount;
    return avgRate >= circlingOmegaThreshold;
  }

  /// Computes flat-earth delta (dx, dy) in meters from point A to point B.
  static (double dx, double dy, double dist) calculateFlatEarthOffset({
    required double latA,
    required double lonA,
    required double latB,
    required double lonB,
  }) {
    final latRadA = latA * math.pi / 180.0;
    final dx = (lonB - lonA) * metersPerDegreeLat * math.cos(latRadA);
    final dy = (latB - latA) * metersPerDegreeLat;
    final dist = math.sqrt(dx * dx + dy * dy);
    return (dx, dy, dist);
  }

  /// 3D position prediction equation P(t) = (x(t), y(t), h(t))
  static (double x, double y, double h) predictPosition({
    required double x0,
    required double y0,
    required double h0,
    required double gs,
    required double trackRad,
    required double omega,
    required double vs,
    required double t,
  }) {
    double x, y;
    if (omega.abs() < minOmegaThreshold) {
      x = x0 + gs * math.sin(trackRad) * t;
      y = y0 + gs * math.cos(trackRad) * t;
    } else {
      x = x0 + (gs / omega) * (math.cos(trackRad) - math.cos(trackRad + omega * t));
      y = y0 + (gs / omega) * (math.sin(trackRad + omega * t) - math.sin(trackRad));
    }
    final h = h0 + vs * t;
    return (x, y, h);
  }

  /// Evaluates broad-phase and 3D threat volume for target aircraft B relative to ownship A.
  static CasThreatEvaluation evaluateThreat({
    required double latA,
    required double lonA,
    required double altA,
    required double gsA,
    required double trackA,
    required double omegaA,
    required double vsA,
    required bool isCirclingA,
    required double latB,
    required double lonB,
    required double altB,
    required double gsB,
    required double trackB,
    required double omegaB,
    required double vsB,
    required bool isCirclingB,
    required double maxBroadPhaseHorizDist,
    required double maxBroadPhaseVertDist,
    required double lookaheadTimeSec,
    required double horizThresholdMeters,
    required double vertThresholdMeters,
  }) {
    final (dx0, dy0, dCurr) = calculateFlatEarthOffset(
      latA: latA,
      lonA: lonA,
      latB: latB,
      lonB: lonB,
    );

    final trackRadA = trackA * math.pi / 180.0;
    final trackRadB = trackB * math.pi / 180.0;
    final altDiffCurr = (altB - altA).abs();

    // 1. Broad-Phase Filter
    if (dCurr > maxBroadPhaseHorizDist || altDiffCurr > maxBroadPhaseVertDist) {
      return CasThreatEvaluation(
        isCollisionThreat: false,
        turnRate: omegaB,
        isCircling: isCirclingB,
      );
    }

    // 2. Thermal Co-circling Logic
    double effectiveHorizThreshold = horizThresholdMeters;
    if (isCirclingA && isCirclingB && dCurr <= 1000.0) {
      effectiveHorizThreshold = math.min(horizThresholdMeters, 50.0);
    }

    // 3. Narrow-Phase Trajectory Prediction & Threat Volume Evaluation
    bool threatDetected = dCurr <= effectiveHorizThreshold && altDiffCurr <= vertThresholdMeters;
    double minDistance = dCurr;
    double? tCpa;

    final steps = lookaheadTimeSec.ceil().clamp(1, 120);
    final dt = lookaheadTimeSec / steps;

    for (int i = 1; i <= steps; i++) {
      final t = i * dt;

      final (xA, yA, hA) = predictPosition(
        x0: 0.0,
        y0: 0.0,
        h0: altA,
        gs: gsA,
        trackRad: trackRadA,
        omega: omegaA,
        vs: vsA,
        t: t,
      );

      final (xB, yB, hB) = predictPosition(
        x0: dx0,
        y0: dy0,
        h0: altB,
        gs: gsB,
        trackRad: trackRadB,
        omega: omegaB,
        vs: vsB,
        t: t,
      );

      final relDx = xB - xA;
      final relDy = yB - yA;
      final distAtT = math.sqrt(relDx * relDx + relDy * relDy);
      final altDiffAtT = (hB - hA).abs();

      if (distAtT < minDistance) {
        minDistance = distAtT;
        tCpa = t;
      }

      if (distAtT <= effectiveHorizThreshold && altDiffAtT <= vertThresholdMeters) {
        threatDetected = true;
      }
    }

    return CasThreatEvaluation(
      isCollisionThreat: threatDetected,
      tCpa: tCpa,
      minDistance: minDistance,
      turnRate: omegaB,
      isCircling: isCirclingB,
    );
  }
}
