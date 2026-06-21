import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mediconnect/l10n/app_localizations.dart';

import '../../common/widgets/app_state_widgets.dart';
import '../../models/service_category.dart';
import '../../models/service_order.dart';
import '../../models/user_role.dart';
import '../../services/order_repository.dart';
import '../../services/service_request_repository.dart';
import '../navigation/role_bottom_navigation.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  late final Future<List<ServiceCategory>> _categoriesFuture;
  late Future<_PatientDashboardSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ServiceRequestRepository().fetchCategories();
    _summaryFuture = _loadSummary();
  }

  Future<_PatientDashboardSummary> _loadSummary() async {
    final repository = OrderRepository();
    final activeOrders = await repository.fetchActiveOrders();
    final history = await repository.fetchOrderHistory();

    return _PatientDashboardSummary(
      activeOrder: activeOrders.isEmpty ? null : activeOrders.first,
      recentOrder: history.isEmpty ? null : history.first,
    );
  }

  void _refreshSummary() {
    setState(() {
      _summaryFuture = _loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      bottomNavigationBar: const RoleBottomNavigation(
        role: UserRole.patient,
        currentItem: RoleNavItem.home,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.home_repair_service_outlined,
                  color: colorScheme.onPrimaryContainer,
                  size: 32,
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.patientDashboardTitle,
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.patientDashboardSubtitle,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DashboardAction(
                  icon: Icons.assignment_outlined,
                  label: l10n.activeOrders,
                  onTap: () => context.push('/orders/active'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DashboardAction(
                  icon: Icons.history_outlined,
                  label: l10n.history,
                  onTap: () => context.push('/orders/history'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<_PatientDashboardSummary>(
            future: _summaryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return AppLoadingState(
                  message: l10n.currentService,
                  compact: true,
                );
              }

              if (snapshot.hasError) {
                return AppErrorState(
                  message: snapshot.error.toString(),
                  retryLabel: l10n.retry,
                  onRetry: _refreshSummary,
                  compact: true,
                );
              }

              final summary = snapshot.data!;
              return Column(
                children: [
                  _PatientOrderSummaryCard(
                    title: l10n.currentService,
                    emptyTitle: l10n.noCurrentService,
                    emptySubtitle: l10n.noCurrentServiceSubtitle,
                    order: summary.activeOrder,
                    icon: Icons.local_activity_outlined,
                    onTap: () => context.push('/orders/active'),
                  ),
                  const SizedBox(height: 12),
                  _PatientOrderSummaryCard(
                    title: l10n.latestService,
                    emptyTitle: l10n.noServiceHistoryYet,
                    emptySubtitle: l10n.noServiceHistorySubtitle,
                    order: summary.recentOrder,
                    icon: Icons.history_outlined,
                    onTap: () => context.push('/orders/history'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: colorScheme.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.emergencySafetyCopy,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.services,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.servicesDashboardSubtitle,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<ServiceCategory>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return AppLoadingState(
                  message: l10n.services,
                  compact: true,
                );
              }

              if (snapshot.hasError) {
                return AppErrorState(
                  message: snapshot.error.toString(),
                  retryLabel: l10n.retry,
                  compact: true,
                );
              }

              final services = snapshot.data ?? [];
              if (services.isEmpty) {
                return AppEmptyState(
                  icon: Icons.local_hospital_outlined,
                  title: l10n.noServices,
                  subtitle: l10n.servicesDashboardSubtitle,
                  compact: true,
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (context, index) {
                  final service = services[index];
                  return _ServiceTile(
                    service: service,
                    icon: _iconForService(service.name),
                    onTap: () => context.go(
                      '/services/request',
                      extra: service,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PatientDashboardSummary {
  const _PatientDashboardSummary({
    required this.activeOrder,
    required this.recentOrder,
  });

  final ServiceOrder? activeOrder;
  final ServiceOrder? recentOrder;
}

class _DashboardAction extends StatelessWidget {
  const _DashboardAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientOrderSummaryCard extends StatelessWidget {
  const _PatientOrderSummaryCard({
    required this.title,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.icon,
    required this.onTap,
    this.order,
  });

  final String title;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData icon;
  final VoidCallback onTap;
  final ServiceOrder? order;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final order = this.order;

    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: colorScheme.onSecondaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: order == null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emptyTitle,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            emptySubtitle,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: textTheme.labelLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Chip(label: Text(_labelize(order.status))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            order.categoryName,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${order.address}, ${order.city}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.icon,
    required this.onTap,
  });

  final ServiceCategory service;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: colorScheme.onPrimaryContainer),
              ),
              const Spacer(),
              Text(
                service.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
              ),
              if (service.description != null) ...[
                const SizedBox(height: 6),
                Text(
                  service.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _labelize(String value) {
  return value
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

IconData _iconForService(String serviceName) {
  final normalized = serviceName.toLowerCase();

  if (normalized.contains('blood')) {
    return Icons.bloodtype_outlined;
  }
  if (normalized.contains('injection')) {
    return Icons.vaccines_outlined;
  }
  if (normalized.contains('drip')) {
    return Icons.water_drop_outlined;
  }
  if (normalized.contains('wound') || normalized.contains('bandage')) {
    return Icons.healing_outlined;
  }
  if (normalized.contains('stitches')) {
    return Icons.medical_information_outlined;
  }
  if (normalized.contains('checkup')) {
    return Icons.monitor_heart_outlined;
  }

  return Icons.local_hospital_outlined;
}
