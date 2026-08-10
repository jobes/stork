import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:stork/features/map/data/repositories/aup_repository.dart';
import 'package:stork/features/map/data/repositories/map_metadata_repository.dart';
import 'package:stork/features/map/data/services/cze_aup_service.dart';
import 'package:stork/features/map/data/services/svk_aup_service.dart';
import 'package:stork/features/map/domain/airspace_metadata.dart';
import 'package:stork/features/map/domain/models/airspace_activity_status.dart';
import 'package:stork/features/map/domain/models/openaip_unit.dart';

class FakeMapMetadataRepository extends MapMetadataRepository {
  FakeMapMetadataRepository() : super(client: http.Client());

  List<Map<String, dynamic>> features = [];
  Map<String, AirspaceMetadata> networkFeatures = {};
  int dbFetchCount = 0;
  int networkFetchCount = 0;
  bool failDbFetchOnce = false;
  bool failNetworkFetchOnce = false;

  @override
  Future<List<Map<String, dynamic>>> fetchAllFeaturesFromDb(String type) async {
    dbFetchCount++;
    if (failDbFetchOnce && dbFetchCount == 1) {
      throw StateError('db fetch failed');
    }
    return features;
  }

  @override
  Future<Map<String, AirspaceMetadata>> fetchAirspacesFromNetwork(
    String countryCode,
  ) async {
    networkFetchCount++;
    if (failNetworkFetchOnce && networkFetchCount == 1) {
      throw StateError('network fetch failed');
    }
    return networkFeatures;
  }
}

AupAirspaceActivity _activity(String designator) {
  return AupAirspaceActivity(
    airspaceId: designator,
    designator: designator,
    name: designator,
    status: AirspaceActivityStatus.active,
    source: SvkAupService.sourceCodeValue,
    updatedAt: DateTime.utc(2026, 8, 2, 4),
  );
}

AirspaceMetadata _metadata({required String id, required String name}) {
  return AirspaceMetadata(
    id: id,
    name: name,
    icaoClass: AirspaceClass.unclassified,
    type: AirspaceType.unknown,
    country: 'SK',
    limitLower: AirspaceLimit(
      value: 0,
      unit: OpenAipUnit.meters,
      referenceDatum: ReferenceDatum.gnd,
    ),
    limitUpper: AirspaceLimit(
      value: 95,
      unit: OpenAipUnit.flightLevel,
      referenceDatum: ReferenceDatum.std,
    ),
  );
}

