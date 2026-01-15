class ArtistModel {
  final String name;
  final int trackCount;

  ArtistModel({
    required this.name,
    this.trackCount = 0,
  });

  factory ArtistModel.fromMap(Map<String, dynamic> map) {
    return ArtistModel(
      name: map['name'] ?? '',
      trackCount: map['trackCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'trackCount': trackCount,
    };
  }
}
