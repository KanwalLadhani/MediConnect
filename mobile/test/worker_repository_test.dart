import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect/services/order_status_transition.dart';
import 'package:mediconnect/services/worker_repository.dart';

void main() {
  group('workerWalletAcceptanceBlocker', () {
    test('allows active wallets with zero or positive balance', () {
      expect(
        workerWalletAcceptanceBlocker(status: 'active', balancePkr: 0),
        isNull,
      );
      expect(
        workerWalletAcceptanceBlocker(status: 'active', balancePkr: 2500),
        isNull,
      );
    });

    test('blocks frozen or non-active wallets', () {
      expect(
        workerWalletAcceptanceBlocker(status: 'frozen', balancePkr: 5000),
        'Wallet is frozen. Contact admin before accepting jobs.',
      );
      expect(
        workerWalletAcceptanceBlocker(status: 'suspended', balancePkr: 5000),
        'Wallet is frozen. Contact admin before accepting jobs.',
      );
    });

    test('blocks active wallets with negative balance', () {
      expect(
        workerWalletAcceptanceBlocker(status: 'active', balancePkr: -1),
        'Top up wallet before accepting new jobs.',
      );
    });
  });

  group('workerCompletionPriceError', () {
    test('allows positive final charges', () {
      expect(workerCompletionPriceError(1), isNull);
      expect(workerCompletionPriceError(1200), isNull);
    });

    test('rejects missing, zero, and negative final charges', () {
      expect(
        workerCompletionPriceError(null),
        WorkerCompletionPriceError.invalidFinalPrice,
      );
      expect(
        workerCompletionPriceError(0),
        WorkerCompletionPriceError.invalidFinalPrice,
      );
      expect(
        workerCompletionPriceError(-100),
        WorkerCompletionPriceError.invalidFinalPrice,
      );
    });
  });

  group('estimatedPlatformCommissionPkr', () {
    test('uses 10 percent commission with ceiling rounding', () {
      expect(estimatedPlatformCommissionPkr(1000), 100);
      expect(estimatedPlatformCommissionPkr(1100), 110);
      expect(estimatedPlatformCommissionPkr(1001), 101);
      expect(estimatedPlatformCommissionPkr(1), 1);
    });

    test('rejects invalid final charges', () {
      expect(() => estimatedPlatformCommissionPkr(0), throwsArgumentError);
      expect(() => estimatedPlatformCommissionPkr(-1), throwsArgumentError);
    });
  });

  group('worker order status transitions', () {
    test('allows worker progress statuses in sequence', () {
      final onWay = buildNonCompletionOrderStatusTransition(
        currentStatus: 'accepted',
        targetStatus: 'worker_on_way',
        eventSource: workerOrderStatusEventSource,
      );
      expect(onWay.targetStatus, 'worker_on_way');
      expect(onWay.eventType, 'worker_on_way');
      expect(onWay.timestampColumn, isNull);
      expect(
        onWay.metadata,
        {
          'source': workerOrderStatusEventSource,
          'previous_status': 'accepted',
        },
      );

      final started = buildNonCompletionOrderStatusTransition(
        currentStatus: 'worker_on_way',
        targetStatus: 'started',
        eventSource: workerOrderStatusEventSource,
      );
      expect(started.targetStatus, 'started');
      expect(started.eventType, 'started');
      expect(started.timestampColumn, 'started_at');
      expect(
        started.metadata,
        {
          'source': workerOrderStatusEventSource,
          'previous_status': 'worker_on_way',
        },
      );
    });

    test('rejects invalid or completion transitions before network calls', () {
      expect(
        nonCompletionOrderStatusTransitionError(
          currentStatus: 'accepted',
          targetStatus: 'started',
        ),
        OrderStatusTransitionError.invalidTransition,
      );
      expect(
        nonCompletionOrderStatusTransitionError(
          currentStatus: 'started',
          targetStatus: 'completed',
        ),
        OrderStatusTransitionError.completionRequiresRpc,
      );
      expect(
        nonCompletionOrderStatusTransitionError(
          currentStatus: 'started',
          targetStatus: 'worker_on_way',
        ),
        OrderStatusTransitionError.invalidTransition,
      );
      expect(
        nonCompletionOrderStatusTransitionError(
          currentStatus: 'completed',
          targetStatus: 'cancelled',
        ),
        OrderStatusTransitionError.invalidTransition,
      );
    });
  });
}
