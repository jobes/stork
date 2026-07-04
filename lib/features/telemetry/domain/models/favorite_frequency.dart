class FavoriteFrequency {
  final double mhz;
  final String name;

  FavoriteFrequency({required this.mhz, required this.name});

  Map<String, dynamic> toJson() => {
        'mhz': mhz,
        'name': name,
      };

  factory FavoriteFrequency.fromJson(Map<String, dynamic> json) => FavoriteFrequency(
        mhz: (json['mhz'] as num).toDouble(),
        name: json['name'] as String,
      );
}
