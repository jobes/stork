import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre/maplibre.dart';
import 'package:stork/features/map/domain/models/notam.dart';
import 'package:stork/features/map/domain/repositories/notam_repository.dart';
import 'package:stork/features/map/domain/services/notam_service.dart';
import 'package:stork/features/map/domain/utils/fir_utils.dart';

class FakeNotamRepository implements NotamRepository {
  final List<String> queriedFirs = [];
  final List<Geographic> queriedPoints = [];
  final List<Notam> mockNotamsToReturn;

  FakeNotamRepository({this.mockNotamsToReturn = const []});

  @override
  Future<List<Notam>> fetchNotamsByFirs(List<String> firs) async {
    queriedFirs.addAll(firs);
    return mockNotamsToReturn.where((n) => firs.contains(n.fir)).toList();
  }

  @override
  Future<List<Notam>> fetchNotamsAroundPoint(
    Geographic point,
    int radiusMeters,
  ) async {
    queriedPoints.add(point);
    return mockNotamsToReturn.where((n) => n.fir == 'LZBB').toList();
  }
}

void main() {
  setUpAll(() async {
    final file = File('assets/geojson/fir.geojson');
    final geojson = file.readAsStringSync();
    await FirUtils.initialize(rawJson: geojson);
  });

  group('NotamService Tests', () {
    final testNotam = Notam(
      facilityDesignator: 'LZIB',
      notamNumber: 'A1234/26',
      featureName: 'BRATISLAVA',
      issueDate: '2026-03-25T13:00:00Z',
      startDate: '2026-03-25T13:15:00Z',
      endDate: '2026-06-25T18:00:00Z',
      icaoMessage: '',
      id: 'A1234/26',
      type: 'NOTAMN',
      issuer: 'LZIB',
      from: DateTime.utc(2026, 3, 25),
      to: DateTime.utc(2026, 6, 25),
      msg: 'TEST NOTAM MESSAGE',
      fir: 'LZBB',
      latitude: 48.17,
      longitude: 17.17,
      radius: 5000,
      flightLevelLowerLimit: 0,
      flightLevelUpperLimit: 999,
    );

    test(
      'fetchInitialNotams queries repository for matching FIR of coordinate',
      () async {
        final repository = FakeNotamRepository(mockNotamsToReturn: [testNotam]);
        final service = NotamService(repository);

        // Bratislava coordinate lies within LZBB FIR
        final result = await service.fetchInitialNotams(48.17, 17.17);

        expect(repository.queriedFirs, contains('LZBB'));
        expect(result.length, equals(1));
        expect(result.first.id, equals('A1234/26'));
      },
    );

    test('fetchNotamsForFirs queries repository directly', () async {
      final repository = FakeNotamRepository(mockNotamsToReturn: [testNotam]);
      final service = NotamService(repository);

      final result = await service.fetchNotamsForFirs(['LZBB']);

      expect(repository.queriedFirs, contains('LZBB'));
      expect(result.length, equals(1));
    });

    test(
      'fetchRouteNotams fetches both FIR and segment points and deduplicates results',
      () async {
        final repository = FakeNotamRepository(mockNotamsToReturn: [testNotam]);
        final service = NotamService(repository);

        final routePoints = [
          Geographic(lat: 48.17, lon: 17.17), // Bratislava (LZBB FIR)
          Geographic(lat: 48.17, lon: 17.5),
        ];

        final result = await service.fetchRouteNotams(routePoints);

        // Check that it queried FIRs and points along the route
        expect(repository.queriedFirs, contains('LZBB'));
        expect(repository.queriedPoints, isNotEmpty);

        // Check that the duplicate NOTAMs returned from parallel calls are correctly deduplicated
        expect(result.length, equals(1));
        expect(result.first.id, equals('A1234/26'));
      },
    );

    test('fetchRouteNotams with extraFir queries extra FIR as well', () async {
      final repository = FakeNotamRepository(
        mockNotamsToReturn: [
          testNotam,
          Notam.fromJson(
            testNotam.toJson()
              ..['id'] = 'B5678/26'
              ..['fir'] = 'LHCC',
          ),
        ],
      );
      final service = NotamService(repository);

      final routePoints = [
        Geographic(lat: 48.17, lon: 17.17), // Bratislava (LZBB FIR)
      ];

      final result = await service.fetchRouteNotams(
        routePoints,
        extraFir: 'LHCC',
      );

      expect(repository.queriedFirs, containsAll(['LHCC', 'LZBB']));
      expect(result.length, equals(2));
    });
  });
}