void main() {
  group('AupRepository service routing', () {
    test('routes LZ* FIRs to Slovak LzPS and LK* to Czech ŘLP', () {
      final repository = AupRepository([
        SvkAupService(),
        CzeAupService(),
      ], FakeMapMetadataRepository());

      expect(
        repository.serviceForFir('LZBB')!.sourceCode,
        SvkAupService.sourceCodeValue,
      );
      expect(
        repository.serviceForFir('LKAA')!.sourceCode,
        CzeAupService.sourceCodeValue,
      );
      // Each service declares the openAIP country code of its FIRs, used for
      // the network metadata fallback.
      expect(repository.serviceForFir('LZBB')!.countryCode, 'SK');
      expect(repository.serviceForFir('LKAA')!.countryCode, 'CZ');
      // Unknown FIR has no configured AUP service.
      expect(repository.serviceForFir('EGTT'), isNull);
    });
  });

  group('AupRepository binding to openAIP ids', () {
    test('binds by exact id match', () async {
      final metadataRepository = FakeMapMetadataRepository();
      metadataRepository.features = [
        {'_id': 'LZR33', 'name': 'R 33'},
      ];
      final repository = AupRepository([SvkAupService()], metadataRepository);

      final result = await repository.bindToOpenAipIds([
        _activity('LZR33'),
        _activity('LZP8'),
      ], 'LZBB');

      expect(result[0].airspaceId, 'LZR33');
      // No matching openAIP feature -> keeps the designator.
      expect(result[1].airspaceId, 'LZP8');
    });

    test(
      'binds by normalized name match (designator R33 -> name R 33)',
      () async {
        final metadataRepository = FakeMapMetadataRepository();
        metadataRepository.features = [
          {'_id': 'asp_123', 'name': 'R 33'},
        ];
        final repository = AupRepository([SvkAupService()], metadataRepository);

        final result = await repository.bindToOpenAipIds([
          _activity('R33'),
        ], 'LZBB');

        expect(result.first.airspaceId, 'asp_123');
      },
    );

    test(
      'binds by name token (designator LZP23 -> name "LZP23 SALA")',
      () async {
        final metadataRepository = FakeMapMetadataRepository();
        metadataRepository.features = [
          {'_id': '626150775e9ded571044eecb', 'name': 'LZP23 SALA'},
        ];
        final repository = AupRepository([SvkAupService()], metadataRepository);

        final result = await repository.bindToOpenAipIds([
          _activity('LZP23'),
        ], 'LZBB');

        expect(result.first.airspaceId, '626150775e9ded571044eecb');
      },
    );

    test(
      'binds Czech openAIP designators (LKTSA2 -> "LKTSA2 BREZINA")',
      () async {
        final metadataRepository = FakeMapMetadataRepository();
        metadataRepository.features = [
          {'_id': 'asp_tsa2', 'name': 'LKTSA2 BREZINA'},
          {'_id': 'asp_tra12', 'name': 'LKTRA12 POHORELICE'},
        ];
        final repository = AupRepository([CzeAupService()], metadataRepository);

        // CzeAupService maps AUP designators (`TSA2`) to the openAIP form
        // (`LKTSA2`); the shared binding then matches them by name token.
        final result = await repository.bindToOpenAipIds([
          _activity('LKTSA2'),
          _activity('LKTRA12'),
        ], 'LKAA');

        expect(result[0].airspaceId, 'asp_tsa2');
        expect(result[1].airspaceId, 'asp_tra12');
      },
    );

    test(
      'name token match does not match a partial designator prefix',
      () async {
        final metadataRepository = FakeMapMetadataRepository();
        metadataRepository.features = [
          {'_id': 'asp_23', 'name': 'LZP23 SALA'},
          {'_id': 'asp_2', 'name': 'LZP2 MOCHOVCE'},
        ];
        final repository = AupRepository([SvkAupService()], metadataRepository);

        // 'LZP2' is a prefix of 'LZP23' but is a full token of 'LZP2 MOCHOVCE'.
        final result = await repository.bindToOpenAipIds([
          _activity('LZP2'),
          _activity('LZP23'),
        ], 'LZBB');

        expect(result[0].airspaceId, 'asp_2');
        expect(result[1].airspaceId, 'asp_23');
      },
    );

    test(
      'falls back to the network metadata when the airspace is not in the DB',
      () async {
        final metadataRepository = FakeMapMetadataRepository();
        // No offline features -> DB binding finds nothing.
        metadataRepository.features = [];
        metadataRepository.networkFeatures = {
          'asp_777': _metadata(id: 'asp_777', name: 'R 44'),
        };
        final repository = AupRepository([SvkAupService()], metadataRepository);

        // designator 'R44' matches network metadata name 'R 44' -> asp_777.
        final result = await repository.bindToOpenAipIds([
          _activity('R44'),
        ], 'LZBB');

        expect(result.first.airspaceId, 'asp_777');
        // The network index is cached per country.
        expect(metadataRepository.networkFetchCount, 1);
      },
    );

    test(
      'retries the database read after a failure instead of caching it',
      () async {
        final metadataRepository = FakeMapMetadataRepository()
          ..failDbFetchOnce = true
          ..features = [
            {'_id': 'asp_123', 'name': 'R 33'},
          ];
        final repository = AupRepository([SvkAupService()], metadataRepository);

        await expectLater(
          repository.bindToOpenAipIds([_activity('R33')], 'LZBB'),
          throwsStateError,
        );

        final result = await repository.bindToOpenAipIds([
          _activity('R33'),
        ], 'LZBB');

        expect(result.first.airspaceId, 'asp_123');
        expect(metadataRepository.dbFetchCount, 2);
      },
    );

    test(
      'network fallback matches by name token (LZP23 -> "LZP23 SALA")',
      () async {
        final metadataRepository = FakeMapMetadataRepository();
        metadataRepository.features = [];
        metadataRepository.networkFeatures = {
          'asp_999': _metadata(id: 'asp_999', name: 'LZP23 SALA'),
        };
        final repository = AupRepository([SvkAupService()], metadataRepository);

        final result = await repository.bindToOpenAipIds([
          _activity('LZP23'),
        ], 'LZBB');

        expect(result.first.airspaceId, 'asp_999');
        expect(metadataRepository.networkFetchCount, 1);
      },
    );

    test(
      'retries the network fallback after a failure instead of caching empty',
      () async {
        final metadataRepository = FakeMapMetadataRepository()
          ..failNetworkFetchOnce = true
          ..features = []
          ..networkFeatures = {
            'asp_777': _metadata(id: 'asp_777', name: 'R 44'),
          };
        final repository = AupRepository([SvkAupService()], metadataRepository);

        final firstResult = await repository.bindToOpenAipIds([
          _activity('R44'),
        ], 'LZBB');

        final secondResult = await repository.bindToOpenAipIds([
          _activity('R44'),
        ], 'LZBB');

        expect(firstResult.first.airspaceId, 'R44');
        expect(secondResult.first.airspaceId, 'asp_777');
        expect(metadataRepository.networkFetchCount, 2);
      },
    );

    test(
      'does not query the network when the designator has no country mapping',
      () async {
        final metadataRepository = FakeMapMetadataRepository();
        metadataRepository.features = [];
        final repository = AupRepository([SvkAupService()], metadataRepository);

        // 'ZZZZ' has no configured country -> keeps designator, no network.
        final result = await repository.bindToOpenAipIds([
          _activity('ZZTOP'),
        ], 'ZZZZ');

        expect(result.first.airspaceId, 'ZZTOP');
        expect(metadataRepository.networkFetchCount, 0);
      },
    );

    test('returns empty binding when there are no activities', () async {
      final repository = AupRepository([
        SvkAupService(),
      ], FakeMapMetadataRepository());
      final result = await repository.bindToOpenAipIds(const [], 'LZBB');
      expect(result, isEmpty);
    });
  });
}
