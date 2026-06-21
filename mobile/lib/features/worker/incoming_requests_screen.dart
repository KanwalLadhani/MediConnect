import 'package:flutter/material.dart';
import 'package:mediconnect/l10n/app_localizations.dart';

import '../../common/widgets/app_state_widgets.dart';
import '../../models/user_role.dart';
import '../../models/incoming_service_request.dart';
import '../../services/worker_repository.dart';
import '../navigation/role_bottom_navigation.dart';

class IncomingRequestsScreen extends StatefulWidget {
  const IncomingRequestsScreen({super.key});

  @override
  State<IncomingRequestsScreen> createState() => _IncomingRequestsScreenState();
}

class _IncomingRequestsScreenState extends State<IncomingRequestsScreen> {
  final _repository = WorkerRepository();
  late Future<List<IncomingServiceRequest>> _requestsFuture;
  String? _busyOfferId;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _repository.fetchIncomingRequests();
  }

  void _refresh() {
    setState(() {
      _requestsFuture = _repository.fetchIncomingRequests();
    });
  }

  Future<void> _accept(IncomingServiceRequest request) async {
    setState(() => _busyOfferId = request.offerId);

    try {
      final orderId = await _repository.acceptRequest(request);
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.orderAcceptedSnack(orderId))),
      );
      _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _busyOfferId = null);
      }
    }
  }

  Future<void> _decline(String offerId) async {
    setState(() => _busyOfferId = offerId);

    try {
      await _repository.declineRequest(offerId);
      _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _busyOfferId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.incomingRequests)),
      bottomNavigationBar: const RoleBottomNavigation(
        role: UserRole.healthWorker,
        currentItem: RoleNavItem.requests,
      ),
      body: FutureBuilder<List<IncomingServiceRequest>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AppLoadingState(message: l10n.incomingRequests);
          }

          if (snapshot.hasError) {
            return AppErrorState(
              message: snapshot.error.toString(),
              retryLabel: l10n.retry,
              onRetry: _refresh,
            );
          }

          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return AppEmptyState(
              icon: Icons.inbox_outlined,
              title: l10n.noIncomingRequests,
              subtitle: l10n.noIncomingRequestsSubtitle,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RequestCard(
                    request: request,
                    l10n: l10n,
                    isBusy: _busyOfferId == request.offerId,
                    onAccept: () => _accept(request),
                    onDecline: () => _decline(request.offerId),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.l10n,
    required this.isBusy,
    required this.onAccept,
    required this.onDecline,
  });

  final IncomingServiceRequest request;
  final AppLocalizations l10n;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.categoryName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(request.patientName),
                    ],
                  ),
                ),
                Text(
                  'PKR ${request.quotedPricePkr}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(request.description),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text('${request.address}, ${request.city}')),
              ],
            ),
            if (request.imagePath != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.image_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      request.imagePath!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onDecline,
                    icon: const Icon(Icons.close),
                    label: Text(l10n.decline, textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isBusy ? null : onAccept,
                    icon: isBusy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(l10n.accept, textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
