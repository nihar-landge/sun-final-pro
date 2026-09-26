import 'package:feedback_app/core/constants/api_constants.dart';
import 'package:feedback_app/core/network/api_client.dart';

/// The citizen's persistent notification inbox (notification-service).
class NotificationRemoteDataSource {
  final ApiClient apiClient;

  NotificationRemoteDataSource(this.apiClient);

  static String get _base =>
      ApiConstants.feedbackBase.replaceAll('/feedback', '/notifications');

  Future<List<Map<String, dynamic>>> inbox() async {
    final data = await apiClient.getDynamic(Uri.parse('$_base/inbox'), authenticated: true);
    return (data as List? ?? []).whereType<Map<String, dynamic>>().toList();
  }

  Future<int> unreadCount() async {
    final data = await apiClient.get(Uri.parse('$_base/unread-count'), authenticated: true);
    return (data['count'] as num? ?? 0).toInt();
  }

  Future<void> markRead(int notificationId) async {
    await apiClient.post(Uri.parse('$_base/$notificationId/read'), authenticated: true);
  }

  Future<void> markAllRead() async {
    await apiClient.post(Uri.parse('$_base/read-all'), authenticated: true);
  }
}
