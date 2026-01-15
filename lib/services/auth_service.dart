import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../features/auth/models/user_model.dart';
import '../core/constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      } else {
        // For mobile platforms, use the new Google Sign-In v7.x API
        final googleSignIn = GoogleSignIn.instance;

        // Initialize if not already done
        await googleSignIn.initialize();

        // Authenticate
        final googleUser = await googleSignIn.authenticate();

        if (googleUser == null) return null;

        // Get authorization for Firebase scopes
        final authorization =
            await googleUser.authorizationClient.authorizationForScopes(['email']);

        if (authorization == null) return null;

        final credential = GoogleAuthProvider.credential(
          accessToken: authorization.accessToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Apple Sign In
  Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      return await _auth.signInWithCredential(oauthCredential);
    } catch (e) {
      debugPrint('Error signing in with Apple: $e');
      rethrow;
    }
  }

  // Check if user exists in Firestore
  Future<bool> userExists(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();
    return doc.exists;
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    final query = await _firestore
        .collection(AppConstants.usersCollection)
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  // Create user profile
  Future<void> createUserProfile({
    required String userId,
    required String displayName,
    required String username,
    String? profileImageUrl,
  }) async {
    final now = DateTime.now();
    final user = UserModel(
      id: userId,
      displayName: displayName,
      username: username.toLowerCase(),
      profileImageUrl: profileImageUrl ?? '',
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .set(user.toFirestore());
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();

    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? bio,
    String? profileImageUrl,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': Timestamp.now(),
    };

    if (displayName != null) updates['displayName'] = displayName;
    if (bio != null) updates['bio'] = bio;
    if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update(updates);
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      // Ignore Google Sign Out errors
    }
    await _auth.signOut();
  }
}
