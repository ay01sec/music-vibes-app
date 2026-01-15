import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/post_service.dart';
import '../../post/models/post_model.dart';
import '../../auth/providers/auth_provider.dart';

final postServiceProvider = Provider<PostService>((ref) => PostService());

class TimelineState {
  final List<PostModel> posts;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  TimelineState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  TimelineState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return TimelineState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class TimelineNotifier extends Notifier<TimelineState> {
  late PostService _postService;
  late String _userId;

  @override
  TimelineState build() {
    _postService = ref.read(postServiceProvider);
    final authState = ref.watch(authNotifierProvider);
    _userId = authState.user?.id ?? '';

    if (_userId.isNotEmpty) {
      loadPosts();
    }

    return TimelineState();
  }

  Future<void> loadPosts() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final posts = await _postService.getPublicPosts(
        currentUserId: _userId,
        limit: 20,
      );

      state = state.copyWith(
        posts: posts,
        isLoading: false,
        hasMore: posts.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final posts = await _postService.getPublicPosts(
        currentUserId: _userId,
        limit: 20,
      );

      state = state.copyWith(
        posts: [...state.posts, ...posts],
        isLoading: false,
        hasMore: posts.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    state = TimelineState();
    await loadPosts();
  }

  Future<void> toggleLike(String postId) async {
    try {
      final isLiked = await _postService.toggleLike(postId, _userId);

      final updatedPosts = state.posts.map((post) {
        if (post.id == postId) {
          return post.copyWith(
            isLiked: isLiked,
            likeCount: isLiked ? post.likeCount + 1 : post.likeCount - 1,
          );
        }
        return post;
      }).toList();

      state = state.copyWith(posts: updatedPosts);
    } catch (e) {
      // Handle error
    }
  }
}

final timelineProvider = NotifierProvider<TimelineNotifier, TimelineState>(() {
  return TimelineNotifier();
});
