import 'dart:convert';
import 'dart:typed_data';

import 'bit_reader.dart';
import 'bit_writer.dart';
import 'dronecan_message.dart';
import 'tail_array.dart';

/// Maximum length of a parameter name (`uint8[<=92]`).
const int paramMaxNameLength = 92;

/// Maximum length of a string parameter value (`uint8[<=128]`).
const int paramMaxStringLength = 128;

/// Tag of the `uavcan.protocol.param.Value` union.
enum ParamValueType {
  empty(0),
  integer(1),
  real(2),
  boolean(3),
  string(4);

  const ParamValueType(this.tag);

  final int tag;

  /// Whether values of this type carry a number.
  bool get isNumeric => this == integer || this == real;
}

/// A single parameter value (`uavcan.protocol.param.Value`).
class ParamValue {
  const ParamValue._({
    required this.type,
    this.integerValue,
    this.realValue,
    this.booleanValue,
    this.stringValue,
  });

  /// Undefined value; used in requests to read a parameter.
  const ParamValue.empty() : this._(type: ParamValueType.empty);

  const ParamValue.integer(int value)
    : this._(type: ParamValueType.integer, integerValue: value);

  const ParamValue.real(double value)
    : this._(type: ParamValueType.real, realValue: value);

  const ParamValue.boolean(bool value)
    : this._(type: ParamValueType.boolean, booleanValue: value);

  const ParamValue.string(String value)
    : this._(type: ParamValueType.string, stringValue: value);

  final ParamValueType type;
  final int? integerValue;
  final double? realValue;
  final bool? booleanValue;
  final String? stringValue;

  bool get isEmpty => type == ParamValueType.empty;

  bool get isNumeric =>
      type == ParamValueType.integer || type == ParamValueType.real;

  @override
  bool operator ==(Object other) {
    return other is ParamValue &&
        other.type == type &&
        other.integerValue == integerValue &&
        other.realValue == realValue &&
        other.booleanValue == booleanValue &&
        other.stringValue == stringValue;
  }

  @override
  int get hashCode =>
      Object.hash(type, integerValue, realValue, booleanValue, stringValue);

  @override
  String toString() => 'ParamValue(${type.name})';
}

/// A numeric bound (`uavcan.protocol.param.NumericValue`).
class ParamNumericValue {
  const ParamNumericValue.integer(int value)
    : integerValue = value,
      realValue = null;

  const ParamNumericValue.real(double value)
    : integerValue = null,
      realValue = value;

  final int? integerValue;
  final double? realValue;

  num? get value => integerValue ?? realValue;

  @override
  String toString() => 'ParamNumericValue(${value ?? '-'})';
}

/// `uavcan.protocol.param.GetSet` request (data type ID 11).
///
/// Parameter sets are always addressed by name; index requests are only meant
/// for enumerating the parameters of a node.
class GetSetRequest implements DroneCanRequestResponseMessage {
  static const int messageId = 11;
  static const int messageSignature = 0xA7B622F939D1A4D5;
  static const bool messageIsService = true;

  const GetSetRequest._({
    required this.index,
    required this.name,
    required this.value,
  });

  /// Requests the parameter at [index], used for the index scan.
  const GetSetRequest.byIndex(int index)
    : this._(index: index, name: '', value: const ParamValue.empty());

  /// Requests the parameter [name]; when [value] is not empty the parameter is
  /// first assigned that value.
  const GetSetRequest.byName(
    String name, {
    ParamValue value = const ParamValue.empty(),
  }) : this._(index: 0, name: name, value: value);

  /// Largest possible request: index, string value and a full name.
  static const int _maxPayloadSize = 224;

  /// Parameter index; ignored by the node when [name] is not empty.
  final int index;

  final String name;

  final ParamValue value;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  @override
  Uint8List toPayload() {
    final nameBytes = utf8.encode(name);
    if (nameBytes.length > paramMaxNameLength) {
      throw ArgumentError(
        'Parameter name is longer than $paramMaxNameLength bytes: '
        '${nameBytes.length}',
      );
    }

    // 13 bits index + value + name. The name is the last field, so DroneCAN
    // omits its 7-bit length prefix on classic CAN (tail array optimization);
    // a trailing zero byte would be read as part of the name, therefore the
    // payload is not padded beyond the written bits.
    final writer = BitWriter(Uint8List(_maxPayloadSize));
    writer.writeUint(index & 0x1FFF, 13);
    _writeValue(writer, value);
    for (final byte in nameBytes) {
      writer.writeUint(byte, 8);
    }
    return writer.toPayload();
  }
}

/// `uavcan.protocol.param.GetSet` response.
class GetSetResponse implements DroneCanMessage {
  static const int messageId = GetSetRequest.messageId;
  static const int messageSignature = GetSetRequest.messageSignature;
  static const bool messageIsService = true;

  const GetSetResponse({
    required this.name,
    this.value,
    this.defaultValue,
    this.maxValue,
    this.minValue,
  });

  /// Parameter name; empty when the node does not know the requested parameter.
  final String name;

  /// Current value, or `null` when the response carries no value.
  final ParamValue? value;

  /// Default value, when the node reports it.
  final ParamValue? defaultValue;

  /// Upper bound, when the node reports it.
  final ParamNumericValue? maxValue;

  /// Lower bound, when the node reports it.
  final ParamNumericValue? minValue;

