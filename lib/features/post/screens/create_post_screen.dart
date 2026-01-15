import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/post_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/timeline_provider.dart';
import '../models/playlist_model.dart';
import '../models/artist_model.dart';
import '../widgets/playlist_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _textController = TextEditingController();
  PlaylistModel? _selectedPlaylist;
  List<ArtistModel> _artists = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _selectPlaylist() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PlaylistPicker(),
    );

    if (result != null) {
      setState(() {
        _selectedPlaylist = result['playlist'] as PlaylistModel;
        _artists = result['artists'] as List<ArtistModel>;
      });
    }
  }

  Future<void> _createPost() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedPlaylist == null) return;

    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(postServiceProvider).createPost(
        userId: user.id,
        text: text,
        playlist: _selectedPlaylist,
        artists: _artists,
      );

      if (mounted) {
        ref.read(timelineProvider.notifier).refresh();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('投稿に失敗しました')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPost = _textController.text.trim().isNotEmpty || _selectedPlaylist != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('投稿作成'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: _isLoading || !canPost ? null : _createPost,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('投稿'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text input
            TextField(
              controller: _textController,
              maxLines: 5,
              maxLength: AppConstants.maxPostLength,
              decoration: const InputDecoration(
                hintText: '今聴いている音楽について共有しよう...',
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            // Playlist selection button
            InkWell(
              onTap: _selectPlaylist,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.queue_music,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'プレイリストを選択',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
            // Selected playlist
            if (_selectedPlaylist != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _selectedPlaylist!.artworkUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _selectedPlaylist!.artworkUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.music_note,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : const Icon(Icons.music_note, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedPlaylist!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_selectedPlaylist!.trackCount}曲',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            if (_artists.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                _artists.take(3).map((a) => a.name).join(', '),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedPlaylist = null;
                            _artists = [];
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
