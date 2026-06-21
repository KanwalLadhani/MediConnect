import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mediconnect/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common/widgets/app_state_widgets.dart';
import '../../models/service_order.dart';
import '../../models/user_role.dart';
import '../../models/worker_location.dart';
import '../../services/order_repository.dart';
import '../../services/supabase_status.dart';
import '../navigation/role_bottom_navigation.dart';

class ActiveOrdersScreen extends StatefulWidget {
  const ActiveOrdersScreen({
    super.key,
    this.navigationRole,
    this.navigationItem = RoleNavItem.orders,
  });

  final UserRole? navigationRole;
  final RoleNavItem navigationItem;

  @override
  State<ActiveOrdersScreen> createState() => _ActiveOrdersScreenState();
}

class _ActiveOrdersScreenState extends State<ActiveOrdersScreen> {
  final _repository = OrderRepository();
  late Future<List<ServiceOrder>> _ordersFuture;
  Timer? _refreshTimer;
  RealtimeChannel? _ordersChannel;
  RealtimeChannel? _locationsChannel;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _repository.fetchActiveOrders();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) {
          _refresh();
        }
      },
    );
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    final ordersChannel = _ordersChannel;
    final locationsChannel = _locationsChannel;
    if (SupabaseStatus.isConfigured) {
      if (ordersChannel != null) {
        SupabaseStatus.client.removeChannel(ordersChannel);
      }
      if (locationsChannel != null) {
        SupabaseStatus.client.removeChannel(locationsChannel);
      }
    }
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _ordersFuture = _repository.fetchActiveOrders();
    });
  }

  void _subscribeToRealtime() {
    if (!SupabaseStatus.isConfigured) {
      return;
    }

    _ordersChannel = SupabaseStatus.client
        .channel('active_orders_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) => _refresh(),
        )
        .subscribe();

    _locationsChannel = SupabaseStatus.client
        .channel('worker_locations_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'worker_locations',
          callback: (_) => _refresh(),
        )
        .subscribe();
  }

  Future<void> _callPhone(String? phone) async {
    final l10n = AppLocalizations.of(context)!;
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.phoneUnavailable)),
      );
      return;
    }

    final normalizedPhone = phone.replaceAll(' ', '');
    final phoneUri = Uri(scheme: 'tel', path: normalizedPhone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
      return;
    }

    await Clipboard.setData(ClipboardData(text: phone));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.callingUnavailableCopied(phone))),
    );
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

  Future<void> _cancelOrder(ServiceOrder order) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelOrderQuestion),
        content: Text(l10n.cancelOrderWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.keepOrder),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.cancelOrder),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _repository.cancelOrder(order);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.orderCancelled)),
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
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.activeOrders)),
      bottomNavigationBar: widget.navigationRole == null
          ? null
          : RoleBottomNavigation(
              role: widget.navigationRole!,
              currentItem: widget.navigationItem,
            ),
      body: FutureBuilder<List<ServiceOrder>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AppLoadingState(
              message: AppLocalizations.of(context)!.activeOrders,
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
              icon: Icons.assignment_outlined,
              title: l10n.noActiveOrders,
              subtitle: l10n.noActiveOrdersSubtitle,
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
                  child: _OrderCard(
                    order: order,
                    currentUserId: _repository.currentUserId(),
                    onCallPhone: () => _callPhone(
                      _repository.currentUserId() == order.patientUserId
                          ? order.workerPhone
                          : order.patientPhone,
                    ),
                    onOpenChat: () => context.push(
                      '/orders/${order.id}/chat',
                      extra: order,
                    ),
                    onReportIssue: () => _reportIssue(order),
                    onCancelOrder: () => _cancelOrder(order),
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.currentUserId,
    required this.onCallPhone,
    required this.onOpenChat,
    required this.onReportIssue,
    required this.onCancelOrder,
  });

  final ServiceOrder order;
  final String? currentUserId;
  final VoidCallback onCallPhone;
  final VoidCallback onOpenChat;
  final VoidCallback onReportIssue;
  final VoidCallback onCancelOrder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isPatient = currentUserId == order.patientUserId;
    final canCancel =
        isPatient && ['accepted', 'worker_on_way'].contains(order.status);
    final counterpartName = isPatient ? order.workerName : order.patientName;

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text('${order.address}, ${order.city}')),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              order.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            _StatusTracker(status: order.status),
            const SizedBox(height: 12),
            _LocationStatus(orderId: order.id),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.activeOrderEmergencyCopy(counterpartName),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCallPhone,
                    icon: const Icon(Icons.call_outlined),
                    label: Text(l10n.call, textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onOpenChat,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text(l10n.chat, textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onReportIssue,
                icon: const Icon(Icons.report_problem_outlined),
                label: Text(l10n.reportIssue, textAlign: TextAlign.center),
              ),
            ),
            if (canCancel) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCancelOrder,
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(l10n.cancelOrder, textAlign: TextAlign.center),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusTracker extends StatelessWidget {
  const _StatusTracker({required this.status});

  final String status;

  static const _steps = ['accepted', 'worker_on_way', 'started', 'completed'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeIndex = _steps.indexOf(status).clamp(0, _steps.length - 1);

    return Row(
      children: [
        for (var index = 0; index < _steps.length; index++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: index <= activeIndex
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    index <= activeIndex ? Icons.check : Icons.circle_outlined,
                    size: 14,
                    color: index <= activeIndex
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _shortStatus(context, _steps[index]),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          if (index != _steps.length - 1)
            Container(
              width: 18,
              height: 2,
              color: index < activeIndex
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
        ],
      ],
    );
  }
}

class _LocationStatus extends StatelessWidget {
  const _LocationStatus({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WorkerLocation?>(
      future: OrderRepository().fetchLatestWorkerLocation(orderId),
      builder: (context, snapshot) {
        final location = snapshot.data;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.near_me_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locationText(
                        context,
                        snapshot.connectionState,
                        location,
                      ),
                    ),
                  ),
                ],
              ),
              if (location != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomPaint(
                      painter: _LocationMapPainter(
                        colorScheme: Theme.of(context).colorScheme,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Align(
                          alignment: AlignmentDirectional.bottomStart,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.updatedAtTime(
                                  _formatTime(location.createdAt),
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _LocationMapPainter extends CustomPainter {
  const _LocationMapPainter({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = colorScheme.surfaceContainerHighest.withOpacity(0.72);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withOpacity(0.52)
      ..strokeWidth = 1;
    for (var x = 24.0; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x - 28, size.height), gridPaint);
    }
    for (var y = 24.0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 18), gridPaint);
    }

    final routePaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final route = Path()
      ..moveTo(size.width * 0.18, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.42,
        size.width * 0.68,
        size.height * 0.54,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.60,
        size.width * 0.86,
        size.height * 0.30,
      );
    canvas.drawPath(route, routePaint);

    _drawPin(
      canvas,
      Offset(size.width * 0.18, size.height * 0.72),
      colorScheme.secondary,
    );
    _drawPin(
      canvas,
      Offset(size.width * 0.86, size.height * 0.30),
      colorScheme.primary,
    );
  }

  void _drawPin(Canvas canvas, Offset center, Color color) {
    final pinPaint = Paint()..color = color;
    final borderPaint = Paint()
      ..color = colorScheme.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, 9, pinPaint);
    canvas.drawCircle(center, 9, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _LocationMapPainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme;
  }
}

String _locationText(
  BuildContext context,
  ConnectionState connectionState,
  WorkerLocation? location,
) {
  final l10n = AppLocalizations.of(context)!;
  if (connectionState == ConnectionState.waiting) {
    return l10n.checkingWorkerLocation;
  }

  if (location == null) {
    return l10n.locationUpdatesPending;
  }

  return l10n.latestLocation(
    location.latitude.toStringAsFixed(5),
    location.longitude.toStringAsFixed(5),
    _formatTime(location.createdAt),
  );
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
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

String _shortStatus(BuildContext context, String value) {
  final l10n = AppLocalizations.of(context)!;
  return switch (value) {
    'worker_on_way' => l10n.onWay,
    _ => _labelize(value),
  };
}
