import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OgnTrafficAircraft {
  final String id;
  final String callsign;
  final String? registration;
  final String? aircraftModel;
  final String? cn;
  final double latitude;
  final double longitude;
  final double altitude; // AMSL in meters
  final double track; // degrees
  final double groundSpeed; // m/s
  final double verticalSpeed; // m/s (vario)
  final int aircraftType;
  final DateTime lastSeen;
  final bool isAnonymous;

  OgnTrafficAircraft({
    required this.id,
    required this.callsign,
    this.registration,
    this.aircraftModel,
    this.cn,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.track,
    required this.groundSpeed,
    required this.verticalSpeed,
    required this.aircraftType,
    required this.lastSeen,
    this.isAnonymous = false,
  });

  OgnTrafficAircraft copyWith({
    String? id,
    String? callsign,
    String? registration,
    String? aircraftModel,
    String? cn,
    double? latitude,
    double? longitude,
    double? altitude,
    double? track,
    double? groundSpeed,
    double? verticalSpeed,
    int? aircraftType,
    DateTime? lastSeen,
    bool? isAnonymous,
  }) {
    return OgnTrafficAircraft(
      id: id ?? this.id,
      callsign: callsign ?? this.callsign,
      registration: registration ?? this.registration,
      aircraftModel: aircraftModel ?? this.aircraftModel,
      cn: cn ?? this.cn,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      track: track ?? this.track,
      groundSpeed: groundSpeed ?? this.groundSpeed,
      verticalSpeed: verticalSpeed ?? this.verticalSpeed,
      aircraftType: aircraftType ?? this.aircraftType,
      lastSeen: lastSeen ?? this.lastSeen,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }
}

class OgnOutboundIsolate {
  static void entryPoint(SendPort mainSendPort) async {
    final isolateReceivePort = ReceivePort();
    mainSendPort.send(isolateReceivePort.sendPort);

    Socket? socket;
    Timer? keepAliveTimer;
    String? currentCallsign;
    String? currentOgnId;
    int currentAircraftType = 1;

    void disconnect() {
      keepAliveTimer?.cancel();
      socket?.destroy();
      socket = null;
    }

    Future<void> connect() async {
      disconnect();
      try {
        socket = await Socket.connect('aprs.glidernet.org', 14580, timeout: const Duration(seconds: 5));
        
        socket!.listen(
          (data) {
            // Server response ignored or logged minimally
          },
          onError: (e) {
            disconnect();
          },
          onDone: () {
            disconnect();
          },
        );

        socket!.write('user anonymous pass -1 vers storknav 1.0\r\n');
        await socket!.flush();

        keepAliveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
          if (socket != null) {
            socket!.write('# keepalive\r\n');
            socket!.flush();
          }
        });
      } catch (e) {
        // Quiet connect failure
      }
    }

    await connect();

    await for (final message in isolateReceivePort) {
      if (message is Map<String, dynamic>) {
        final command = message['command'] as String?;
        if (command == 'stop') {
          disconnect();
          isolateReceivePort.close();
          break;
        } else if (command == 'config') {
          currentCallsign = message['callsign'] as String?;
          currentOgnId = message['ognId'] as String?;
          currentAircraftType = message['aircraftType'] as int? ?? 1;
        } else if (command == 'position') {
          if (socket == null) {
            await connect();
          }

          if (socket != null && currentCallsign != null && currentOgnId != null) {
            final lat = message['lat'] as double;
            final lon = message['lon'] as double;
            final alt = message['alt'] as double;
            final heading = message['heading'] as double;
            final speed = message['speed'] as double;
            final vs = message['vs'] as double;

            final latDeg = lat.abs().floor();
            final latMin = (lat.abs() - latDeg) * 60.0;
            final latHemi = lat >= 0 ? 'N' : 'S';
            final latStr = '${latDeg.toString().padLeft(2, '0')}${latMin.toStringAsFixed(2).padLeft(5, '0')}$latHemi';

            final lonDeg = lon.abs().floor();
            final lonMin = (lon.abs() - lonDeg) * 60.0;
            final lonHemi = lon >= 0 ? 'E' : 'W';
            final lonStr = '${lonDeg.toString().padLeft(3, '0')}${lonMin.toStringAsFixed(2).padLeft(5, '0')}$lonHemi';

            final trackVal = (heading.round() % 360).toString().padLeft(3, '0');
            final speedKnots = (speed * 1.94384).round().clamp(0, 999).toString().padLeft(3, '0');
            final altFeet = (alt * 3.28084).round().clamp(0, 999999).toString().padLeft(6, '0');
            
            final now = DateTime.now().toUtc();
            final timeStr = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}h';

            final addressType = 3; // OGN Tracker address type
            final xx = (currentAircraftType << 2) | addressType;
            final xxHex = xx.toRadixString(16).padLeft(2, '0').toUpperCase();

            final vsFpm = (vs * 196.8504).round();
            final vsSign = vsFpm >= 0 ? '+' : '-';
            final vsStr = '$vsSign${vsFpm.abs().toString().padLeft(3, '0')}fpm';

            final comment = 'id$xxHex$currentOgnId $vsStr';
            final packet = '$currentCallsign>APRS,TCPIP*,qAC,GLIDERN12:/$timeStr$latStr/$lonStr^$trackVal/$speedKnots/A=$altFeet $comment\r\n';

            socket!.write(packet);
            await socket!.flush();
          }
        }
      }
    }
  }
}

