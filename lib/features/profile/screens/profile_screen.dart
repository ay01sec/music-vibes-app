import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../../services/post_service.dart';
import '../../post/models/post_model.dart';
import '../../home/widgets/post_card.dart';
import '../../home/providers/timeline_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'edit_profile_screen.dart';
import '../../social/screens/follow_list_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  UserModel? _user;
  List<PostModel> _posts = [];
  bool _isLoading = true;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authService = ref.read(authServiceProvider);
    final currentUser = ref.read(authNotifierProvider).valueOrNull;

    if (widget.userId != null && widget.userId != currentUser?.id) {
      // Load other user's profile
      final user = await authService.getUserProfile(widget.userId!);
      final posts = await ref.read(postServiceProvider).getUserPosts(
        userId: widget.userId!,
        currentUserId: currentUser?.id ?? '',
      );

      // Check if following
      final socialService = ref.read(postServiceProvider);
      // TODO: Check following status

      if (mounted) {
        setState(() {
          _user = user;
          _posts = posts;
          _isLoading = false;
        });
      }
    } else {
      // Load current user's profile
      final user = currentUser;
      if (user != null) {
        final posts = await ref.read(postServiceProvider).getUserPosts(
          userId: user.id,
          currentUserId: user.id,
        );

        if (mounted) {
          setState(() {
            _user = user;
            _posts = posts;
            _isLoading = false;
          });
        }
      }
    }
  }

  bool get _isOwnProfile {
    final currentUser = ref.read(authNotifierProvider).valueOrNull;
    return widget.userId == null || widget.userId == currentUser?.id;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('ユーザーが見つかりませんでした')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_user!.displayName),
        actions: [
          if (_isOwnProfile) ...[
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                _showSettingsMenu();
              },
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(authNotifierProvider.notifier).refresh();
          await _loadProfile();
        },
        child: ListView(
          children: [
            // Profile header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _user!.profileImageUrl.isNotEmpty
                        ? CachedNetworkImageProvider(_user!.profileImageUrl)
                        : null,
                    child: _user!.profileImageUrl.isEmpty
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // Display name
                  Text(
                    _user!.displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Username
                  Text(
                    '@${_user!.username}',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_user!.bio.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _user!.bio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStat('投稿', _user!.postCount, null),
                      const SizedBox(width: 32),
                      _buildStat('フォロワー', _user!.followerCount, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FollowListScreen(
                              userId: _user!.id,
                              isFollowers: true,
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 32),
                      _buildStat('フォロー中', _user!.followingCount, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FollowListScreen(
                              userId: _user!.id,
                              isFollowers: false,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action button
                  if (_isOwnProfile)
                    OutlinedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(user: _user!),
                          ),
                        );
                        _loadProfile();
                      },
                      child: const Text('プロフィールを編集'),
                    )
                  else
                    SizedBox(
                      width: 150,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Toggle follow
                        },
                        style: _isFollowing
                            ? OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryColor,
                              )
                            : null,
                        child: Text(_isFollowing ? 'フォロー中' : 'フォローする'),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),
            // Posts
            if (_posts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.music_note, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      '投稿がありません',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ..._posts.map((post) => PostCard(
                post: post,
                onLike: () async {
                  final currentUser = ref.read(authNotifierProvider).valueOrNull;
                  if (currentUser == null) return;

                  await ref.read(postServiceProvider).toggleLike(
                    post.id,
                    currentUser.id,
                  );
                  _loadProfile();
                },
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, int count, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('ログアウト'),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authNotifierProvider.notifier).signOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
