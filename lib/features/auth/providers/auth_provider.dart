import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/auth_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) async {
      if (user == null) return null;
      return await ref.read(authServiceProvider).getUserProfile(user.uid);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late AuthService _authService;

  @override
  AuthState build() {
    _authService = ref.read(authServiceProvider);
    _init();
    return AuthState(isLoading: true);
  }

  void _init() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        final userModel = await _authService.getUserProfile(user.uid);
        state = state.copyWith(user: userModel, isLoading: false);
      } catch (e) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final credential = await _authService.signInWithGoogle();
      if (credential?.user != null) {
        final exists = await _authService.userExists(credential!.user!.uid);
        if (exists) {
          final userModel = await _authService.getUserProfile(credential.user!.uid);
          state = state.copyWith(user: userModel, isLoading: false);
        } else {
          state = state.copyWith(isLoading: false);
        }
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final credential = await _authService.signInWithApple();
      if (credential?.user != null) {
        final exists = await _authService.userExists(credential!.user!.uid);
        if (exists) {
          final userModel = await _authService.getUserProfile(credential.user!.uid);
          state = state.copyWith(user: userModel, isLoading: false);
        } else {
          state = state.copyWith(isLoading: false);
        }
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createProfile({
    required String displayName,
    required String username,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return false;

    try {
      final isAvailable = await _authService.isUsernameAvailable(username);
      if (!isAvailable) return false;

      await _authService.createUserProfile(
        userId: user.uid,
        displayName: displayName,
        username: username,
        profileImageUrl: user.photoURL,
      );

      final userModel = await _authService.getUserProfile(user.uid);
      state = state.copyWith(user: userModel);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? profileImageUrl,
  }) async {
    final currentUserModel = state.user;
    if (currentUserModel == null) return;

    try {
      await _authService.updateUserProfile(
        userId: currentUserModel.id,
        displayName: displayName,
        bio: bio,
        profileImageUrl: profileImageUrl,
      );

      final updated = await _authService.getUserProfile(currentUserModel.id);
      state = state.copyWith(user: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = AuthState();
  }

  void refresh() {
    _init();
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

// Extension for easy access
extension AuthStateExtension on AuthState {
  UserModel? get valueOrNull => user;
}