class OgnOutboundManager {
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;

  Future<void> start({
    required String callsign,
    required String ognId,
    int aircraftType = 1,
  }) async {
    await stop();
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(OgnOutboundIsolate.entryPoint, _receivePort!.sendPort);
    
    _sendPort = await _receivePort!.first as SendPort;
    _sendPort!.send({
      'command': 'config',
      'callsign': callsign,
      'ognId': ognId,
      'aircraftType': aircraftType,
    });
  }

  void sendPosition({
    required double lat,
    required double lon,
    required double altitude,
    required double heading,
    required double speed,
    required double vs,
  }) {
    if (_sendPort != null) {
      _sendPort!.send({
        'command': 'position',
        'lat': lat,
        'lon': lon,
        'alt': altitude,
        'heading': heading,
        'speed': speed,
        'vs': vs,
      });
    }
  }

  Future<void> stop() async {
    if (_sendPort != null) {
      _sendPort!.send({'command': 'stop'});
      _sendPort = null;
    }
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
  }
}

class OgnInboundConnection {
  Socket? _socket;
  bool _isConnected = false;
  final Function(String) onLineReceived;
  final VoidCallback onDisconnected;
  String _currentFilter = '';

  OgnInboundConnection({
    required this.onLineReceived,
    required this.onDisconnected,
  });

  Future<void> connect() async {
    await disconnect();
    try {
      _socket = await Socket.connect('aprs.glidernet.org', 14580, timeout: const Duration(seconds: 5));
      _isConnected = true;
      debugPrint('OGN Inbound: Connected to aprs.glidernet.org:14580 🚀');

      _socket!.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen(
        (line) {
          onLineReceived(line);
        },
        onError: (e) {
          debugPrint('OGN Inbound: Socket error: $e');
          disconnect();
        },
        onDone: () {
          debugPrint('OGN Inbound: Socket closed by host');
          disconnect();
        },
      );

      _socket!.write('user anonymous pass -1 vers storknav 1.0\r\n');
      await _socket!.flush();

      if (_currentFilter.isNotEmpty) {
        final cmd = _currentFilter.startsWith('#') ? _currentFilter : '#$_currentFilter';
        debugPrint('OGN Inbound: Sending initial filter -> $cmd');
        _socket!.write('$cmd\r\n');
        await _socket!.flush();
      }
    } catch (e) {
      debugPrint('OGN Inbound: Connection failed: $e');
      _isConnected = false;
      onDisconnected();
    }
  }

  Future<void> updateFilter(String filterCommand) async {
    _currentFilter = filterCommand;
    if (_isConnected && _socket != null) {
      final cmd = filterCommand.startsWith('#') ? filterCommand : '#$filterCommand';
      debugPrint('OGN Inbound: Sending filter command -> $cmd');
      _socket!.write('$cmd\r\n');
      await _socket!.flush();
    }
  }

  Future<void> disconnect() async {
    _isConnected = false;
    await _socket?.close();
    _socket?.destroy();
    _socket = null;
  }
}

class OgnAprsService {
  final http.Client? _client;
  final Map<String, Map<String, String>> _ddbCache = {};

  OgnAprsService({http.Client? client}) : _client = client;

  Future<Map<String, String>?> lookupDdb(String deviceId) async {
    final results = await lookupDdbMultiple([deviceId]);
    return results[deviceId.toUpperCase()];
  }

