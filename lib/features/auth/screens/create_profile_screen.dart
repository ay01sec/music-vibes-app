import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  String? _usernameError;

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _usernameError = null;
    });

    final success = await ref.read(authNotifierProvider.notifier).createProfile(
      displayName: _displayNameController.text.trim(),
      username: _usernameController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!success && mounted) {
      setState(() {
        _usernameError = 'このユーザー名は既に使用されています';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール作成'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'あなたのプロフィールを\n作成しましょう',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                // Display Name
                const Text(
                  '表示名',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    hintText: '表示名を入力',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '表示名を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Username
                const Text(
                  'ユーザー名',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: 'username',
                    prefixText: '@',
                    errorText: _usernameError,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'ユーザー名を入力してください';
                    }
                    if (value.length < AppConstants.minUsernameLength) {
                      return 'ユーザー名は${AppConstants.minUsernameLength}文字以上で入力してください';
                    }
                    if (value.length > AppConstants.maxUsernameLength) {
                      return 'ユーザー名は${AppConstants.maxUsernameLength}文字以下で入力してください';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                      return '英数字とアンダースコアのみ使用できます';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '英数字とアンダースコアのみ。${AppConstants.minUsernameLength}〜${AppConstants.maxUsernameLength}文字',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createProfile,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            '始める',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
