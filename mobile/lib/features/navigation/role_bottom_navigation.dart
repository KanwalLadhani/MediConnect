import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mediconnect/l10n/app_localizations.dart';

import '../../models/user_role.dart';

enum RoleNavItem {
  home,
  services,
  orders,
  chat,
  requests,
  active,
  wallet,
  profile,
}

class RoleBottomNavigation extends StatelessWidget {
  const RoleBottomNavigation({
    super.key,
    required this.role,
    required this.currentItem,
  });

  final UserRole role;
  final RoleNavItem currentItem;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = role == UserRole.healthWorker
        ? _workerItems(l10n)
        : _patientItems(l10n);

    return NavigationBar(
      selectedIndex: items.indexWhere((item) => item.item == currentItem),
      onDestinationSelected: (index) {
        final selected = items[index];
        if (selected.item == currentItem) {
          return;
        }
        context.go(selected.route);
      },
      destinations: [
        for (final item in items)
          NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: item.label,
          ),
      ],
    );
  }
}

List<_NavDestination> _patientItems(AppLocalizations l10n) => [
      _NavDestination(
        item: RoleNavItem.home,
        route: '/dashboard/patient',
        label: l10n.home,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
      ),
      _NavDestination(
        item: RoleNavItem.services,
        route: '/services',
        label: l10n.services,
        icon: Icons.medical_services_outlined,
        selectedIcon: Icons.medical_services,
      ),
      _NavDestination(
        item: RoleNavItem.orders,
        route: '/orders/active',
        label: l10n.orders,
        icon: Icons.assignment_outlined,
        selectedIcon: Icons.assignment,
      ),
      _NavDestination(
        item: RoleNavItem.chat,
        route: '/chats',
        label: l10n.chat,
        icon: Icons.chat_bubble_outline,
        selectedIcon: Icons.chat_bubble,
      ),
      _NavDestination(
        item: RoleNavItem.profile,
        route: '/profile',
        label: l10n.profile,
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
      ),
    ];

List<_NavDestination> _workerItems(AppLocalizations l10n) => [
      _NavDestination(
        item: RoleNavItem.home,
        route: '/dashboard/worker',
        label: l10n.home,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
      ),
      _NavDestination(
        item: RoleNavItem.requests,
        route: '/worker/requests',
        label: l10n.requests,
        icon: Icons.inbox_outlined,
        selectedIcon: Icons.inbox,
      ),
      _NavDestination(
        item: RoleNavItem.active,
        route: '/worker/active',
        label: l10n.active,
        icon: Icons.near_me_outlined,
        selectedIcon: Icons.near_me,
      ),
      _NavDestination(
        item: RoleNavItem.wallet,
        route: '/worker/wallet',
        label: l10n.wallet,
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet,
      ),
      _NavDestination(
        item: RoleNavItem.profile,
        route: '/profile',
        label: l10n.profile,
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
      ),
    ];

class _NavDestination {
  const _NavDestination({
    required this.item,
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final RoleNavItem item;
  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