  Future<Map<String, Map<String, String>>> lookupDdbMultiple(List<String> deviceIds) async {
    final cleanIds = deviceIds.map((id) => id.toUpperCase()).toSet().toList();
    final Map<String, Map<String, String>> results = {};
    final List<String> toFetch = [];

    for (final id in cleanIds) {
      if (_ddbCache.containsKey(id)) {
        results[id] = _ddbCache[id]!;
      } else {
        toFetch.add(id);
      }
    }

    if (toFetch.isEmpty) {
      return results;
    }

    try {
      final idsParam = toFetch.join(',');
      final url = Uri.parse('https://ddb.glidernet.org/download/?j=1&device_id=$idsParam');
      final headers = {
        'User-Agent': 'stork-aprs-app/1.0.0 (https://github.com/vjoba/stork)',
      };
      final response = await (_client != null
              ? _client.get(url, headers: headers)
              : http.get(url, headers: headers))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> devices = data['devices'] ?? [];
        final Map<String, Map<String, String>> fetched = {};
        for (final device in devices) {
          final id = device['device_id']?.toString().toUpperCase();
          if (id != null) {
            fetched[id] = {
              'registration': device['registration']?.toString() ?? '',
              'aircraftModel': device['aircraft_model']?.toString() ?? '',
              'cn': device['cn']?.toString() ?? '',
            };
          }
        }

        for (final id in toFetch) {
          final info = fetched[id] ?? {
            'registration': '',
            'aircraftModel': '',
            'cn': '',
          };
          _ddbCache[id] = info;
          results[id] = info;
        }
      }
    } catch (e) {
      debugPrint('DDB batch lookup failed for $toFetch: $e');
    }

    for (final id in toFetch) {
      if (!results.containsKey(id)) {
        final emptyInfo = {
          'registration': '',
          'aircraftModel': '',
          'cn': '',
        };
        _ddbCache[id] = emptyInfo;
        results[id] = emptyInfo;
      }
    }

    return results;
  }

  OgnTrafficAircraft? parseAprsLine(String line) {
    if (line.startsWith('#')) return null;

    final headerEnd = line.indexOf('>');
    if (headerEnd == -1) return null;
    final rawCallsign = line.substring(0, headerEnd);

    // Coordinate regex for Lat/Lon, Symbol, Course/Speed, Altitude
    final match = RegExp(
      r":[/@](\d{6})h(\d{2})(\d{2}\.\d+)([NS])[\/\\](\d{3})(\d{2}\.\d+)([EW])(.)(?:([\d\s.]{3})\/([\d\s.]{3}))?\/A=(-?\d+)"
    ).firstMatch(line);
    if (match == null) return null;

    final timeStr = match.group(1)!;
    final hour = int.parse(timeStr.substring(0, 2));
    final minute = int.parse(timeStr.substring(2, 4));
    final second = int.parse(timeStr.substring(4, 6));

    final nowUtc = DateTime.now().toUtc();
    var packetTime = DateTime.utc(
      nowUtc.year,
      nowUtc.month,
      nowUtc.day,
      hour,
      minute,
      second,
    );

    if (packetTime.isAfter(nowUtc.add(const Duration(minutes: 5)))) {
      packetTime = packetTime.subtract(const Duration(days: 1));
    }

    final latDeg = double.parse(match.group(2)!);
    final latMin = double.parse(match.group(3)!);
    var lat = latDeg + latMin / 60.0;
    if (match.group(4) == 'S') lat = -lat;

    final lonDeg = double.parse(match.group(5)!);
    final lonMin = double.parse(match.group(6)!);
    var lon = lonDeg + lonMin / 60.0;
    if (match.group(7) == 'W') lon = -lon;

    final trackStr = match.group(9)?.trim() ?? '';
    final track = double.tryParse(trackStr) ?? 0.0;

    final speedStr = match.group(10)?.trim() ?? '';
    final speedKnots = double.tryParse(speedStr) ?? 0.0;
    final groundSpeed = speedKnots * 0.514444; // m/s

    final altStr = match.group(11)!;
    final altFeet = double.tryParse(altStr) ?? 0.0;
    final altitude = altFeet * 0.3048; // meters

    // Parse OGN extension in comment
    final idMatch = RegExp(r'id([0-9a-fA-F]{8})').firstMatch(line);
    var id = rawCallsign;
    var aircraftType = 0;
    var isAnonymous = false;
    if (idMatch != null) {
      final idStr = idMatch.group(1)!;
      final xxStr = idStr.substring(0, 2);
      final yyyyyy = idStr.substring(2);
      final byte = int.parse(xxStr, radix: 16);
      
      final stealth = (byte & 0x80) != 0;
      final noTracking = (byte & 0x40) != 0;
      isAnonymous = stealth || noTracking;
      
      aircraftType = (byte >> 2) & 0x0F;
      id = yyyyyy;
    }

    final vsMatch = RegExp(r'([+-]\d+)fpm').firstMatch(line);
    final vsFpm = vsMatch != null ? (double.tryParse(vsMatch.group(1)!) ?? 0.0) : 0.0;
    final verticalSpeed = vsFpm * 0.00508; // m/s

    return OgnTrafficAircraft(
      id: id,
      callsign: rawCallsign,
      latitude: lat,
      longitude: lon,
      altitude: altitude,
      track: track,
      groundSpeed: groundSpeed,
      verticalSpeed: verticalSpeed,
      aircraftType: aircraftType,
      lastSeen: packetTime,
      isAnonymous: isAnonymous,
    );
  }
}
