import 'package:flutter/material.dart';
import 'package:mediconnect/l10n/app_localizations.dart';

import '../../common/widgets/app_state_widgets.dart';
import '../../models/user_role.dart';
import '../../models/service_order.dart';
import '../../services/order_repository.dart';
import '../../services/profile_repository.dart';
import '../navigation/role_bottom_navigation.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _repository = OrderRepository();
  final _profileRepository = ProfileRepository();
  late Future<List<ServiceOrder>> _ordersFuture;
  late Future<UserRole?> _roleFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _repository.fetchOrderHistory();
    _roleFuture = _profileRepository.fetchCurrentRole();
  }

  void _refresh() {
    setState(() {
      _ordersFuture = _repository.fetchOrderHistory();
    });
  }

  Future<void> _leaveReview(ServiceOrder order) async {
    final result = await showDialog<_ReviewResult>(
      context: context,
      builder: (context) => const _ReviewDialog(),
    );

    if (result == null) {
      return;
    }

    try {
      await _repository.submitReview(
        order: order,
        rating: result.rating,
        reviewText: result.text,
      );
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reviewSubmitted)),
      );
      _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _reportIssue(ServiceOrder order) async {
    final result = await showDialog<_DisputeResult>(
      context: context,
      builder: (context) => const _DisputeDialog(),
    );

    if (result == null) {
      return;
    }

    try {
      await _repository.reportDispute(
        order: order,
        reason: result.reason,
        details: result.details,
      );
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.issueReported)),
      );
      _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.serviceHistory)),
      bottomNavigationBar: FutureBuilder<UserRole?>(
        future: _roleFuture,
        builder: (context, snapshot) {
          final role = snapshot.data;
          if (role == null) {
            return const SizedBox.shrink();
          }

          return RoleBottomNavigation(
            role: role,
            currentItem: role == UserRole.healthWorker
                ? RoleNavItem.active
                : RoleNavItem.orders,
          );
        },
      ),
      body: FutureBuilder<List<ServiceOrder>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AppLoadingState(
              message: AppLocalizations.of(context)!.serviceHistory,
            );
          }

          if (snapshot.hasError) {
            final l10n = AppLocalizations.of(context)!;
            return AppErrorState(
              message: snapshot.error.toString(),
              retryLabel: l10n.retry,
              onRetry: _refresh,
            );
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            final l10n = AppLocalizations.of(context)!;
            return AppEmptyState(
              icon: Icons.history_outlined,
              title: l10n.noServiceHistoryYet,
              subtitle: l10n.noServiceHistorySubtitle,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HistoryCard(
                    order: order,
                    currentUserId: _repository.currentUserId(),
                    onLeaveReview: () => _leaveReview(order),
                    onReportIssue: () => _reportIssue(order),
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

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.order,
    required this.currentUserId,
    required this.onLeaveReview,
    required this.onReportIssue,
  });

  final ServiceOrder order;
  final String? currentUserId;
  final VoidCallback onLeaveReview;
  final VoidCallback onReportIssue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final price = order.finalPricePkr ?? order.quotedPricePkr;
    final isPatient = currentUserId == order.patientUserId;
    final canReview = isPatient && order.status == 'completed';
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
            const SizedBox(height: 8),
            Text(l10n.patientLabel(order.patientName)),
            Text(l10n.workerLabel(order.workerName)),
            const SizedBox(height: 8),
            Text('${order.address}, ${order.city}'),
            const SizedBox(height: 8),
            Text(
              order.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text(
              'PKR $price',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if (order.medicalRecordNotes != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.serviceNotes,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.medicalRecordNotes!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                if (canReview) ...[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onLeaveReview,
                      icon: const Icon(Icons.star_outline),
                      label: Text(l10n.review, textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReportIssue,
                    icon: const Icon(Icons.report_problem_outlined),
                    label: Text(l10n.reportIssue, textAlign: TextAlign.center),
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

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog();

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _controller = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.leaveReview),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1')),
                  ButtonSegment(value: 2, label: Text('2')),
                  ButtonSegment(value: 3, label: Text('3')),
                  ButtonSegment(value: 4, label: Text('4')),
                  ButtonSegment(value: 5, label: Text('5')),
                ],
                selected: {_rating},
                onSelectionChanged: (value) {
                  setState(() => _rating = value.first);
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.reviewNotes,
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
          onPressed: () => Navigator.of(context).pop(
            _ReviewResult(
              rating: _rating,
              text: _controller.text.trim(),
            ),
          ),
          child: Text(l10n.submit),
        ),
      ],
    );
  }
}

class _DisputeDialog extends StatefulWidget {
  const _DisputeDialog();

  @override
  State<_DisputeDialog> createState() => _DisputeDialogState();
}

class _DisputeDialogState extends State<_DisputeDialog> {
  final _reasonController = TextEditingController();
  final _detailsController = TextEditingController();
  String? _reasonErrorText;

  @override
  void dispose() {
    _reasonController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reasonController.text.trim();
    if (disputeReasonError(reason) != null) {
      setState(() {
        _reasonErrorText = AppLocalizations.of(context)!.required;
      });
      return;
    }
    Navigator.of(context).pop(
      _DisputeResult(
        reason: reason,
        details: _detailsController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.reportIssueTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _reasonController,
              onChanged: (_) {
                if (_reasonErrorText != null) {
                  setState(() => _reasonErrorText = null);
                }
              },
              decoration: InputDecoration(
                labelText: l10n.reason,
                errorText: _reasonErrorText,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.details,
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
          onPressed: _submit,
          child: Text(l10n.submit),
        ),
      ],
    );
  }
}

class _ReviewResult {
  const _ReviewResult({
    required this.rating,
    required this.text,
  });

  final int rating;
  final String text;
}

class _DisputeResult {
  const _DisputeResult({
    required this.reason,
    required this.details,
  });

  final String reason;
  final String details;
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
