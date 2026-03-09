import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_sample/services/auth_service.dart';

void main() {
  test('firebaseErrorToMessage returns localized text', () {
    expect(
      firebaseErrorToMessage('user-not-found'),
      'Пользователь с таким email не найден',
    );
    expect(firebaseErrorToMessage('unknown-code'), 'Произошла ошибка: unknown-code');
  });
}
