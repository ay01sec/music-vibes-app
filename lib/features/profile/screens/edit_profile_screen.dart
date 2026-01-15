import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../../core/constants/app_constants.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.user.displayName);
    _bioController = TextEditingController(text: widget.user.bio);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _checkChanges() {
    final hasChanges = _displayNameController.text != widget.user.displayName ||
        _bioController.text != widget.user.bio;
    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  Future<void> _save() async {
    if (!_hasChanges || _isLoading) return;

    final displayName = _displayNameController.text.trim();
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('表示名を入力してください')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).updateProfile(
        displayName: displayName,
        bio: _bioController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存に失敗しました')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィールを編集'),
        actions: [
          TextButton(
            onPressed: _hasChanges && !_isLoading ? _save : null,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    '保存',
                    style: TextStyle(
                      color: _hasChanges ? null : Colors.grey,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile image
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: widget.user.profileImageUrl.isNotEmpty
                        ? CachedNetworkImageProvider(widget.user.profileImageUrl)
                        : null,
                    child: widget.user.profileImageUrl.isEmpty
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Display name
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: '表示名',
              ),
              onChanged: (_) => _checkChanges(),
            ),
            const SizedBox(height: 16),
            // Bio
            TextField(
              controller: _bioController,
              maxLines: 3,
              maxLength: AppConstants.maxBioLength,
              decoration: const InputDecoration(
                labelText: '自己紹介',
                alignLabelWithHint: true,
              ),
              onChanged: (_) => _checkChanges(),
            ),
            const SizedBox(height: 16),
            // Username (read-only)
            TextFormField(
              initialValue: '@${widget.user.username}',
              readOnly: true,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'ユーザー名',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
