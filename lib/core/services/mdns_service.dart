import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/settings/domain/models/cannelloni_device.dart';

part 'mdns_service.g.dart';

@riverpod
Stream<List<CannelloniDevice>> discoveredDevices(Ref ref) async* {
  // Initial scan
  yield await MDnsService.findCannelloni();

  // Periodic scan every 10 seconds
  final timer = Stream.periodic(const Duration(seconds: 10));
  await for (final _ in timer) {
    yield await MDnsService.findCannelloni();
  }
}

class MDnsService {
  /// Searches for the _cannelloni._udp service, filters for avionics-dronecan,
  /// and returns all discovered services.
  static Future<List<CannelloniDevice>> findCannelloni() async {
    const String serviceType = '_cannelloni._udp.local';
    const String filterPrefix = 'avionics-dronecan.';
    final MDnsClient client = MDnsClient();
    final List<CannelloniDevice> results = [];

    try {
      await client.start();

      // Find pointers for the service type
      final Stream<PtrResourceRecord> ptrStream = client
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer(serviceType),
          );

      // We wait for results for a fixed duration to ensure we collect everything
      await for (final PtrResourceRecord ptr in ptrStream.timeout(
        const Duration(seconds: 2),
        onTimeout: (sink) => sink.close(),
      )) {
        // Filter for our specific instance prefix
        if (!ptr.domainName.startsWith(filterPrefix)) continue;

        // Find service records (contains port and target hostname)
        final Stream<SrvResourceRecord> srvStream = client
            .lookup<SrvResourceRecord>(
              ResourceRecordQuery.service(ptr.domainName),
            );

        await for (final SrvResourceRecord srv in srvStream.timeout(
          const Duration(seconds: 2),
          onTimeout: (sink) => sink.close(),
        )) {
          // Find IPv4 addresses
          final Stream<IPAddressResourceRecord> ipv4Stream = client
              .lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv4(srv.target),
              );

          await for (final IPAddressResourceRecord ip in ipv4Stream.timeout(
            const Duration(seconds: 2),
            onTimeout: (sink) => sink.close(),
          )) {
            results.add(
              CannelloniDevice(
                name: ptr.domainName,
                hostname: srv.target,
                ip: ip.address.address,
                port: srv.port,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (e is! TimeoutException) {
        debugPrint('mDNS: Error during lookup: $e');
      }
    } finally {
      client.stop();
    }

    return results.toSet().toList();
  }
}
