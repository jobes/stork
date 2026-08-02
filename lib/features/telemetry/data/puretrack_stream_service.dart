import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../domain/utils/canonical_id.dart';

class PureTrackPacket {
  final String rawId;
  final String canonicalId;
  final String callsign;
  final String? registration;
  final String? model;
  final String? cn;
  final double latitude;
  final double longitude;
  final double altitude; // AMSL in meters
  final double groundSpeed; // m/s
  final double track; // degrees
  final double verticalSpeed; // m/s
  final int aircraftType;
  final DateTime tSent; // Onboard GPS fix timestamp
  final DateTime tRecv; // Packet reception timestamp

  PureTrackPacket({
    required this.rawId,
    required this.canonicalId,
    required this.callsign,
    this.registration,
    this.model,
    this.cn,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.groundSpeed,
    required this.track,
    required this.verticalSpeed,
    required this.aircraftType,
    required this.tSent,
    DateTime? tRecv,
  }) : tRecv = tRecv ?? DateTime.now();

  /// Parses an official PureTrack packed data row string or JSON map.
  /// PureTrack Traffic API returns data as comma-separated string rows:
  /// e.g. "T1713592586,L-37.78174,G174.88159,A4685,C338,S144.05,V-13.31,O56,DC828EA,EZK-MZE,mANZ118M,KY-ZK-MZE"
  static PureTrackPacket? parseDataRow(String row) {
    if (row.trim().isEmpty) return null;

    final parts = row.split(',');
    final values = <String, String>{};

    for (final part in parts) {
      if (part.isEmpty) continue;
      final key = part[0];
      final val = part.length > 1 ? part.substring(1) : '';
      values[key] = val;
    }

    final lat = double.tryParse(values['L'] ?? '');
    final lon = double.tryParse(values['G'] ?? '');
    if (lat == null || lon == null) return null;

    // Timestamp
    final tsSec = int.tryParse(values['T'] ?? '');
    final DateTime tSent = tsSec != null
        ? DateTime.fromMillisecondsSinceEpoch(tsSec * 1000, isUtc: true)
        : DateTime.now().toUtc();

    // Aircraft identification: D (tracker_uid / FLARM / ICAO hex), K (key), or a (aircraft_id)
    final trackerUid = values['D'];
    final keyVal = values['K'];
    final aircraftId = values['a'] ?? values['J'];
    final rawIdStr = trackerUid ?? keyVal ?? aircraftId ?? '';
    if (rawIdStr.isEmpty) return null;

    final canonical = CanonicalId.normalize(rawIdStr);
    if (canonical.isEmpty) return null;

    final alt = double.tryParse(values['A'] ?? '') ?? 0.0;
    final track = double.tryParse(values['C'] ?? '') ?? 0.0;
    final speed = double.tryParse(values['S'] ?? '') ?? 0.0;
    final vs = double.tryParse(values['V'] ?? '') ?? 0.0;
    final objectType = int.tryParse(values['O'] ?? '') ?? 1;

    final registration = values['E'];
    final model = values['M'];
    final callsignStr =
        values['m'] ?? values['B'] ?? registration ?? values['N'] ?? canonical;
    final cn = values['n'];

    return PureTrackPacket(
      rawId: rawIdStr,
      canonicalId: canonical,
      callsign: callsignStr,
      registration: registration,
      model: model,
      cn: cn,
      latitude: lat,
      longitude: lon,
      altitude: alt,
      groundSpeed: speed,
      track: track,
      verticalSpeed: vs,
      aircraftType: objectType,
      tSent: tSent,
    );
  }

  static PureTrackPacket? fromJson(Map<String, dynamic> json) {
    if (json.containsKey('row') && json['row'] is String) {
      return parseDataRow(json['row'] as String);
    }

    final idRaw =
        json['id'] ??
        json['hex'] ??
        json['target_id'] ??
        json['D'] ??
        json['K'];
    if (idRaw == null || idRaw.toString().isEmpty) return null;
    final rawIdStr = idRaw.toString();
    final canonical = CanonicalId.normalize(rawIdStr);
    if (canonical.isEmpty) return null;

    double? parseNum(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    final lat = parseNum(json['lat'] ?? json['latitude'] ?? json['L']);
    final lon = parseNum(json['lon'] ?? json['longitude'] ?? json['G']);
    if (lat == null || lon == null) return null;

    final alt = parseNum(json['alt'] ?? json['altitude'] ?? json['A']) ?? 0.0;
    final speed =
        parseNum(
          json['speed'] ?? json['ground_speed'] ?? json['gs'] ?? json['S'],
        ) ??
        0.0;
    final track =
        parseNum(json['track'] ?? json['heading'] ?? json['C']) ?? 0.0;
    final vs =
        parseNum(json['vs'] ?? json['vertical_speed'] ?? json['V']) ?? 0.0;

    int parseType(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 1;
      return 1;
    }

    final type = parseType(json['type'] ?? json['aircraft_type'] ?? json['O']);

    DateTime tSent;
    final tsRaw =
        json['timestamp'] ?? json['t_sent'] ?? json['time'] ?? json['T'];
    if (tsRaw is int) {
      tSent = tsRaw < 10000000000
          ? DateTime.fromMillisecondsSinceEpoch(tsRaw * 1000, isUtc: true)
          : DateTime.fromMillisecondsSinceEpoch(tsRaw, isUtc: true);
    } else if (tsRaw is String) {
      tSent = DateTime.parse(tsRaw).toUtc();
    } else {
      tSent = DateTime.now().toUtc();
    }

    final callsign =
        (json['callsign'] ??
                json['name'] ??
                json['m'] ??
                json['B'] ??
                canonical)
            .toString();
    final registration =
        json['registration']?.toString() ?? json['E']?.toString();
    final model = json['model']?.toString() ?? json['M']?.toString();
    final cn = json['cn']?.toString();

    return PureTrackPacket(
      rawId: rawIdStr,
      canonicalId: canonical,
      callsign: callsign,
      registration: registration,
      model: model,
      cn: cn,
      latitude: lat,
      longitude: lon,
      altitude: alt,
      groundSpeed: speed,
      track: track,
      verticalSpeed: vs,
      aircraftType: type,
      tSent: tSent,
    );
  }
}

class PureTrackStreamService {
  final String _baseUrl;
  final String _apiKey;
  final http.Client _client;

