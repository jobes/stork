import 'dronecan_message.dart';

class GetTransportStats implements DroneCanMessage {
  static const int messageId = 4;
  static const int messageSignature = 0xbe6f76a7ec312b04;
  static const bool messageIsService = true;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;
}
