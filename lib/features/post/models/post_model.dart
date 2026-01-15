import 'package:cloud_firestore/cloud_firestore.dart';
import 'playlist_model.dart';
import 'artist_model.dart';

class PostModel {
  final String id;
  final String userId;
  final String text;
  final PlaylistModel? playlist;
  final List<ArtistModel> artists;
  final String topArtistNames;
  final int likeCount;
  final DateTime createdAt;
  final bool isLiked;

  // User info for display (populated separately)
  final String? userDisplayName;
  final String? userProfileImageUrl;

  PostModel({
    required this.id,
    required this.userId,
    required this.text,
    this.playlist,
    this.artists = const [],
    this.topArtistNames = '',
    this.likeCount = 0,
    required this.createdAt,
    this.isLiked = false,
    this.userDisplayName,
    this.userProfileImageUrl,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc, {bool isLiked = false, String? userDisplayName, String? userProfileImageUrl}) {
    final data = doc.data() as Map<String, dynamic>;

    PlaylistModel? playlist;
    if (data['playlist'] != null) {
      playlist = PlaylistModel.fromMap(data['playlist'] as Map<String, dynamic>);
    }

    List<ArtistModel> artists = [];
    if (data['artists'] != null) {
      artists = (data['artists'] as List<dynamic>)
          .map((e) => ArtistModel.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      text: data['text'] ?? '',
      playlist: playlist,
      artists: artists,
      topArtistNames: data['topArtistNames'] ?? '',
      likeCount: data['likeCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isLiked: isLiked,
      userDisplayName: userDisplayName,
      userProfileImageUrl: userProfileImageUrl,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'text': text,
      'playlist': playlist?.toMap(),
      'artists': artists.map((e) => e.toMap()).toList(),
      'topArtistNames': topArtistNames,
      'likeCount': likeCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? text,
    PlaylistModel? playlist,
    List<ArtistModel>? artists,
    String? topArtistNames,
    int? likeCount,
    DateTime? createdAt,
    bool? isLiked,
    String? userDisplayName,
    String? userProfileImageUrl,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      text: text ?? this.text,
      playlist: playlist ?? this.playlist,
      artists: artists ?? this.artists,
      topArtistNames: topArtistNames ?? this.topArtistNames,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt ?? this.createdAt,
      isLiked: isLiked ?? this.isLiked,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
    );
  }
}
