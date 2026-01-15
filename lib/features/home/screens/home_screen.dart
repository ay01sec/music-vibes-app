import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/timeline_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/native_ad_widget.dart';
import '../../post/screens/create_post_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../social/screens/search_screen.dart';
import '../../../core/constants/app_constants.dart';
import 'dart:math';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final List<int> _adPositions = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _calculateAdPositions();
  }

  void _calculateAdPositions() {
    _adPositions.clear();
    int currentPosition = 0;

    for (int i = 0; i < 10; i++) {
      int interval = _random.nextInt(AppConstants.maxAdInterval - AppConstants.minAdInterval + 1) + AppConstants.minAdInterval;
      currentPosition += interval;
      _adPositions.add(currentPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildTimeline(),
          const SearchScreen(),
          const SizedBox(), // Placeholder for create post
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatePostScreen()),
            );
          } else {
            setState(() => _currentIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: '検索',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: '投稿',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'プロフィール',
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final timelineState = ref.watch(timelineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Music Vibes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _calculateAdPositions();
          await ref.read(timelineProvider.notifier).refresh();
        },
        child: timelineState.isLoading && timelineState.posts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : timelineState.error != null && timelineState.posts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'エラーが発生しました',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(timelineProvider.notifier).refresh(),
                          child: const Text('再読み込み'),
                        ),
                      ],
                    ),
                  )
                : timelineState.posts.isEmpty
                    ? _buildEmptyTimeline()
                    : _buildPostList(timelineState),
      ),
    );
  }

  Widget _buildEmptyTimeline() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'まだ投稿がありません',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '最初の投稿をしてみましょう',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePostScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('投稿する'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostList(TimelineState timelineState) {
    final posts = timelineState.posts;
    int adsInserted = 0;

    return ListView.builder(
      itemCount: posts.length + _adPositions.where((p) => p <= posts.length).length,
      itemBuilder: (context, index) {
        // Calculate how many ads should be before this index
        int adsBeforeIndex = _adPositions.where((p) => p <= index - adsInserted).length;

        // Check if current index is an ad position
        if (_adPositions.contains(index - adsInserted + 1) && adsBeforeIndex <= adsInserted) {
          adsInserted++;
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: NativeAdWidget(),
          );
        }

        int postIndex = index - _adPositions.where((p) => p <= index).length;
        if (postIndex >= 0 && postIndex < posts.length) {
          final post = posts[postIndex];

          // Load more when reaching end
          if (postIndex == posts.length - 3 && timelineState.hasMore && !timelineState.isLoading) {
            ref.read(timelineProvider.notifier).loadMore();
          }

          return PostCard(
            post: post,
            onLike: () => ref.read(timelineProvider.notifier).toggleLike(post.id),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
