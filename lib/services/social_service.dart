import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/auth/models/user_model.dart';
import '../core/constants/app_constants.dart';

class SocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Follow a user
  Future<void> followUser(String userId, String targetUserId) async {
    final batch = _firestore.batch();

    // Add to user's follows
    final followRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.followsCollection)
        .doc(targetUserId);

    batch.set(followRef, {
      'createdAt': Timestamp.now(),
    });

    // Add to target's followers
    final followerRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(targetUserId)
        .collection(AppConstants.followersCollection)
        .doc(userId);

    batch.set(followerRef, {
      'createdAt': Timestamp.now(),
    });

    // Update counts
    final userRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId);
    batch.update(userRef, {
      'followingCount': FieldValue.increment(1),
    });

    final targetRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(targetUserId);
    batch.update(targetRef, {
      'followerCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // Unfollow a user
  Future<void> unfollowUser(String userId, String targetUserId) async {
    final batch = _firestore.batch();

    // Remove from user's follows
    final followRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.followsCollection)
        .doc(targetUserId);

    batch.delete(followRef);

    // Remove from target's followers
    final followerRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(targetUserId)
        .collection(AppConstants.followersCollection)
        .doc(userId);

    batch.delete(followerRef);

    // Update counts
    final userRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId);
    batch.update(userRef, {
      'followingCount': FieldValue.increment(-1),
    });

    final targetRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(targetUserId);
    batch.update(targetRef, {
      'followerCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  // Check if following
  Future<bool> isFollowing(String userId, String targetUserId) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.followsCollection)
        .doc(targetUserId)
        .get();

    return doc.exists;
  }

  // Get followers
  Future<List<UserModel>> getFollowers({
    required String userId,
    DocumentSnapshot? lastDocument,
    int limit = 30,
  }) async {
    Query query = _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.followersCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();

    List<UserModel> users = [];
    for (final doc in snapshot.docs) {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(doc.id)
          .get();

      if (userDoc.exists) {
        users.add(UserModel.fromFirestore(userDoc));
      }
    }

    return users;
  }

  // Get following
  Future<List<UserModel>> getFollowing({
    required String userId,
    DocumentSnapshot? lastDocument,
    int limit = 30,
  }) async {
    Query query = _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.followsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();

    List<UserModel> users = [];
    for (final doc in snapshot.docs) {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(doc.id)
          .get();

      if (userDoc.exists) {
        users.add(UserModel.fromFirestore(userDoc));
      }
    }

    return users;
  }

  // Search users
  Future<List<UserModel>> searchUsers(String query, {int limit = 20}) async {
    if (query.isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();

    // Search by username (prefix match)
    final usernameSnapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .where('username', isGreaterThanOrEqualTo: lowercaseQuery)
        .where('username', isLessThan: '${lowercaseQuery}z')
        .limit(limit)
        .get();

    final users = usernameSnapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();

    return users;
  }
}
