import 'package:test/test.dart';
import 'package:stork/features/settings/domain/cannelloni_device.dart';

void main() {
  group('CannelloniDevice Equality and Set Filtering', () {
    test('identical instances are equal', () {
      const device1 = CannelloniDevice(
        name: 'avionics-dronecan._cannelloni._udp.local',
        hostname: 'airplane_gateway.local',
        ip: '192.168.0.202',
        port: 20000,
      );

      const device2 = CannelloniDevice(
        name: 'avionics-dronecan._cannelloni._udp.local',
        hostname: 'airplane_gateway.local',
        ip: '192.168.0.202',
        port: 20000,
      );

      expect(device1, equals(device2));
      expect(device1.hashCode, equals(device2.hashCode));
    });

    test('instances with different attributes are not equal', () {
      const device1 = CannelloniDevice(
        name: 'avionics-dronecan._cannelloni._udp.local',
        hostname: 'airplane_gateway.local',
        ip: '192.168.0.202',
        port: 20000,
      );

      const device2 = CannelloniDevice(
        name: 'avionics-dronecan._cannelloni._udp.local',
        hostname: 'airplane_gateway.local',
        ip: '192.168.0.203', // different IP
        port: 20000,
      );

      expect(device1, isNot(equals(device2)));
      expect(device1.hashCode, isNot(equals(device2.hashCode)));
    });

    test('toSet() filters duplicates properly', () {
      const device1 = CannelloniDevice(
        name: 'avionics-dronecan._cannelloni._udp.local',
        hostname: 'airplane_gateway.local',
        ip: '192.168.0.202',
        port: 20000,
      );

      const device2 = CannelloniDevice(
        name: 'avionics-dronecan._cannelloni._udp.local',
        hostname: 'airplane_gateway.local',
        ip: '192.168.0.202',
        port: 20000,
      );

      const device3 = CannelloniDevice(
        name: 'other-dronecan._cannelloni._udp.local',
        hostname: 'other_gateway.local',
        ip: '192.168.0.203',
        port: 20001,
      );

      final list = [device1, device2, device3];
      final uniqueList = list.toSet().toList();

      expect(uniqueList.length, equals(2));
      expect(uniqueList, contains(device1));
      expect(uniqueList, contains(device3));
    });
  });
}
