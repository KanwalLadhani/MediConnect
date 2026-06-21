import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mediconnect/l10n/app_localizations.dart';

import '../../common/widgets/app_state_widgets.dart';
import '../../models/available_worker.dart';
import '../../models/service_request_result.dart';
import '../../services/service_request_repository.dart';

class AvailableWorkersScreen extends StatefulWidget {
  const AvailableWorkersScreen({
    required this.request,
    super.key,
  });

  final ServiceRequestResult request;

  @override
  State<AvailableWorkersScreen> createState() => _AvailableWorkersScreenState();
}

class _AvailableWorkersScreenState extends State<AvailableWorkersScreen> {
  final _repository = ServiceRequestRepository();
  String? _hiringWorkerId;
  String? _sentOfferId;
  AvailableWorker? _selectedWorker;

  Future<void> _hireWorker(AvailableWorker worker) async {
    if (_sentOfferId != null) {
      return;
    }

    setState(() => _hiringWorkerId = worker.id);

    try {
      final offerId = await _repository.hireWorker(
        request: widget.request,
        worker: worker,
      );

      if (!mounted) {
        return;
      }

      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _sentOfferId = offerId;
        _selectedWorker = worker;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.requestSentSnack(offerId))),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _hiringWorkerId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workers = widget.request.workers;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.availableWorkers)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.request.category.name,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${widget.request.city} - ${widget.request.address}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.verified_user_outlined,
                        label:
                            '${workers.length} ${workers.length == 1 ? l10n.verifiedMatch : l10n.verifiedMatches}',
                      ),
                      _InfoChip(
                        icon: Icons.payments_outlined,
                        label: l10n.payWorkerDirectly,
                      ),
                      if (widget.request.latitude != null &&
                          widget.request.longitude != null)
                        const _InfoChip(
                          icon: Icons.my_location_outlined,
                          label: 'GPS distance matching',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_sentOfferId != null && _selectedWorker != null) ...[
              _RequestSentCard(worker: _selectedWorker!, l10n: l10n),
              const SizedBox(height: 16),
            ],
            if (workers.isEmpty)
              AppEmptyState(
                icon: Icons.person_search_outlined,
                title: l10n.noWorkersAvailable,
                subtitle: l10n.noWorkersSubtitle,
                compact: true,
              )
            else
              ...workers.map(
                (worker) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _WorkerCard(
                    worker: worker,
                    l10n: l10n,
                    isHiring: _hiringWorkerId == worker.id,
                    isDisabled: _sentOfferId != null,
                    onHire: () => _hireWorker(worker),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  const _WorkerCard({
    required this.worker,
    required this.l10n,
    required this.isHiring,
    required this.isDisabled,
    required this.onHire,
  });

  final AvailableWorker worker;
  final AppLocalizations l10n;
  final bool isHiring;
  final bool isDisabled;
  final VoidCallback onHire;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.medical_services_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${worker.workerType} - ${worker.serviceArea ?? worker.city}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'PKR ${worker.pricePkr}',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    size: 16,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.approvedByMediConnect,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.star_outline,
                  label:
                      '${worker.rating.toStringAsFixed(1)} (${worker.totalReviews})',
                ),
                _InfoChip(
                  icon: Icons.near_me_outlined,
                  label: _distanceLabel(worker, l10n),
                ),
                _InfoChip(
                  icon: Icons.timer_outlined,
                  label: _etaLabel(worker, l10n),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isHiring || isDisabled ? null : onHire,
              icon: isHiring
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(
                isHiring
                    ? l10n.sending
                    : isDisabled
                        ? l10n.requestAlreadySent
                        : l10n.sendRequestToWorker,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _distanceLabel(AvailableWorker worker, AppLocalizations l10n) {
  final distanceKm = worker.distanceKm;
  if (distanceKm == null) {
    return l10n.nearby;
  }

  if (distanceKm < 1) {
    return '${(distanceKm * 1000).round()} m away';
  }

  return '${distanceKm.toStringAsFixed(1)} km away';
}

String _etaLabel(AvailableWorker worker, AppLocalizations l10n) {
  final etaMinutes = worker.etaMinutes;
  if (etaMinutes == null) {
    return l10n.etaShort;
  }

  return 'ETA $etaMinutes min';
}

class _RequestSentCard extends StatelessWidget {
  const _RequestSentCard({
    required this.worker,
    required this.l10n,
  });

  final AvailableWorker worker;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.requestSentToWorker(worker.name),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.requestSentDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => context.go('/orders/active'),
                icon: const Icon(Icons.assignment_outlined),
                label: Text(l10n.openActiveOrders, textAlign: TextAlign.center),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/dashboard/patient'),
                icon: const Icon(Icons.home_outlined),
                label: Text(l10n.backHome, textAlign: TextAlign.center),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      backgroundColor: colorScheme.surface,
      side: BorderSide(color: colorScheme.outlineVariant),
      visualDensity: VisualDensity.compact,
    );
  }
}
