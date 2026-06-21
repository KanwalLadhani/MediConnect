import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mediconnect/l10n/app_localizations.dart';

import '../../app/app_locale_controller.dart';
import '../../models/app_notification.dart';
import '../../models/user_role.dart';
import '../../services/auth_repository.dart';
import '../../services/notification_repository.dart';
import '../../services/profile_repository.dart';
import '../navigation/role_bottom_navigation.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _profileRepository = ProfileRepository();
  final _notificationRepository = NotificationRepository();
  final _authRepository = AuthRepository();
  late Future<_AccountData> _accountFuture;

  @override
  void initState() {
    super.initState();
    _accountFuture = _fetchAccountData();
  }

  Future<_AccountData> _fetchAccountData() async {
    final data = await Future.wait([
      _profileRepository.fetchCurrentProfile(),
      _notificationRepository.fetchRecentNotifications(),
    ]);

    return _AccountData(
      profile: data[0] as Map<String, dynamic>?,
      notifications: data[1] as List<AppNotification>,
    );
  }

  Future<void> _markNotificationsRead() async {
    await _notificationRepository.markAllRead();
    if (!mounted) {
      return;
    }
    setState(() {
      _accountFuture = _fetchAccountData();
    });
  }

  Future<void> _setLanguage(String languageCode) async {
    await appLocaleController.setLanguage(languageCode);
    if (!mounted) {
      return;
    }
    setState(() {
      _accountFuture = _fetchAccountData();
    });
  }

  Future<void> _signOut() async {
    await _authRepository.signOut();
    if (!mounted) {
      return;
    }
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<_AccountData>(
      future: _accountFuture,
      builder: (context, snapshot) {
        final profile = snapshot.data?.profile;
        final role = UserRole.fromValue(
          profile?['role'] as String? ?? UserRole.patient.value,
        );

        return Scaffold(
          appBar: AppBar(title: Text(l10n.profile)),
          bottomNavigationBar: RoleBottomNavigation(
            role: role,
            currentItem: RoleNavItem.profile,
          ),
          body: _buildBody(context, snapshot, profile, role, l10n),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<_AccountData> snapshot,
    Map<String, dynamic>? profile,
    UserRole role,
    AppLocalizations l10n,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(snapshot.error.toString(), textAlign: TextAlign.center),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person_outline,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  profile?['full_name'] as String? ?? 'MediConnect user',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(_roleLabel(role, l10n)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _NotificationsCard(
          notifications: snapshot.data?.notifications ?? const [],
          onMarkAllRead: _markNotificationsRead,
          l10n: l10n,
        ),
        const SizedBox(height: 16),
        _ProfileTile(
          icon: Icons.phone_outlined,
          label: l10n.phone,
          value: profile?['phone'] as String?,
        ),
        _ProfileTile(
          icon: Icons.mail_outline,
          label: l10n.email,
          value: profile?['email'] as String?,
        ),
        _ProfileTile(
          icon: Icons.language_outlined,
          label: l10n.language,
          value: profile?['preferred_language'] as String?,
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.language,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'en',
                      label: Text(l10n.languageEnglish),
                    ),
                    ButtonSegment(
                      value: 'ur',
                      label: Text(l10n.languageUrdu),
                    ),
                  ],
                  selected: {
                    appLocaleController.value?.languageCode ??
                        profile?['preferred_language'] as String? ??
                        'en',
                  },
                  onSelectionChanged: (value) => _setLanguage(value.first),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.profileSafetyNote,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout),
          label: Text(l10n.signOut),
        ),
      ],
    );
  }
}

class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard({
    required this.notifications,
    required this.onMarkAllRead,
    required this.l10n,
  });

  final List<AppNotification> notifications;
  final VoidCallback onMarkAllRead;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((item) => !item.isRead).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.notifications,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (unreadCount > 0)
                  TextButton(
                    onPressed: onMarkAllRead,
                    child: Text(l10n.markRead),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (notifications.isEmpty)
              Text(l10n.notificationsEmpty)
            else
              ...notifications.map(
                (notification) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      notification.isRead
                          ? Icons.notifications_none
                          : Icons.notifications_active_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(notification.title),
                    subtitle: Text(notification.body),
                    trailing: notification.isRead
                        ? null
                        : const Icon(Icons.circle, size: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(
          value == null || value!.trim().isEmpty
              ? AppLocalizations.of(context)!.notProvided
              : value!,
        ),
      ),
    );
  }
}

String _roleLabel(UserRole role, AppLocalizations l10n) {
  return switch (role) {
    UserRole.healthWorker => l10n.workerAccount,
    UserRole.admin => l10n.adminAccount,
    UserRole.patient => l10n.patientAccount,
  };
}

class _AccountData {
  const _AccountData({
    required this.profile,
    required this.notifications,
  });

  final Map<String, dynamic>? profile;
  final List<AppNotification> notifications;
}
