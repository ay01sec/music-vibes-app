import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/create_profile_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/post/screens/create_post_screen.dart';
import '../../features/post/screens/post_detail_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/social/screens/follow_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.user != null || authState.isLoading;
      final hasProfile = authState.user != null;
      final isLoading = authState.isLoading;

      if (isLoading) return null;

      final isOnLoginPage = state.matchedLocation == '/login';
      final isOnCreateProfilePage = state.matchedLocation == '/create-profile';

      if (!isLoggedIn && !isOnLoginPage) {
        return '/login';
      }

      if (isLoggedIn && !hasProfile && !isOnCreateProfilePage) {
        return '/create-profile';
      }

      if (isLoggedIn && hasProfile && (isOnLoginPage || isOnCreateProfilePage)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/create-profile',
        builder: (context, state) => const CreateProfileScreen(),
      ),
      GoRoute(
        path: '/post/create',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/post/:id',
        builder: (context, state) {
          final postId = state.pathParameters['id']!;
          return PostDetailScreen(postId: postId);
        },
      ),
      GoRoute(
        path: '/profile/:id',
        builder: (context, state) {
          final userId = state.pathParameters['id'];
          return ProfileScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/profile/:id/followers',
        builder: (context, state) {
          final userId = state.pathParameters['id']!;
          return FollowListScreen(userId: userId, isFollowers: true);
        },
      ),
      GoRoute(
        path: '/profile/:id/following',
        builder: (context, state) {
          final userId = state.pathParameters['id']!;
          return FollowListScreen(userId: userId, isFollowers: false);
        },
      ),
    ],
  );
});
