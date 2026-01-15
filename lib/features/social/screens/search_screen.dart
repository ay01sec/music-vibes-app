import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/social_service.dart';
import '../../auth/models/user_model.dart';
import '../../profile/screens/profile_screen.dart';

final socialServiceProvider = Provider<SocialService>((ref) => SocialService());

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  List<UserModel> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await ref.read(socialServiceProvider).searchUsers(query);
      if (mounted) {
        setState(() {
          _results = results;
          _hasSearched = true;
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
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'ユーザーを検索...',
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _search('');
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            if (value.length >= 2) {
              _search(value);
            } else {
              setState(() {
                _results = [];
                _hasSearched = false;
              });
            }
          },
          onSubmitted: _search,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasSearched
              ? _buildEmptyState()
              : _results.isEmpty
                  ? _buildNoResults()
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final user = _results[index];
                        return _buildUserTile(user);
                      },
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'ユーザーを検索',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ユーザー名で検索してフォローしよう',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'ユーザーが見つかりませんでした',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(UserModel user) {
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
  }
}
