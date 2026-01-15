class PlaylistModel {
  final String id;
  final String name;
  final String description;
  final int trackCount;
  final String artworkUrl;
  final String curatorName;

  PlaylistModel({
    required this.id,
    required this.name,
    this.description = '',
    this.trackCount = 0,
    this.artworkUrl = '',
    this.curatorName = '',
  });

  factory PlaylistModel.fromMap(Map<String, dynamic> map) {
    return PlaylistModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      trackCount: map['trackCount'] ?? 0,
      artworkUrl: map['artworkUrl'] ?? '',
      curatorName: map['curatorName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'trackCount': trackCount,
      'artworkUrl': artworkUrl,
      'curatorName': curatorName,
    };
  }

  PlaylistModel copyWith({
    String? id,
    String? name,
    String? description,
    int? trackCount,
    String? artworkUrl,
    String? curatorName,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      trackCount: trackCount ?? this.trackCount,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      curatorName: curatorName ?? this.curatorName,
    );
  }
}
