class AirportImage {
  final String id;
  final String filename;

  AirportImage({required this.id, required this.filename});

  factory AirportImage.fromJson(Map<String, Object?> json) {
    return AirportImage(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      filename: (json['filename'] ?? '').toString(),
    );
  }

  Map<String, Object?> toJson() {
    return {'_id': id, 'filename': filename};
  }
}
