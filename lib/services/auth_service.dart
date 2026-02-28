import 'package:firebase_auth/firebase_auth.dart';

/// Все ошибки Firebase переводим в понятный русский текст
String firebaseErrorToMessage(String code) {
  switch (code) {
    case 'user-not-found':
      return 'Пользователь с таким email не найден';
    case 'wrong-password':
      return 'Неверный пароль';
    case 'invalid-credential':
      return 'Неверный email или пароль';
    case 'email-already-in-use':
      return 'Этот email уже зарегистрирован';
    case 'invalid-email':
      return 'Некорректный формат email';
    case 'weak-password':
      return 'Пароль слишком слабый (минимум 6 символов)';
    case 'user-disabled':
      return 'Аккаунт заблокирован';
    case 'too-many-requests':
      return 'Слишком много попыток. Попробуйте позже';
    case 'network-request-failed':
      return 'Нет соединения с интернетом';
    default:
      return 'Произошла ошибка: $code';
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Поток состояния авторизации — используется в main.dart для роутинга
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Текущий пользователь (может быть null)
  User? get currentUser => _auth.currentUser;

  /// Регистрация + сохранение displayName
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Сохраняем имя сразу после регистрации
    await credential.user?.updateDisplayName(name);
    // Обновляем локальный объект пользователя
    await _auth.currentUser?.reload();
  }

  /// Вход по email/password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Выход
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Сброс пароля — отправляет письмо на email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Обновление профиля: имя и/или фото
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    await _auth.currentUser?.updateDisplayName(displayName);
    if (photoURL != null) {
      await _auth.currentUser?.updatePhotoURL(photoURL);
    }
    await _auth.currentUser?.reload();
  }
}
