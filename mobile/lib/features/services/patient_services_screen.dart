import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mediconnect/l10n/app_localizations.dart';

import '../../common/widgets/app_state_widgets.dart';
import '../../models/service_category.dart';
import '../../models/user_role.dart';
import '../../services/service_request_repository.dart';
import '../navigation/role_bottom_navigation.dart';

class PatientServicesScreen extends StatefulWidget {
  const PatientServicesScreen({super.key});

  @override
  State<PatientServicesScreen> createState() => _PatientServicesScreenState();
}

class _PatientServicesScreenState extends State<PatientServicesScreen> {
  late Future<List<ServiceCategory>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ServiceRequestRepository().fetchCategories();
  }

  void _refresh() {
    setState(() {
      _categoriesFuture = ServiceRequestRepository().fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.services)),
      bottomNavigationBar: const RoleBottomNavigation(
        role: UserRole.patient,
        currentItem: RoleNavItem.services,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              l10n.chooseCare,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.servicesSubtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<ServiceCategory>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return AppLoadingState(
                    message: l10n.findingWorkers,
                    compact: true,
                  );
                }

                if (snapshot.hasError) {
                  return AppErrorState(
                    message: snapshot.error.toString(),
                    retryLabel: l10n.retry,
                    onRetry: _refresh,
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

                return Column(
                  children: [
                    for (final service in services)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: ListTile(
                            leading: Icon(_iconForService(service.name)),
                            title: Text(service.name),
                            subtitle: Text(
                              service.description ??
                                  l10n.verifiedDoorstepSupport,
                            ),
                            trailing: const Icon(Icons.arrow_forward),
                            onTap: () => context.go(
                              '/services/request',
                              extra: service,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
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
