import 'package:freezed_annotation/freezed_annotation.dart';

part 'cannelloni_device.freezed.dart';
part 'cannelloni_device.g.dart';

@freezed
abstract class CannelloniDevice with _$CannelloniDevice {
  const factory CannelloniDevice({
    required String name,
    required String hostname,
    required String ip,
    required int port,
  }) = _CannelloniDevice;

  factory CannelloniDevice.fromJson(Map<String, dynamic> json) =>
      _$CannelloniDeviceFromJson(json);
}

