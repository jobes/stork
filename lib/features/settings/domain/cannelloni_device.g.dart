// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cannelloni_device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CannelloniDevice _$CannelloniDeviceFromJson(Map<String, dynamic> json) =>
    _CannelloniDevice(
      name: json['name'] as String,
      hostname: json['hostname'] as String,
      ip: json['ip'] as String,
      port: (json['port'] as num).toInt(),
    );

Map<String, dynamic> _$CannelloniDeviceToJson(_CannelloniDevice instance) =>
    <String, dynamic>{
      'name': instance.name,
      'hostname': instance.hostname,
      'ip': instance.ip,
      'port': instance.port,
    };
