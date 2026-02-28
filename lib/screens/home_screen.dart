import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_sample/screens/profile_screen.dart';
import 'package:firebase_auth_sample/services/auth_service.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder подхватывает обновления профиля в реальном времени
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Главный экран'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Выйти',
                onPressed: () async {
                  final confirmed = await _confirmSignOut(context);
                  if (confirmed == true) {
                    await AuthService().signOut();
                  }
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Аватар
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: Colors.deepPurple.shade100,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? Text(
                              _getInitial(user),
                              style: const TextStyle(
                                fontSize: 42,
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Имя
                    Text(
                      user?.displayName?.isNotEmpty == true
                          ? user!.displayName!
                          : 'Нет имени',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),

                    // Email
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    const SizedBox(height: 6),

                    // UID
                    Text(
                      'UID: ${user?.uid ?? '—'}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),

                    // Кнопка редактировать профиль
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Редактировать профиль',
                            style: TextStyle(fontSize: 16)),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Кнопка выйти
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          'Выйти из аккаунта',
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                        onPressed: () async {
                          final confirmed = await _confirmSignOut(context);
                          if (confirmed == true) {
                            await AuthService().signOut();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getInitial(User? user) {
    if (user?.displayName?.isNotEmpty == true) {
      return user!.displayName![0].toUpperCase();
    }
    if (user?.email?.isNotEmpty == true) {
      return user!.email![0].toUpperCase();
    }
    return '?';
  }

  Future<bool?> _confirmSignOut(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Выйти', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
