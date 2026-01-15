import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/post/models/post_model.dart';
import '../features/post/models/playlist_model.dart';
import '../features/post/models/artist_model.dart';
import '../features/auth/models/user_model.dart';
import '../core/constants/app_constants.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new post
  Future<String> createPost({
    required String userId,
    required String text,
    PlaylistModel? playlist,
    List<ArtistModel>? artists,
  }) async {
    final topArtistNames = artists != null && artists.isNotEmpty
        ? artists.take(3).map((a) => a.name).join(', ')
        : '';

    final post = PostModel(
      id: '',
      userId: userId,
      text: text,
      playlist: playlist,
      artists: artists ?? [],
      topArtistNames: topArtistNames,
      createdAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection(AppConstants.postsCollection)
        .add(post.toFirestore());

    // Update user's post count
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'postCount': FieldValue.increment(1),
    });

    return docRef.id;
  }

  // Get timeline posts for a user
  Future<List<PostModel>> getTimelinePosts({
    required String userId,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    Query query = _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.timelinesCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final timelineSnap = await query.get();

    List<PostModel> posts = [];
    for (final doc in timelineSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final postId = data['postId'] as String;

      final postDoc = await _firestore
          .collection(AppConstants.postsCollection)
          .doc(postId)
          .get();

      if (postDoc.exists) {
        final postData = postDoc.data()!;
        final postUserId = postData['userId'] as String;

        // Get user info
        final userDoc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(postUserId)
            .get();

        String? displayName;
        String? profileImageUrl;
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          displayName = userData['displayName'] as String?;
          profileImageUrl = userData['profileImageUrl'] as String?;
        }

        // Check if liked
        final likeDoc = await _firestore
            .collection(AppConstants.postsCollection)
            .doc(postId)
            .collection(AppConstants.likesCollection)
            .doc(userId)
            .get();

        posts.add(PostModel.fromFirestore(
          postDoc,
          isLiked: likeDoc.exists,
          userDisplayName: displayName,
          userProfileImageUrl: profileImageUrl,
        ));
      }
    }

    return posts;
  }

  // Get public posts (for users without follows or discovery)
  Future<List<PostModel>> getPublicPosts({
    required String currentUserId,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    Query query = _firestore
        .collection(AppConstants.postsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();

    List<PostModel> posts = [];
    for (final doc in snapshot.docs) {
      final postData = doc.data() as Map<String, dynamic>;
      final postUserId = postData['userId'] as String;

      // Get user info
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(postUserId)
          .get();

      String? displayName;
      String? profileImageUrl;
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        displayName = userData['displayName'] as String?;
        profileImageUrl = userData['profileImageUrl'] as String?;
      }

      // Check if liked
      final likeDoc = await _firestore
          .collection(AppConstants.postsCollection)
          .doc(doc.id)
          .collection(AppConstants.likesCollection)
          .doc(currentUserId)
          .get();

      posts.add(PostModel.fromFirestore(
        doc,
        isLiked: likeDoc.exists,
        userDisplayName: displayName,
        userProfileImageUrl: profileImageUrl,
      ));
    }

    return posts;
  }

  // Get posts by user
  Future<List<PostModel>> getUserPosts({
    required String userId,
    required String currentUserId,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    Query query = _firestore
        .collection(AppConstants.postsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();

    // Get user info once
    final userDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();

    String? displayName;
    String? profileImageUrl;
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      displayName = userData['displayName'] as String?;
      profileImageUrl = userData['profileImageUrl'] as String?;
    }

    List<PostModel> posts = [];
    for (final doc in snapshot.docs) {
      // Check if liked
      final likeDoc = await _firestore
          .collection(AppConstants.postsCollection)
          .doc(doc.id)
          .collection(AppConstants.likesCollection)
          .doc(currentUserId)
          .get();

      posts.add(PostModel.fromFirestore(
        doc,
        isLiked: likeDoc.exists,
        userDisplayName: displayName,
        userProfileImageUrl: profileImageUrl,
      ));
    }

    return posts;
  }

  // Get single post
  Future<PostModel?> getPost(String postId, String currentUserId) async {
    final doc = await _firestore
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .get();

    if (!doc.exists) return null;

    final postData = doc.data()!;
    final postUserId = postData['userId'] as String;

    // Get user info
    final userDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(postUserId)
        .get();

    String? displayName;
    String? profileImageUrl;
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      displayName = userData['displayName'] as String?;
      profileImageUrl = userData['profileImageUrl'] as String?;
    }

    // Check if liked
    final likeDoc = await _firestore
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .collection(AppConstants.likesCollection)
        .doc(currentUserId)
        .get();

    return PostModel.fromFirestore(
      doc,
      isLiked: likeDoc.exists,
      userDisplayName: displayName,
      userProfileImageUrl: profileImageUrl,
    );
  }

  // Delete post
  Future<void> deletePost(String postId, String userId) async {
    await _firestore
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .delete();

    // Update user's post count
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'postCount': FieldValue.increment(-1),
    });
  }

  // Toggle like
  Future<bool> toggleLike(String postId, String userId) async {
    final likeRef = _firestore
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .collection(AppConstants.likesCollection)
        .doc(userId);

    final likeDoc = await likeRef.get();

    if (likeDoc.exists) {
      // Unlike
      await likeRef.delete();
      await _firestore
          .collection(AppConstants.postsCollection)
          .doc(postId)
          .update({
        'likeCount': FieldValue.increment(-1),
      });
      return false;
    } else {
      // Like
      await likeRef.set({
        'userId': userId,
        'createdAt': Timestamp.now(),
      });
      await _firestore
          .collection(AppConstants.postsCollection)
          .doc(postId)
          .update({
        'likeCount': FieldValue.increment(1),
      });
      return true;
    }
  }
}