  final StreamController<PureTrackPacket> _packetController =
      StreamController<PureTrackPacket>.broadcast();

  Timer? _pollTimer;
  bool _isPolling = false;
  bool _isDisposed = false;
  String? _activeToken;
  VoidCallback? _onUnauthorized;

  double _lat1 = 90.0;
  double _long1 = 180.0;
  double _lat2 = -90.0;
  double _long2 = -180.0;

  Stream<PureTrackPacket> get stream => _packetController.stream;
  bool get isConnected =>
      _activeToken != null && _pollTimer != null && _pollTimer!.isActive;

  final bool _ownsClient;

  PureTrackStreamService({
    this._baseUrl = 'https://puretrack.io',
    String? apiKey,
    http.Client? client,
    VoidCallback? onUnauthorized,
  }) : _apiKey =
           apiKey ??
           (dotenv.isInitialized ? (dotenv.env['PURETRACK_KEY'] ?? '') : ''),
       _ownsClient = client == null,
       _client = client ?? http.Client(),
       // ignore: prefer_initializing_formals
       _onUnauthorized = onUnauthorized;

  void setUnauthorizedHandler(VoidCallback handler) {
    _onUnauthorized = handler;
  }

  void updateViewport({
    required double lat1,
    required double long1,
    required double lat2,
    required double long2,
  }) {
    _lat1 = lat1;
    _long1 = long1;
    _lat2 = lat2;
    _long2 = long2;
  }

  Future<void> connect(String token) async {
    if (_isDisposed) return;
    _activeToken = token;
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _fetchTraffic(); // Fetch immediately on connect
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchTraffic();
    });
  }

  Future<void> _fetchTraffic() async {
    if (_isDisposed || _activeToken == null || _isPolling) return;
    _isPolling = true;

    try {
      final uri = Uri.parse('$_baseUrl/api/traffic').replace(
        queryParameters: {
          'key': _apiKey,
          'lat1': _lat1.toStringAsFixed(4),
          'long1': _long1.toStringAsFixed(4),
          'lat2': _lat2.toStringAsFixed(4),
          'long2': _long2.toStringAsFixed(4),
          't': '5',
        },
      );

      final response = await _client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $_activeToken',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 401) {
        _handleUnauthorized();
        return;
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json is Map<String, dynamic>) {
          if (json['http_code'] == 401 ||
              json['success'] == false && json['http_code'] == 401) {
            _handleUnauthorized();
            return;
          }

          final dataList = json['data'];
          if (dataList is List) {
            for (var i = 0; i < dataList.length; i++) {
              final item = dataList[i];
              if (item is String) {
                final packet = PureTrackPacket.parseDataRow(item);
                if (packet != null) {
                  _packetController.add(packet);
                }
              } else if (item is Map<String, dynamic>) {
                final packet = PureTrackPacket.fromJson(item);
                if (packet != null) {
                  _packetController.add(packet);
                }
              }
              if (i > 0 && i % 100 == 0) {
                await Future<void>.delayed(Duration.zero);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('PureTrack traffic poll error: $e');
    } finally {
      _isPolling = false;
    }
  }

  /// Helper to process raw payload directly (for testing or debugging)
  void processRawPayload(String payload) {
    try {
      final json = jsonDecode(payload);
      if (json is Map<String, dynamic>) {
        if (json['status'] == 401 || json['http_code'] == 401) {
          _handleUnauthorized();
          return;
        }
        final dataList = json['data'];
        if (dataList is List) {
          for (final item in dataList) {
            if (item is String) {
              final packet = PureTrackPacket.parseDataRow(item);
              if (packet != null) {
                _packetController.add(packet);
              }
            } else if (item is Map<String, dynamic>) {
              final packet = PureTrackPacket.fromJson(item);
              if (packet != null) {
                _packetController.add(packet);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing raw PureTrack payload: $e');
    }
  }

  void _handleUnauthorized() {
    disconnect();
    _onUnauthorized?.call();
  }

  void disconnect() {
    _activeToken = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _isPolling = false;
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    if (_ownsClient) {
      _client.close();
    }
    _packetController.close();
  }
}
