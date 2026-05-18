import 'dronecan_message.dart';

class RestartNode implements DroneCanMessage {
  static const int messageId = 5;
  static const int messageSignature = 0x569E05394A3017F0;
  static const bool messageIsService = true;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;
}
