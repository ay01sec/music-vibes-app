import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/post_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/timeline_provider.dart';
import '../models/post_model.dart';
import '../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  PostModel? _post;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    try {
      final post = await ref.read(postServiceProvider).getPost(
        widget.postId,
        user.id,
      );
      if (mounted) {
        setState(() {
          _post = post;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_post == null) return;

    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final isLiked = await ref.read(postServiceProvider).toggleLike(
      _post!.id,
      user.id,
    );

    setState(() {
      _post = _post!.copyWith(
        isLiked: isLiked,
        likeCount: isLiked ? _post!.likeCount + 1 : _post!.likeCount - 1,
      );
    });
  }

  Future<void> _playPlaylist() async {
    if (_post?.playlist == null) return;

    // TODO: Implement Apple Music playback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple Musicで再生を開始します')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('投稿詳細'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show options menu
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _post == null
              ? const Center(child: Text('投稿が見つかりませんでした'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _post!.userProfileImageUrl != null &&
                                    _post!.userProfileImageUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(_post!.userProfileImageUrl!)
                                : null,
                            child: _post!.userProfileImageUrl == null ||
                                    _post!.userProfileImageUrl!.isEmpty
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _post!.userDisplayName ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  DateFormat('yyyy/MM/dd HH:mm').format(_post!.createdAt),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Post text
                      Text(
                        _post!.text,
                        style: const TextStyle(fontSize: 16),
                      ),
                      // Playlist info
                      if (_post!.playlist != null) ...[
                        const SizedBox(height: 24),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _post!.playlist!.artworkUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: CachedNetworkImage(
                                            imageUrl: _post!.playlist!.artworkUrl,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => const Icon(
                                              Icons.music_note,
                                              color: Colors.grey,
                                              size: 40,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.music_note,
                                          color: Colors.grey,
                                          size: 40,
                                        ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _post!.playlist!.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_post!.playlist!.trackCount}曲',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      // Artists
                      if (_post!.artists.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'アーティスト',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _post!.artists.map((artist) {
                            return Chip(
                              avatar: const Icon(Icons.person, size: 18),
                              label: Text('${artist.name} (${artist.trackCount}曲)'),
                              backgroundColor: Colors.grey[100],
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // Action buttons
                      Row(
                        children: [
                          if (_post!.playlist != null)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _playPlaylist,
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('試聴する'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          if (_post!.playlist != null) const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: IconButton(
                              onPressed: _toggleLike,
                              icon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _post!.isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: _post!.isLiked ? Colors.red : Colors.grey[600],
                                  ),
                                  if (_post!.likeCount > 0) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_post!.likeCount}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}
