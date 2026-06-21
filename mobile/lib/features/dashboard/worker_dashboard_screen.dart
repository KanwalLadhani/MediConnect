import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mediconnect/l10n/app_localizations.dart';

import '../../common/widgets/app_state_widgets.dart';
import '../../models/user_role.dart';
import '../../models/worker_dashboard_data.dart';
import '../../models/worker_order.dart';
import '../../models/worker_review.dart';
import '../../services/worker_repository.dart';
import '../navigation/role_bottom_navigation.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  final _repository = WorkerRepository();
  late Future<WorkerDashboardData> _dashboardFuture;
  bool _isUpdatingAvailability = false;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _repository.fetchDashboard();
  }

  void _refresh() {
    setState(() {
      _dashboardFuture = _repository.fetchDashboard();
    });
  }

  Future<void> _toggleAvailability(
    WorkerDashboardData data,
    bool isAvailable,
  ) async {
    setState(() => _isUpdatingAvailability = true);

    try {
      await _repository.updateAvailability(
        workerId: data.workerId,
        isAvailable: isAvailable,
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
        setState(() => _isUpdatingAvailability = false);
      }
    }
  }

  Future<void> _advanceOrder(WorkerOrder order) async {
    final nextStatus = switch (order.status) {
      'accepted' => 'worker_on_way',
      'worker_on_way' => 'started',
      'started' => 'completed',
      _ => 'accepted',
    };

    _CompletionResult? completion;
    if (nextStatus == 'completed') {
      completion = await _askCompletion(order);
      if (completion == null) {
        return;
      }
    }

    await _repository.updateOrderStatus(
      order: order,
      status: nextStatus,
      finalPricePkr: completion?.finalPricePkr,
      completionNotes: completion?.notes,
    );
    _refresh();
  }

  Future<void> _shareLocation(WorkerOrder order) async {
    try {
      await _repository.shareCurrentLocation(order);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.locationShared),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<_CompletionResult?> _askCompletion(WorkerOrder order) async {
    final priceController = TextEditingController(
      text: order.quotedPricePkr.toString(),
    );
    final notesController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    String? priceErrorText;

    final value = await showDialog<_CompletionResult>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.completeOrder),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                        if (priceErrorText != null) {
                          setDialogState(() => priceErrorText = null);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: l10n.finalChargePkr,
                        errorText: priceErrorText,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: l10n.serviceNotes,
                        hintText: l10n.completionServiceNotesHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    final price = int.tryParse(priceController.text.trim());
                    if (workerCompletionPriceError(price) != null) {
                      setDialogState(() {
                        priceErrorText = l10n.enterValidAmount;
                      });
                      return;
                    }

                    Navigator.of(context).pop(
                      _CompletionResult(
                        finalPricePkr: price!,
                        notes: notesController.text.trim(),
                      ),
                    );
                  },
                  child: Text(l10n.complete),
                ),
              ],
            );
          },
        );
      },
    );

    priceController.dispose();
    notesController.dispose();
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.workerDashboard)),
      bottomNavigationBar: const RoleBottomNavigation(
        role: UserRole.healthWorker,
        currentItem: RoleNavItem.home,
      ),
      body: FutureBuilder<WorkerDashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AppLoadingState(message: l10n.workerDashboard);
          }

          if (snapshot.hasError) {
            return AppErrorState(
              message: snapshot.error.toString(),
              retryLabel: l10n.retry,
              onRetry: _refresh,
            );
          }

          final data = snapshot.data!;
          final stats = [
            (l10n.statWallet, 'PKR ${data.walletBalancePkr}'),
            (l10n.statToday, 'PKR ${data.todayEarningsPkr}'),
            (l10n.statEarnings, 'PKR ${data.totalEarningsPkr}'),
            (l10n.statRequests, data.pendingRequestCount.toString()),
            (l10n.statTotalOrders, data.totalCompletedOrders.toString()),
            (l10n.statRating, data.rating.toStringAsFixed(1)),
          ];

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (!data.isApproved) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.verified_user_outlined),
                      title: Text(
                        l10n.verificationStatusValue(
                          _labelize(data.verificationStatus),
                        ),
                      ),
                      subtitle: Text(l10n.workerApprovalRequired),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Card(
                  child: SwitchListTile(
                    value: data.isAvailable,
                    onChanged: data.isApproved && !_isUpdatingAvailability
                        ? (value) => _toggleAvailability(data, value)
                        : null,
                    title: Text(l10n.availableForRequests),
                    subtitle: Text(
                      '${l10n.availableForRequestsSubtitle} GPS location is shared while available.',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stats.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, index) {
                    final (label, value) = stats[index];
                    return _StatCard(label: label, value: value);
                  },
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: data.isApproved
                      ? () => context.push('/worker/requests').then(
                            (_) => _refresh(),
                          )
                      : null,
                  icon: const Icon(Icons.inbox_outlined),
                  label: Text(
                    data.pendingRequestCount == 0
                        ? l10n.viewIncomingRequests
                        : l10n.viewRequestCount(data.pendingRequestCount),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push('/worker/wallet').then(
                        (_) => _refresh(),
                      ),
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: Text(l10n.openWallet, textAlign: TextAlign.center),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push('/orders/history').then(
                        (_) => _refresh(),
                      ),
                  icon: const Icon(Icons.history_outlined),
                  label:
                      Text(l10n.viewOrderHistory, textAlign: TextAlign.center),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.recentReviews,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                if (data.recentReviews.isEmpty)
                  AppEmptyState(
                    icon: Icons.star_outline,
                    title: l10n.recentReviews,
                    subtitle: l10n.noWorkerReviews,
                    compact: true,
                  )
                else
                  ...data.recentReviews.map(
                    (review) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReviewCard(review: review),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  l10n.activeOrders,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                if (data.activeOrders.isEmpty)
                  AppEmptyState(
                    icon: Icons.assignment_outlined,
                    title: l10n.noActiveOrders,
                    subtitle: l10n.noActiveOrdersNow,
                    compact: true,
                  )
                else
                  ...data.activeOrders.map(
                    (order) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ActiveOrderCard(
                        order: order,
                        onAdvance: () => _advanceOrder(order),
                        onShareLocation: () => _shareLocation(order),
                        l10n: l10n,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CompletionResult {
  const _CompletionResult({
    required this.finalPricePkr,
    required this.notes,
  });

  final int finalPricePkr;
  final String notes;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            const Spacer(),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final WorkerReview review;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reviewText = review.reviewText?.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: colorScheme.tertiary),
                const SizedBox(width: 6),
                Text(
                  '${review.rating}/5',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                Text(
                  _shortDate(review.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review.patientName,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if (reviewText != null && reviewText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(reviewText),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({
    required this.order,
    required this.onAdvance,
    required this.onShareLocation,
    required this.l10n,
  });

  final WorkerOrder order;
  final VoidCallback onAdvance;
  final VoidCallback onShareLocation;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final actionLabel = switch (order.status) {
      'accepted' => l10n.markOnTheWay,
      'worker_on_way' => l10n.startService,
      'started' => l10n.completeService,
      _ => l10n.update,
    };

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
                    order.categoryName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Chip(label: Text(_labelize(order.status))),
              ],
            ),
            const SizedBox(height: 6),
            Text(order.patientName),
            const SizedBox(height: 4),
            Text('${order.address}, ${order.city}'),
            const SizedBox(height: 10),
            Text(
              order.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdvance,
              icon: const Icon(Icons.arrow_forward),
              label: Text(actionLabel, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onShareLocation,
              icon: const Icon(Icons.near_me_outlined),
              label: Text(l10n.shareLocation, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push(
                '/orders/${order.id}/chat',
                extra: order.toServiceOrder(),
              ),
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(l10n.openChat, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}

String _shortDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day}/${local.month}/${local.year}';
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
