import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/telemetry/domain/utils/cas_evaluator.dart';

void main() {
  group('CasEvaluator Tests', () {
    test('normalizeAngle normalizes angles to [-pi, pi]', () {
      expect(CasEvaluator.normalizeAngle(0.0), closeTo(0.0, 1e-6));
      expect(CasEvaluator.normalizeAngle(math.pi * 3).abs(), closeTo(math.pi, 1e-6));
      expect(CasEvaluator.normalizeAngle(-math.pi * 3).abs(), closeTo(math.pi, 1e-6));
      expect(CasEvaluator.normalizeAngle(2 * math.pi), closeTo(0.0, 1e-6));
    });

    test('calculateTurnRate calculates omega correctly including 0/360 wrap-around', () {
      final now = DateTime.now();
      // Turning right from 350 deg (6.108 rad) to 10 deg (0.1745 rad) over 2 seconds -> +20 deg / 2s = 10 deg/s
      final p1 = TrackHistoryPoint(
        timestamp: now.subtract(const Duration(seconds: 2)),
        trackRad: 350.0 * math.pi / 180.0,
      );
      final p2 = TrackHistoryPoint(
        timestamp: now,
        trackRad: 10.0 * math.pi / 180.0,
      );

      final omega = CasEvaluator.calculateTurnRate([p1, p2]);
      final omegaDegPerSec = omega * 180.0 / math.pi;
      expect(omegaDegPerSec, closeTo(10.0, 0.1));
    });

    test('detectCircling detects sustained turn rate >= 12 deg/s over 5+ seconds', () {
      final now = DateTime.now();
      final points = <TrackHistoryPoint>[];
      // Generate 6 seconds of 15 deg/s turning right
      for (int i = 6; i >= 0; i--) {
        final t = now.subtract(Duration(seconds: i));
        final trackDeg = (i * 15.0) % 360.0;
        points.add(TrackHistoryPoint(
          timestamp: t,
          trackRad: trackDeg * math.pi / 180.0,
        ));
      }

      final isCircling = CasEvaluator.detectCircling(points);
      expect(isCircling, isTrue);
    });

    test('detectCircling returns false for straight-line motion', () {
      final now = DateTime.now();
      final points = <TrackHistoryPoint>[];
      for (int i = 6; i >= 0; i--) {
        points.add(TrackHistoryPoint(
          timestamp: now.subtract(Duration(seconds: i)),
          trackRad: 90.0 * math.pi / 180.0, // Straight East
        ));
      }

      final isCircling = CasEvaluator.detectCircling(points);
      expect(isCircling, isFalse);
    });

    test('evaluateThreat flags broad-phase filter for distant targets', () {
      final eval = CasEvaluator.evaluateThreat(
        latA: 48.0,
        lonA: 17.0,
        altA: 1000.0,
        gsA: 30.0,
        trackA: 0.0,
        omegaA: 0.0,
        vsA: 0.0,
        isCirclingA: false,
        latB: 48.2, // ~22 km away (> 10 km max broad phase)
        lonB: 17.0,
        altB: 1000.0,
        gsB: 30.0,
        trackB: 180.0,
        omegaB: 0.0,
        vsB: 0.0,
        isCirclingB: false,
        maxBroadPhaseHorizDist: 10000.0,
        maxBroadPhaseVertDist: 1500.0,
        lookaheadTimeSec: 30.0,
        horizThresholdMeters: 300.0,
        vertThresholdMeters: 100.0,
      );

      expect(eval.isCollisionThreat, isFalse);
    });

    test('evaluateThreat detects head-on collision threat (straight paths)', () {
      // Ownship flying North at 30 m/s from (48.0, 17.0)
      // Target flying South at 30 m/s from (48.009, 17.0) (~1 km away)
      final eval = CasEvaluator.evaluateThreat(
        latA: 48.0,
        lonA: 17.0,
        altA: 1000.0,
        gsA: 30.0,
        trackA: 0.0,
        omegaA: 0.0,
        vsA: 0.0,
        isCirclingA: false,
        latB: 48.009,
        lonB: 17.0,
        altB: 1000.0,
        gsB: 30.0,
        trackB: 180.0,
        omegaB: 0.0,
        vsB: 0.0,
        isCirclingB: false,
        maxBroadPhaseHorizDist: 10000.0,
        maxBroadPhaseVertDist: 1500.0,
        lookaheadTimeSec: 30.0,
        horizThresholdMeters: 300.0,
        vertThresholdMeters: 100.0,
      );

      expect(eval.isCollisionThreat, isTrue);
      expect(eval.tCpa, greaterThan(0.0));
      expect(eval.tCpa, lessThanOrEqualTo(30.0));
    });

    test('evaluateThreat handles curved trajectory (arc projection)', () {
      // Ownship turning right (omega = 0.1 rad/s)
      // Target turning left (omega = -0.1 rad/s)
      final eval = CasEvaluator.evaluateThreat(
        latA: 48.0,
        lonA: 17.0,
        altA: 1000.0,
        gsA: 25.0,
        trackA: 90.0,
        omegaA: 0.1,
        vsA: 0.0,
        isCirclingA: false,
        latB: 48.002,
        lonB: 17.005,
        altB: 1000.0,
        gsB: 25.0,
        trackB: 270.0,
        omegaB: -0.1,
        vsB: 0.0,
        isCirclingB: false,
        maxBroadPhaseHorizDist: 10000.0,
        maxBroadPhaseVertDist: 1500.0,
        lookaheadTimeSec: 30.0,
        horizThresholdMeters: 300.0,
        vertThresholdMeters: 100.0,
      );

      expect(eval.turnRate, equals(-0.1));

      // Direct validation of predictPosition arc projection components
      // Track 90 deg (pi/2 rad = East) turning right (omega = 0.1 rad/s > 0, heading turns South)
      final (xEast, ySouth, _) = CasEvaluator.predictPosition(
        x0: 0.0,
        y0: 0.0,
        h0: 1000.0,
        gs: 30.0,
        trackRad: math.pi / 2,
        omega: 0.1,
        vs: 0.0,
        t: 5.0,
      );
      expect(xEast, greaterThan(0.0)); // Eastward movement
      expect(ySouth, lessThan(0.0)); // Southward movement due to right turn from East

      // Convergence of small omega to straight-line prediction
      final (xStraight, yStraight, _) = CasEvaluator.predictPosition(
        x0: 0.0,
        y0: 0.0,
        h0: 1000.0,
        gs: 30.0,
        trackRad: math.pi / 4,
        omega: 0.0,
        vs: 0.0,
        t: 10.0,
      );
      final (xSmallOmega, ySmallOmega, _) = CasEvaluator.predictPosition(
        x0: 0.0,
        y0: 0.0,
        h0: 1000.0,
        gs: 30.0,
        trackRad: math.pi / 4,
        omega: 0.0001,
        vs: 0.0,
        t: 10.0,
      );
      expect(xSmallOmega, closeTo(xStraight, 0.05));
      expect(ySmallOmega, closeTo(yStraight, 0.05));
    });

    test('evaluateThreat thermal co-circling adjusts horizontal threshold', () {
      // Both aircraft circling in thermal 200m apart at same altitude
      // If co-circling threshold adjustment is active (50m), 200m apart will NOT trigger false alarm
      final eval = CasEvaluator.evaluateThreat(
        latA: 48.0,
        lonA: 17.0,
        altA: 1000.0,
        gsA: 20.0,
        trackA: 0.0,
        omegaA: 0.25,
        vsA: 1.5,
        isCirclingA: true,
        latB: 48.0018, // ~200m away
        lonB: 17.0,
        altB: 1000.0,
        gsB: 20.0,
        trackB: 180.0,
        omegaB: 0.25,
        vsB: 1.5,
        isCirclingB: true,
        maxBroadPhaseHorizDist: 10000.0,
        maxBroadPhaseVertDist: 1500.0,
        lookaheadTimeSec: 30.0,
        horizThresholdMeters: 300.0,
        vertThresholdMeters: 100.0,
      );

      // With 50m adjusted threshold due to co-circling, 200m distance prevents false collision alarm
      expect(eval.isCollisionThreat, isFalse);
      expect(eval.isCircling, isTrue);
    });
  });
}
