import '../models/app_notification.dart';
import 'supabase_status.dart';

class NotificationRepository {
  Future<List<AppNotification>> fetchRecentNotifications() async {
    if (!SupabaseStatus.isConfigured) {
      return _demoNotifications;
    }

    final user = SupabaseStatus.client.auth.currentUser;
    if (user == null) {
      return [];
    }

    final rows = await SupabaseStatus.client
        .from('notifications')
        .select('id, title, body, type, is_read, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(10);

    return rows
        .cast<Map<String, dynamic>>()
        .map(AppNotification.fromMap)
        .toList();
  }

  Future<void> markAllRead() async {
    if (!SupabaseStatus.isConfigured) {
      return;
    }

    final user = SupabaseStatus.client.auth.currentUser;
    if (user == null) {
      return;
    }

    await SupabaseStatus.client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', user.id)
        .eq('is_read', false);
  }
}

final _demoNotifications = [
  AppNotification(
    id: 'demo-notification-1',
    title: 'Worker profile approved',
    body: 'Your MediConnect worker profile is approved.',
    type: 'verification',
    isRead: false,
    createdAt: DateTime(2026, 6, 14, 10, 30),
  ),
];
