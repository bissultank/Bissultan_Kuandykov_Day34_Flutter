import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_sample/services/auth_service.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _photoController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _photoController = TextEditingController(text: user?.photoURL ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.updateProfile(
        displayName: _nameController.text.trim(),
        photoURL: _photoController.text.trim().isEmpty
            ? null
            : _photoController.text.trim(),
      );

      if (mounted) {
        // Перерисовываем виджет чтобы подхватить обновлённые данные
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Профиль обновлён'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Аватар ──────────────────────────────────────────────
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.deepPurple.shade100,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? Text(
                            (user?.displayName?.isNotEmpty == true)
                                ? user!.displayName![0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontSize: 36,
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Имя ─────────────────────────────────────────────────
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Отображаемое имя',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Введите имя' : null,
                ),
                const SizedBox(height: 16),

                // ── URL фото ─────────────────────────────────────────────
                TextFormField(
                  controller: _photoController,
                  decoration: const InputDecoration(
                    labelText: 'Ссылка на фото (URL)',
                    prefixIcon: Icon(Icons.image_outlined),
                    hintText: 'https://example.com/photo.jpg',
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 32),

                // ── Кнопка сохранить ─────────────────────────────────────
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Сохранить',
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
