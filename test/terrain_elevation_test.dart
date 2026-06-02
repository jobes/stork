import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stork/core/services/terrain_elevation_service.dart';
import 'package:stork/core/utils/aviation_math.dart';
import 'package:stork/features/telemetry/presentation/providers/agl_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/settings/domain/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Terrain Web Mercator and Terrarium math tests', () {
    test('Equator and Prime Meridian (0,0) translates to exact middle tile and pixel', () {
      const double lat = 0.0;
      const double lon = 0.0;
      const int zoomLevel = 12;
      final n = pow(2, zoomLevel).toInt(); // 4096

      // Longitude to x coordinate
      final double xDecimal = ((lon + 180) / 360) * n;
      final int tileX = xDecimal.floor();
      final int pixelX = ((xDecimal - tileX) * 256).floor();

      // Latitude to y coordinate (Web Mercator projection)
      final double latRad = lat * pi / 180;
      final double yDecimal =
          (1.0 - (log(tan(latRad) + 1.0 / cos(latRad)) / pi)) / 2.0 * n;
      final int tileY = yDecimal.floor();
      final int pixelY = ((yDecimal - tileY) * 256).floor();

      expect(tileX, equals(2048));
      expect(tileY, equals(2048));
      expect(pixelX, equals(0));
      expect(pixelY, equals(0));
    });

    test('Terrarium height formula matches Mapzen specification', () {
      // Test terrarium decode: elevation = (R * 256 + G + B / 256) - 32768
      // Case 1: Sea level (0m) -> R=128, G=0, B=0
      // elevation = (128 * 256 + 0 + 0) - 32768 = 32768 - 32768 = 0
      const int r1 = 128;
      const int g1 = 0;
      const int b1 = 0;
      final double elev1 = (r1 * 256.0 + g1 + b1 / 256.0) - 32768.0;
      expect(elev1, equals(0.0));

      // Case 2: Mt. Everest (approx 8848m) -> R=162, G=144, B=0
      // elevation = (162 * 256 + 144 + 0) - 32768 = 41472 + 144 - 32768 = 8848
      const int r2 = 162;
      const int g2 = 144;
      const int b2 = 0;
      final double elev2 = (r2 * 256.0 + g2 + b2 / 256.0) - 32768.0;
      expect(elev2, equals(8848.0));

      // Case 3: Negative elevation (-418m for Dead Sea) -> R=126, G=94, B=0
      // elevation = (126 * 256 + 94) - 32768 = 32256 + 94 - 32768 = -418
      const int r3 = 126;
      const int g3 = 94;
      const int b3 = 0;
      final double elev3 = (r3 * 256.0 + g3 + b3 / 256.0) - 32768.0;
      expect(elev3, equals(-418.0));
    });

    test('TerrainElevationService uses mock cache and decodes correctly', () async {
      final service = TerrainElevationService();
      service.clearCache();
      
      // A zoom 12 tile is 256x256. Raw RGBA buffer size = 256 * 256 * 4 = 262144 bytes.
      final Uint8List rawBytes = Uint8List(256 * 256 * 4);
      final ByteData mockByteData = ByteData.sublistView(rawBytes);

      // (0,0) is pixelX=0, pixelY=0 in tile (2048, 2048) at zoom 12.
      // Set R=162, G=144, B=0 (expected Mt. Everest elevation: 8848.0)
      mockByteData.setUint8(0, 162);
      mockByteData.setUint8(1, 144);
      mockByteData.setUint8(2, 0);
      mockByteData.setUint8(3, 255); // Alpha

      service.setMockCache(2048, 2048, mockByteData);

      final double? elevation = await service.getElevation(0.0, 0.0);
      expect(elevation, equals(8848.0));

      // Clear cache and verify it doesn't return mock value
      service.clearCache();
      final double? postClearElevation = await service.getElevation(0.0, 0.0);
      expect(postClearElevation, isNot(equals(8848.0)));
    });

    test('TerrainPixel equality and hashcode comparison works correctly', () {
      const p1 = TerrainPixel(tileX: 10, tileY: 20, pixelX: 5, pixelY: 6);
      const p2 = TerrainPixel(tileX: 10, tileY: 20, pixelX: 5, pixelY: 6);
      const p3 = TerrainPixel(tileX: 11, tileY: 20, pixelX: 5, pixelY: 6);

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
      expect(p1.toString(), contains('tileX: 10'));
    });

    test('TileCache LRU eviction works correctly with a limit of 4 entries', () {
      final cache = TileCache(4);
      final data1 = TerrainTile(byteData: ByteData(10), sideSize: 256);
      final data2 = TerrainTile(byteData: ByteData(10), sideSize: 256);
      final data3 = TerrainTile(byteData: ByteData(10), sideSize: 256);
      final data4 = TerrainTile(byteData: ByteData(10), sideSize: 256);
      final data5 = TerrainTile(byteData: ByteData(10), sideSize: 256);

      cache.put(1, 1, data1);
      cache.put(2, 2, data2);
      cache.put(3, 3, data3);
      cache.put(4, 4, data4);

      // Access (1, 1) to make it most recently used
      expect(cache.get(1, 1), equals(data1));

      // Put (5, 5) which should evict (2, 2) (since 1,1 was accessed and became recently used)
      cache.put(5, 5, data5);

      expect(cache.get(2, 2), isNull); // Evicted!
      expect(cache.get(1, 1), equals(data1)); // Still present!
      expect(cache.get(3, 3), equals(data3)); // Still present!
      expect(cache.get(4, 4), equals(data4)); // Still present!
      expect(cache.get(5, 5), equals(data5)); // Still present!
    });

    test('TileCache getEntry returns correct record and updates LRU position', () {
      final cache = TileCache(4);
      final data1 = TerrainTile(byteData: ByteData(10), sideSize: 256);
      final data2 = TerrainTile(byteData: ByteData(10), sideSize: 256);

      cache.put(1, 1, data1);
      cache.put(2, 2, data2);

      // Check non-existing entry
      final (isCached1, dataEntry1) = cache.getEntry(3, 3);
      expect(isCached1, isFalse);
      expect(dataEntry1, isNull);

      // Check existing entry
      final (isCached2, dataEntry2) = cache.getEntry(1, 1);
      expect(isCached2, isTrue);
      expect(dataEntry2, equals(data1));
    });

    test('TerrainFractionalPixel maps fractional values and works with high-res tile size scaling', () async {
      final service = TerrainElevationService();
      service.clearCache();

      // Setup a 512x512 high-res tile. Byte size = 512 * 512 * 4 = 1048576 bytes.
      final Uint8List rawBytes = Uint8List(512 * 512 * 4);
      // Initialize the whole buffer to Mt. Everest elevation so that interpolation always yields 8848.0
      for (int i = 0; i < rawBytes.length; i += 4) {
        rawBytes[i] = 162;
        rawBytes[i + 1] = 144;
        rawBytes[i + 2] = 0;
        rawBytes[i + 3] = 255;
      }
      final ByteData mockByteData = ByteData.sublistView(rawBytes);

      // E.g. a coordinate that falls exactly on pixel 1.5 in a 256x256 tile.
      // That corresponds to pixel 3 in a 512x512 tile!
      const double targetLon = 0.000515625;
      const double targetLat = 0.0;

      // Let's verify fractional coordinate mapping:
      final fractionalCoord = TerrainElevationService.getFractionalPixelCoordinate(targetLat, targetLon);
      expect(fractionalCoord.pixelX, closeTo(1.5, 0.005));
      expect(fractionalCoord.pixelY, closeTo(0.0, 0.0001));

      service.setMockCache(2048, 2048, mockByteData);

      final double? elevation = await service.getElevation(targetLat, targetLon);
      expect(elevation, equals(8848.0));
    });

    test('aglProvider computes elevation and AGL reactively', () async {
      final container = ProviderContainer(
        overrides: [
          terrainElevationServiceProvider.overrideWithValue(TerrainElevationService()),
          appSettingsProvider.overrideWith(() => MockAppSettingsNotifier()),
        ],
      );
      addTearDown(container.dispose);

      // Keep providers alive during the test by listening to them
      container.listen(telemetryProvider, (_, _) {});
      container.listen(aglProvider, (_, _) {});

      final service = container.read(terrainElevationServiceProvider);
      
      // Set Mt. Everest elevation in cache for (0,0) zoom 12 tile (2048, 2048) at pixel (0,0)
      final Uint8List rawBytes = Uint8List(256 * 256 * 4);
      final ByteData mockByteData = ByteData.sublistView(rawBytes);
      mockByteData.setUint8(0, 162);
      mockByteData.setUint8(1, 144);
      mockByteData.setUint8(2, 0);
      mockByteData.setUint8(3, 255);
      service.setMockCache(2048, 2048, mockByteData);

      // Initially, telemetry state is empty, so AglState should have nulls
      var agl = container.read(aglProvider);
      expect(agl.terrainElevation, isNull);
      expect(agl.heightAboveGround, isNull);

      // Now update telemetry with GPS coordinates and MSL altitude
      container.read(telemetryProvider.notifier).updateGPS(
        latitude: 0.0,
        longitude: 0.0,
        gpsAltitude: 10000.0, // MSL: 10000m
      );

      // Wait for the async fetching and decoding to complete
      await Future.delayed(const Duration(milliseconds: 100));

      agl = container.read(aglProvider);
      // Terrain elevation at (0,0) is Mt. Everest (8848.0)
      expect(agl.terrainElevation, equals(8848.0));
      // AGL = MSL - Elevation = 10000 - 8848 = 1152.0
      expect(agl.heightAboveGround, equals(1152.0));
    });

    test('aglProvider rounds coordinates to 5 decimal places to ignore micro-fluctuations', () async {
      final container = ProviderContainer(
        overrides: [
          terrainElevationServiceProvider.overrideWithValue(TerrainElevationService()),
          appSettingsProvider.overrideWith(() => MockAppSettingsNotifier()),
        ],
      );
      addTearDown(container.dispose);

      container.listen(telemetryProvider, (_, _) {});
      container.listen(aglProvider, (_, _) {});

      final service = container.read(terrainElevationServiceProvider);
      
      final Uint8List rawBytes = Uint8List(256 * 256 * 4);
      final ByteData mockByteData = ByteData.sublistView(rawBytes);
      mockByteData.setUint8(0, 162);
      mockByteData.setUint8(1, 144);
      mockByteData.setUint8(2, 0);
      mockByteData.setUint8(3, 255);
      service.setMockCache(2048, 2048, mockByteData);

      // Set initial GPS position
      container.read(telemetryProvider.notifier).updateGPS(
        latitude: 0.0,
        longitude: 0.0,
        gpsAltitude: 10000.0,
      );

      await Future.delayed(const Duration(milliseconds: 100));
      var agl = container.read(aglProvider);
      expect(agl.terrainElevation, equals(8848.0));

      // Clear the mock cache to verify if service is called again
      service.clearCache();

      // Change GPS coordinates by a very small amount (micro-fluctuation less than 5 decimal places: 0.000001)
      container.read(telemetryProvider.notifier).updateGPS(
        latitude: 0.000001, // 0.000001 rounds to 0.00000
        longitude: 0.0,
      );

      await Future.delayed(const Duration(milliseconds: 50));
      
      // Since it rounded to 0.0, telemetryCoordinatesProvider shouldn't change,
      // and terrainElevationProvider shouldn't call getElevation again.
      // So it will still return the previous value from the provider's cache.
      agl = container.read(aglProvider);
      expect(agl.terrainElevation, equals(8848.0));

      // Change coordinates by a larger amount (greater than 5 decimal places: 0.00002)
      container.read(telemetryProvider.notifier).updateGPS(
        latitude: 0.00002, // rounds to 0.00002
        longitude: 0.0,
      );

      await Future.delayed(const Duration(milliseconds: 50));
      agl = container.read(aglProvider);
      // Since it changed, it should call getElevation again.
      // Since the mock cache was cleared, it will try to fetch the real tile (which will fail/return null in test)
      // and thus terrainElevation should be null now.
      expect(agl.terrainElevation, isNull);
    });

    test('Bilinear interpolation calculates smooth elevations between pixels correctly', () async {
      final service = TerrainElevationService();
      service.clearCache();

      final Uint8List rawBytes = Uint8List(256 * 256 * 4);
      final ByteData mockByteData = ByteData.sublistView(rawBytes);

      // (0,0) to R=128, G=0, B=0 -> elevation = 0m
      // (1,0) to R=128, G=100, B=0 -> elevation = 100m
      // (0,1) to R=128, G=0, B=0 -> elevation = 0m
      // (1,1) to R=128, G=100, B=0 -> elevation = 100m
      
      mockByteData.setUint8(0, 128);
      mockByteData.setUint8(3, 255);

      mockByteData.setUint8(4, 128);
      mockByteData.setUint8(5, 100);
      mockByteData.setUint8(7, 255);

      final int rowSize = 256 * 4;
      mockByteData.setUint8(rowSize, 128);
      mockByteData.setUint8(rowSize + 3, 255);

      mockByteData.setUint8(rowSize + 4, 128);
      mockByteData.setUint8(rowSize + 5, 100);
      mockByteData.setUint8(rowSize + 7, 255);

      service.setMockCache(2048, 2048, mockByteData);

      // If we query half-way in longitude: pixelX = 0.5.
      // With linear interpolation along X between 0m and 100m, it should return exactly 50m!
      final double? halfElevation = await service.getElevation(0.0, 0.000171875);
      expect(halfElevation, closeTo(50.0, 0.1));
    });

    test('TileCache caches failed (null) tile fetches and prevents duplicate requests', () async {
      final service = TerrainElevationService();
      service.clearCache();

      // The tile is not in cache, and it will fail to fetch (returns null in tests)
      final double? elev1 = await service.getElevation(45.0, 45.0);
      expect(elev1, isNull);

      // Now it should be cached as null.
      expect(service.isTileCached(45.0, 45.0), isTrue);

      // If we query again, it should return null instantly from the cache
      final double? elev2 = await service.getElevation(45.0, 45.0);
      expect(elev2, isNull);
    });

    test('terrainElevation notifier returns cached values synchronously without transitioning to loading', () {
      final service = TerrainElevationService();
      service.clearCache();

      final Uint8List rawBytes = Uint8List(256 * 256 * 4);
      final ByteData mockByteData = ByteData.sublistView(rawBytes);
      mockByteData.setUint8(0, 162);
      mockByteData.setUint8(1, 144);
      mockByteData.setUint8(3, 255);
      service.setMockCache(2048, 2048, mockByteData);

      final container = ProviderContainer(
        overrides: [
          terrainElevationServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      var elevationState = container.read(terrainElevationProvider);
      expect(elevationState, const AsyncValue<double?>.data(null));

      container.read(telemetryProvider.notifier).updateGPS(
        latitude: 0.0,
        longitude: 0.0,
      );

      elevationState = container.read(terrainElevationProvider);
      expect(elevationState.isLoading, isFalse);
      expect(elevationState.value, equals(8848.0));
    });

    test('AviationMath.altitudeToQnhHpa calculates sea-level pressure correctly', () {
      // At 0m elevation, QNH is exactly the measured pressure
      expect(AviationMath.altitudeToQnhHpa(101325, 0), closeTo(1013.25, 0.01));
      
      // Known altitude check
      // Measured: 90000 Pa at 988.61m elevation -> QNH should be 1013.25 hPa
      expect(AviationMath.altitudeToQnhHpa(90000, 988.61), closeTo(1013.25, 0.05));
    });

    testWidgets('aglProvider performs auto-QNH calibration when on the ground and conditions are met', (WidgetTester tester) async {
      final service = TerrainElevationService();
      service.clearCache();

      final Uint8List rawBytes = Uint8List(256 * 256 * 4);
      final ByteData mockByteData = ByteData.sublistView(rawBytes);
      mockByteData.setUint8(0, 162);
      mockByteData.setUint8(1, 144);
      mockByteData.setUint8(2, 0);
      mockByteData.setUint8(3, 255);
      service.setMockCache(2048, 2048, mockByteData);

      final container = ProviderContainer(
        overrides: [
          terrainElevationServiceProvider.overrideWithValue(service),
          appSettingsProvider.overrideWith(() => FakeAppSettingsNotifier(
            const AppSettings(autoQnh: true, qnh: 1013.25),
          )),
        ],
      );
      addTearDown(container.dispose);

      container.listen(telemetryProvider, (_, _) {});
      container.listen(aglProvider, (_, _) {});

      container.read(telemetryProvider.notifier).updatePressure(90000);
      container.read(telemetryProvider.notifier).updateGPS(
        latitude: 0.0,
        longitude: 0.0,
        gpsVerticalAccuracy: 5.0,
      );

      await tester.pump(const Duration(milliseconds: 500));
      container.read(telemetryProvider.notifier).updatePressure(90000);
      container.read(telemetryProvider.notifier).updateGPS(
        latitude: 0.0,
        longitude: 0.0,
        gpsVerticalAccuracy: 5.0,
      );

      await tester.pump(const Duration(milliseconds: 500));
      container.read(telemetryProvider.notifier).updatePressure(90000);
      container.read(telemetryProvider.notifier).updateGPS(
        latitude: 0.0,
        longitude: 0.0,
        gpsVerticalAccuracy: 5.0,
      );

      await tester.pump(const Duration(milliseconds: 500));
      container.read(telemetryProvider.notifier).updatePressure(90000);
      container.read(telemetryProvider.notifier).updateGPS(
        latitude: 0.0,
        longitude: 0.0,
        gpsVerticalAccuracy: 5.0,
      );

      await tester.pump(const Duration(milliseconds: 500));
      container.read(telemetryProvider.notifier).updatePressure(90000);
      container.read(telemetryProvider.notifier).updateGPS(
        latitude: 0.0,
        longitude: 0.0,
        gpsVerticalAccuracy: 5.0,
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      final currentSettings = container.read(appSettingsProvider).value;
      expect(currentSettings, isNotNull);
      expect(currentSettings!.qnh, equals(AviationMath.maxQnhHpa));

      container.dispose();
    });

    test('aglProvider does NOT perform auto-QNH calibration when isFlying is true', () async {
      final service = TerrainElevationService();
      service.clearCache();

      final Uint8List rawBytes = Uint8List(256 * 256 * 4);
      final ByteData mockByteData = ByteData.sublistView(rawBytes);
      mockByteData.setUint8(0, 162);
      mockByteData.setUint8(1, 144);
      mockByteData.setUint8(2, 0);
      mockByteData.setUint8(3, 255);
      service.setMockCache(2048, 2048, mockByteData);

      final container = ProviderContainer(
        overrides: [
          terrainElevationServiceProvider.overrideWithValue(service),
          appSettingsProvider.overrideWith(() => FakeAppSettingsNotifier(
            const AppSettings(autoQnh: true, qnh: 1013.25),
          )),
        ],
      );
      addTearDown(container.dispose);

      container.listen(telemetryProvider, (_, _) {});
      container.listen(aglProvider, (_, _) {});

      container.read(telemetryProvider.notifier).updateGPS(
        latitude: 0.0,
        longitude: 0.0,
        gpsVerticalAccuracy: 5.0,
        groundSpeed: 10.0,
      );
      container.read(telemetryProvider.notifier).updatePressure(90000);

      await Future.delayed(const Duration(milliseconds: 100));

      final currentSettings = container.read(appSettingsProvider).value;
      expect(currentSettings!.qnh, equals(1013.25));
    });
  });
}

class MockAppSettingsNotifier extends AppSettingsNotifier {
  @override
  Future<AppSettings> build() async {
    return const AppSettings();
  }
}

class FakeAppSettingsNotifier extends AppSettingsNotifier {
  final AppSettings initialSettings;
  FakeAppSettingsNotifier([this.initialSettings = const AppSettings()]);

  @override
  Future<AppSettings> build() async {
    return initialSettings;
  }

  @override
  Future<SettingsUpdateResult> updateQnh(double qnh) async {
    state = AsyncData(state.value!.copyWith(qnh: qnh));
    return const SettingsUpdateSuccess();
  }
}
