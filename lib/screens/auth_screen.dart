import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_sample/screens/forgot_password_screen.dart';
import 'package:firebase_auth_sample/services/auth_service.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// true = режим регистрации, false = режим входа
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── Показать SnackBar с ошибкой ────────────────────────────────────────
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Основное действие: войти или зарегистрироваться ────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
        );
      } else {
        await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      // После успешного входа/регистрации authStateChanges в main.dart
      // автоматически переключит на HomeScreen — ничего делать не нужно.
    } on FirebaseAuthException catch (e) {
      _showError(firebaseErrorToMessage(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Переключение между режимами ────────────────────────────────────────
  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Заголовок ──────────────────────────────────────────
                  const Icon(Icons.lock_outline,
                      size: 64, color: Colors.deepPurple),
                  const SizedBox(height: 16),
                  Text(
                    _isSignUp ? 'Создать аккаунт' : 'Вход в аккаунт',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 32),

                  // ── Поле «Имя» — только при регистрации ───────────────
                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Имя',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Введите имя' : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Email ──────────────────────────────────────────────
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Введите email';
                      }
                      if (!v.contains('@')) {
                        return 'Некорректный email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Password ───────────────────────────────────────────
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Введите пароль';
                      if (_isSignUp && v.length < 6) {
                        return 'Минимум 6 символов';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // ── Забыли пароль? — только при входе ─────────────────
                  if (!_isSignUp)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                        child: const Text('Забыли пароль?'),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // ── Кнопка Submit (с индикатором загрузки) ─────────────
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
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
                          : Text(
                              _isSignUp ? 'Зарегистрироваться' : 'Войти',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Переключение режима ────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUp
                            ? 'Уже есть аккаунт? '
                            : 'Нет аккаунта? ',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: _toggleMode,
                        child: Text(
                          _isSignUp ? 'Войти' : 'Зарегистрироваться',
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
