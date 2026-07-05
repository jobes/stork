class AirspaceFrequency {
  final String id;
  final String value;
  final bool? primary;

  AirspaceFrequency({required this.id, required this.value, this.primary});

  factory AirspaceFrequency.fromJson(Map<String, Object?> json) {
    return AirspaceFrequency(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      primary: json['primary'] as bool?,
    );
  }

  Map<String, Object?> toJson() {
    return {'_id': id, 'value': value, if (primary != null) 'primary': primary};
  }
}
