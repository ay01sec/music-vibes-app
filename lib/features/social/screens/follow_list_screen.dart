import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/social_service.dart';
import '../../auth/models/user_model.dart';
import '../../profile/screens/profile_screen.dart';
import 'search_screen.dart';

class FollowListScreen extends ConsumerStatefulWidget {
  final String userId;
  final bool isFollowers;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.isFollowers,
  });

  @override
  ConsumerState<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends ConsumerState<FollowListScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final socialService = ref.read(socialServiceProvider);
      final users = widget.isFollowers
          ? await socialService.getFollowers(userId: widget.userId)
          : await socialService.getFollowing(userId: widget.userId);

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFollowers ? 'フォロワー' : 'フォロー中'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        widget.isFollowers
                            ? 'フォロワーがいません'
                            : 'フォロー中のユーザーがいません',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        backgroundImage: user.profileImageUrl.isNotEmpty
                            ? CachedNetworkImageProvider(user.profileImageUrl)
                            : null,
                        child: user.profileImageUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.grey)
                            : null,
                      ),
                      title: Text(
                        user.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text('@${user.username}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(userId: user.id),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
