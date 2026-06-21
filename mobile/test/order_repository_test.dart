import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect/services/order_status_transition.dart';
import 'package:mediconnect/services/order_repository.dart';

void main() {
  group('disputeReasonError', () {
    test('allows non-empty reasons after trimming', () {
      expect(disputeReasonError('Worker did not arrive'), isNull);
      expect(disputeReasonError('  Billing issue  '), isNull);
    });

    test('requires a reason for disputes', () {
      expect(disputeReasonError(null), DisputeReasonError.required);
      expect(disputeReasonError(''), DisputeReasonError.required);
      expect(disputeReasonError('   '), DisputeReasonError.required);
    });
  });

  group('reviewRatingError', () {
    test('allows ratings from 1 to 5', () {
      expect(reviewRatingError(1), isNull);
      expect(reviewRatingError(3), isNull);
      expect(reviewRatingError(5), isNull);
    });

    test('rejects ratings outside 1 to 5', () {
      expect(reviewRatingError(0), ReviewRatingError.outOfRange);
      expect(reviewRatingError(-1), ReviewRatingError.outOfRange);
      expect(reviewRatingError(6), ReviewRatingError.outOfRange);
    });
  });

  group('chatMessageBodyError', () {
    test('allows non-empty message bodies after trimming', () {
      expect(chatMessageBodyError('Hello'), isNull);
      expect(chatMessageBodyError('  Please call me  '), isNull);
    });

    test('requires message body text', () {
      expect(chatMessageBodyError(null), ChatMessageBodyError.required);
      expect(chatMessageBodyError(''), ChatMessageBodyError.required);
      expect(chatMessageBodyError('   '), ChatMessageBodyError.required);
    });
  });

  group('chatImageExtensionError', () {
    test('allows jpg, jpeg, and png extensions after normalization', () {
      expect(chatImageExtensionError('jpg'), isNull);
      expect(chatImageExtensionError('.JPEG'), isNull);
      expect(chatImageExtensionError(' png '), isNull);
      expect(normalizedChatImageExtension('.JPEG'), 'jpeg');
    });

    test('rejects missing and unsupported image extensions', () {
      expect(
        chatImageExtensionError(null),
        ChatImageExtensionError.unsupported,
      );
      expect(chatImageExtensionError(''), ChatImageExtensionError.unsupported);
      expect(
        chatImageExtensionError('gif'),
        ChatImageExtensionError.unsupported,
      );
      expect(
        chatImageExtensionError('pdf'),
        ChatImageExtensionError.unsupported,
      );
    });
  });

  group('patient order cancellation transitions', () {
    test('allows cancellation before service starts', () {
      final acceptedCancellation = buildNonCompletionOrderStatusTransition(
        currentStatus: 'accepted',
        targetStatus: 'cancelled',
        eventSource: patientActiveOrderEventSource,
      );
      expect(acceptedCancellation.targetStatus, 'cancelled');
      expect(acceptedCancellation.eventType, 'cancelled');
      expect(acceptedCancellation.timestampColumn, 'cancelled_at');
      expect(
        acceptedCancellation.metadata,
        {
          'source': patientActiveOrderEventSource,
          'previous_status': 'accepted',
        },
      );

      expect(
        nonCompletionOrderStatusTransitionError(
          currentStatus: 'worker_on_way',
          targetStatus: 'cancelled',
        ),
        isNull,
      );
    });

    test('rejects cancellation after service starts or terminal statuses', () {
      expect(
        nonCompletionOrderStatusTransitionError(
          currentStatus: 'started',
          targetStatus: 'cancelled',
        ),
        OrderStatusTransitionError.invalidTransition,
      );
      expect(
        nonCompletionOrderStatusTransitionError(
          currentStatus: 'cancelled',
          targetStatus: 'cancelled',
        ),
        OrderStatusTransitionError.unchangedStatus,
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
