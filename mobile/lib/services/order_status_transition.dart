import 'package:flutter/foundation.dart';

const workerOrderStatusEventSource = 'worker_dashboard';
const patientActiveOrderEventSource = 'mobile_active_order';

class OrderStatusTransitionPlan {
  const OrderStatusTransitionPlan({
    required this.targetStatus,
    required this.eventType,
    required this.metadata,
    this.timestampColumn,
  });

  final String targetStatus;
  final String eventType;
  final String? timestampColumn;
  final Map<String, dynamic> metadata;
}

@visibleForTesting
OrderStatusTransitionError? nonCompletionOrderStatusTransitionError({
  required String currentStatus,
  required String targetStatus,
}) {
  if (currentStatus == targetStatus) {
    return OrderStatusTransitionError.unchangedStatus;
  }

  if (targetStatus == 'completed') {
    return OrderStatusTransitionError.completionRequiresRpc;
  }

  final validPreviousStatuses = switch (targetStatus) {
    'worker_on_way' => const {'accepted'},
    'started' => const {'worker_on_way'},
    'cancelled' => const {'accepted', 'worker_on_way'},
    _ => const <String>{},
  };

  if (validPreviousStatuses.isEmpty) {
    return OrderStatusTransitionError.unsupportedTargetStatus;
  }

  if (!validPreviousStatuses.contains(currentStatus)) {
    return OrderStatusTransitionError.invalidTransition;
  }

  return null;
}

OrderStatusTransitionPlan buildNonCompletionOrderStatusTransition({
  required String currentStatus,
  required String targetStatus,
  required String eventSource,
}) {
  final error = nonCompletionOrderStatusTransitionError(
    currentStatus: currentStatus,
    targetStatus: targetStatus,
  );
  if (error != null) {
    throw StateError(orderStatusTransitionErrorMessage(error));
  }

  final timestampColumn = switch (targetStatus) {
    'started' => 'started_at',
    'cancelled' => 'cancelled_at',
    _ => null,
  };

  return OrderStatusTransitionPlan(
    targetStatus: targetStatus,
    eventType: targetStatus,
    timestampColumn: timestampColumn,
    metadata: nonCompletionOrderStatusEventMetadata(
      currentStatus: currentStatus,
      eventSource: eventSource,
    ),
  );
}

@visibleForTesting
Map<String, dynamic> nonCompletionOrderStatusEventMetadata({
  required String currentStatus,
  required String eventSource,
}) {
  return {
    'source': eventSource,
    'previous_status': currentStatus,
  };
}

String orderStatusTransitionErrorMessage(OrderStatusTransitionError error) {
  return switch (error) {
    OrderStatusTransitionError.unchangedStatus =>
      'Order already has this status.',
    OrderStatusTransitionError.completionRequiresRpc =>
      'Use the completion flow to complete orders.',
    OrderStatusTransitionError.unsupportedTargetStatus =>
      'Unsupported order status.',
    OrderStatusTransitionError.invalidTransition =>
      'Order cannot move to this status from its current status.',
  };
}

enum OrderStatusTransitionError {
  unchangedStatus,
  completionRequiresRpc,
  unsupportedTargetStatus,
  invalidTransition,
}
