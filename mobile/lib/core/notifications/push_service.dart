import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

import 'package:feedback_app/core/constants/api_constants.dart';
import 'package:feedback_app/core/network/token_store.dart';
import 'package:feedback_app/features/feedback/presentation/pages/feedback_detail_page.dart';
import 'package:feedback_app/features/polls/presentation/pages/poll_detail_page.dart';

/// FCM push notifications: permission, token registration and routing.
///
/// Registered tokens are stored against the signed-in user by
/// notification-service, which pushes on report status changes.
class PushService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static bool _initialized = false;
  static StreamSubscription<RemoteMessage>? _foregroundSub;
  static StreamSubscription<RemoteMessage>? _tapSub;

  /// Must be called before runApp (configures Firebase for Android).
  static Future<void> preload() async {
    await Firebase.initializeApp();
    // Background/terminated taps need an isolate-level handler.
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
  }

  /// Call whenever the user is (or becomes) authenticated.
  static Future<void> register(TokenStore tokenStore) async {
    if (_initialized) return;
    try {
      // Android 13+ requires the runtime notification permission.
      await FirebaseMessaging.instance.requestPermission(
        alert: true, badge: true, sound: true,
      );
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _sendToken(tokenStore, token);
      }
      // Token rotation (app restore, key invalidation).
      FirebaseMessaging.instance.onTokenRefresh
          .listen((token) => _sendToken(tokenStore, token));

      // Foreground: show an in-app banner via the material context.
      _foregroundSub ??= FirebaseMessaging.onMessage.listen((message) {
        final context = navigatorKey.currentContext;
        if (context == null || !context.mounted) return;
        final body = message.notification?.body ?? 'Your report was updated';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(body), duration: const Duration(seconds: 4)),
        );
      });

      // Tap while app is open in background → deep-link.
      _tapSub ??= FirebaseMessaging.onMessageOpenedApp.listen(_routeToTarget);
      _initialized = true;
    } catch (e) {
      debugPrint('Push init skipped: $e');
    }
  }

  /// Cold-start tap: the app was terminated; Firebase delivers the payload.
  static Future<void> handleInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) _routeToTarget(message);
  }

  static void _routeToTarget(RemoteMessage message) {
    final reportId = message.data['reportId'];
    final pollId = message.data['pollId'];
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    if (reportId != null) {
      navigator.push(MaterialPageRoute(
        builder: (_) => FeedbackDetailPage(feedbackId: int.parse(reportId)),
      ));
    } else if (pollId != null) {
      navigator.push(MaterialPageRoute(
        builder: (_) => PollDetailPage(pollId: int.parse(pollId)),
      ));
    }
  }

  static Future<void> _sendToken(TokenStore tokenStore, String token) async {
    // Registered through the gateway; the ApiClient attaches the JWT.
    final access = await tokenStore.readAccessToken();
    if (access == null) return; // not signed in yet
    final client = http.Client();
    try {
      await client.post(
        Uri.parse('${ApiConstants.baseUrl}/notifications/register-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $access',
        },
        body: '{"token":"$token"}',
      );
    } finally {
      client.close();
    }
  }

}

/// Background isolate entry point — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // No UI in the background isolate; Android shows the notification itself.
}
