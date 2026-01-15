import 'package:flutter/material.dart';
import '../models/playlist_model.dart';
import '../models/artist_model.dart';

class PlaylistPicker extends StatefulWidget {
  const PlaylistPicker({super.key});

  @override
  State<PlaylistPicker> createState() => _PlaylistPickerState();
}

class _PlaylistPickerState extends State<PlaylistPicker> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    // TODO: Load actual playlists from Apple Music
    // For now, using mock data
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _playlists = [
        {
          'playlist': PlaylistModel(
            id: '1',
            name: 'お気に入りの曲',
            trackCount: 24,
            artworkUrl: '',
          ),
          'artists': [
            ArtistModel(name: 'アーティストA', trackCount: 5),
            ArtistModel(name: 'アーティストB', trackCount: 4),
            ArtistModel(name: 'アーティストC', trackCount: 3),
          ],
        },
        {
          'playlist': PlaylistModel(
            id: '2',
            name: 'ドライブ用',
            trackCount: 18,
            artworkUrl: '',
          ),
          'artists': [
            ArtistModel(name: 'アーティストD', trackCount: 6),
            ArtistModel(name: 'アーティストE', trackCount: 4),
          ],
        },
        {
          'playlist': PlaylistModel(
            id: '3',
            name: '作業用BGM',
            trackCount: 32,
            artworkUrl: '',
          ),
          'artists': [
            ArtistModel(name: 'アーティストF', trackCount: 8),
            ArtistModel(name: 'アーティストG', trackCount: 6),
            ArtistModel(name: 'アーティストH', trackCount: 5),
          ],
        },
        {
          'playlist': PlaylistModel(
            id: '4',
            name: 'Chill Vibes',
            trackCount: 45,
            artworkUrl: '',
          ),
          'artists': [
            ArtistModel(name: 'アーティストI', trackCount: 10),
            ArtistModel(name: 'アーティストJ', trackCount: 8),
          ],
        },
      ];
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredPlaylists {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _playlists;

    return _playlists.where((item) {
      final playlist = item['playlist'] as PlaylistModel;
      return playlist.name.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'プレイリストを選択',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '検索...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 16),
          // Playlist list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPlaylists.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.queue_music, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'プレイリストが見つかりません',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredPlaylists.length,
                        itemBuilder: (context, index) {
                          final item = _filteredPlaylists[index];
                          final playlist = item['playlist'] as PlaylistModel;
                          final artists = item['artists'] as List<ArtistModel>;

                          return ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: playlist.artworkUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        playlist.artworkUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.music_note, color: Colors.grey),
                                      ),
                                    )
                                  : const Icon(Icons.music_note, color: Colors.grey),
                            ),
                            title: Text(
                              playlist.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text('${playlist.trackCount}曲'),
                            onTap: () {
                              Navigator.pop(context, {
                                'playlist': playlist,
                                'artists': artists,
                              });
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