  /// Whether the node answered with an actual parameter.
  bool get isKnown => name.isNotEmpty && value != null && !value!.isEmpty;

  /// Smallest payload that can hold the fixed part of the response.
  static const int _minPayloadSize = 4;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  /// Decodes a `uavcan.protocol.param.GetSet` response.
  ///
  /// Layout: `void5`, `value` (`Value`), `void5`, `default_value` (`Value`),
  /// `void6`, `max_value` (`NumericValue`), `void6`, `min_value`
  /// (`NumericValue`) and finally `name` (`uint8[<=92]`).
  ///
  /// Nodes talking DroneCAN on classic CAN omit the name length prefix
  /// (tail-array optimization) and truncate trailing zeros, while older
  /// libuavcan based nodes send a 7-bit length prefix, so both forms are
  /// accepted.
  factory GetSetResponse.fromPayload(Uint8List payload) {
    final source = payload.length >= _minPayloadSize
        ? payload
        : (Uint8List(_minPayloadSize)..setAll(0, payload));

    final reader = BitReader(source);
    reader.skip(5);
    final value = _readValue(reader);
    reader.skip(5);
    final defaultValue = _readValue(reader);
    reader.skip(6);
    final maxValue = _readNumericValue(reader);
    reader.skip(6);
    final minValue = _readNumericValue(reader);
    final name = decodeTailString(
      source,
      reader.bitOffset,
      maxLength: paramMaxNameLength,
    );

    return GetSetResponse(
      name: name,
      value: value.isEmpty ? null : value,
      defaultValue: defaultValue.isEmpty ? null : defaultValue,
      maxValue: maxValue,
      minValue: minValue,
    );
  }
}

/// `uavcan.protocol.param.ExecuteOpcode` request (data type ID 10).
class ExecuteOpcodeRequest implements DroneCanRequestResponseMessage {
  static const int messageId = 10;
  static const int messageSignature = 0x3B131AC5EB69D2CD;
  static const bool messageIsService = true;

  /// Saves all parameters to non-volatile storage.
  static const int opcodeSave = 0;

  /// Clears the non-volatile storage; parameters fall back to their defaults.
  static const int opcodeErase = 1;

  const ExecuteOpcodeRequest(this.opcode, {this.argument = 0});

  final int opcode;

  /// Reserved for future use, must be zero.
  final int argument;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  @override
  Uint8List toPayload() {
    final writer = BitWriter(Uint8List(7));
    writer.writeUint(opcode & 0xFF, 8);
    writer.writeInt(argument, 48);
    return writer.toPayload();
  }
}

/// `uavcan.protocol.param.ExecuteOpcode` response.
class ExecuteOpcodeResponse implements DroneCanMessage {
  static const int messageId = ExecuteOpcodeRequest.messageId;
  static const int messageSignature = ExecuteOpcodeRequest.messageSignature;
  static const bool messageIsService = true;

  const ExecuteOpcodeResponse({required this.ok, this.argument = 0});

  final int argument;

  final bool ok;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  factory ExecuteOpcodeResponse.fromPayload(Uint8List payload) {
    final source = payload.length >= 7
        ? payload
        : (Uint8List(7)..setAll(0, payload));

    final reader = BitReader(source);
    final argument = reader.readInt(48);
    final ok = reader.readUint(1) != 0;
    return ExecuteOpcodeResponse(argument: argument, ok: ok);
  }
}

void _writeValue(BitWriter writer, ParamValue value) {
  writer.writeUint(value.type.tag, 3);
  switch (value.type) {
    case ParamValueType.empty:
      break;
    case ParamValueType.integer:
      writer.writeInt(value.integerValue!, 64);
    case ParamValueType.real:
      writer.writeFloat32(value.realValue!);
    case ParamValueType.boolean:
      writer.writeUint(value.booleanValue! ? 1 : 0, 8);
    case ParamValueType.string:
      final bytes = utf8.encode(value.stringValue!);
      if (bytes.length > paramMaxStringLength) {
        throw ArgumentError(
          'String parameter value is longer than $paramMaxStringLength bytes: '
          '${bytes.length}',
        );
      }
      writer.writeUint(bytes.length, 8);
      for (final byte in bytes) {
        writer.writeUint(byte, 8);
      }
  }
}

ParamValue _readValue(BitReader reader) {
  final tag = reader.readUint(3);
  return switch (tag) {
    0 => const ParamValue.empty(),
    1 => ParamValue.integer(reader.readInt(64)),
    2 => ParamValue.real(reader.readFloat32()),
    3 => ParamValue.boolean(reader.readUint(8) != 0),
    4 => ParamValue.string(_readString(reader)),
    _ => throw FormatException('Unknown parameter value tag: $tag'),
  };
}

String _readString(BitReader reader) {
  final length = reader.readUint(8);
  final bytes = List<int>.generate(
    length,
    (_) => reader.readUint(8),
    growable: false,
  );
  return utf8.decode(bytes, allowMalformed: true);
}

ParamNumericValue? _readNumericValue(BitReader reader) {
  final tag = reader.readUint(2);
  return switch (tag) {
    0 => null,
    1 => ParamNumericValue.integer(reader.readInt(64)),
    2 => ParamNumericValue.real(reader.readFloat32()),
    _ => throw FormatException('Unknown numeric parameter value tag: $tag'),
  };
}
