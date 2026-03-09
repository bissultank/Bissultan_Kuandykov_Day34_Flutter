import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_sample/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../screens/note_form_screen.dart';
import '../screens/notes_screen.dart';
import 'notes_service.dart';

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NotesService _notesService = NotesService();
  final Set<String> _handledMessageIds = <String>{};

  GlobalKey<NavigatorState>? _navigatorKey;
  GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;

  Future<void> init({
    required GlobalKey<NavigatorState> navigatorKey,
    required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  }) async {
    _navigatorKey = navigatorKey;
    _scaffoldMessengerKey = scaffoldMessengerKey;

    await _requestPermissions();
    await _configureForegroundPresentation();
    await _logToken();
    _listenTokenRefresh();
    _listenForegroundMessages();
    await _listenNotificationOpen();
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM permission status: ${settings.authorizationStatus}');
  }

  Future<void> _configureForegroundPresentation() {
    return _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _logToken() async {
    final token = await _messaging.getToken();
    debugPrint('FCM token: $token');
  }

  void _listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) {
      debugPrint('FCM token refreshed: $token');
    });
  }

  void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) {
      if (message.notification == null) return;

      final title = message.notification?.title ?? 'Новое уведомление';
      final body = message.notification?.body ?? '';

      _scaffoldMessengerKey?.currentState?.showSnackBar(
        SnackBar(content: Text('$title\n$body')),
      );
    });
  }

  Future<void> _listenNotificationOpen() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _handleNotificationTap(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  Future<void> _handleNotificationTap(RemoteMessage message) async {
    if (_isAlreadyHandled(message)) return;

    final navigatorState = _navigatorKey?.currentState;
    if (navigatorState == null) return;

    final screen = message.data['screen'] as String?;
    if (screen == null) return;

    if (screen == 'notes') {
      navigatorState.push(MaterialPageRoute(builder: (_) => const NotesScreen()));
      return;
    }

    if (screen == 'note') {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final noteId = message.data['noteId'] as String?;
      if (uid == null || noteId == null || noteId.isEmpty) return;

      final note = await _notesService.getNoteById(uid, noteId);
      if (note == null) {
        _scaffoldMessengerKey?.currentState?.showSnackBar(
          const SnackBar(content: Text('Заметка из уведомления не найдена')),
        );
        return;
      }

      navigatorState.push(
        MaterialPageRoute(builder: (_) => NoteFormScreen(note: note)),
      );
    }
  }

  bool _isAlreadyHandled(RemoteMessage message) {
    final id = message.messageId;
    if (id == null) return false;
    if (_handledMessageIds.contains(id)) return true;
    _handledMessageIds.add(id);
    return false;
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  if (kDebugMode) {
    debugPrint('FCM background message: ${message.messageId}');
  }
}
