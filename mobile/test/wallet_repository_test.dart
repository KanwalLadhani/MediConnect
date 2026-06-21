import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect/services/wallet_repository.dart';

void main() {
  group('walletTopUpAmountError', () {
    test('allows positive integer amounts', () {
      expect(walletTopUpAmountError('1'), isNull);
      expect(walletTopUpAmountError(' 2500 '), isNull);
      expect(parseWalletTopUpAmount(' 2500 '), 2500);
    });

    test('rejects missing, zero, negative, and non-numeric amounts', () {
      expect(
        walletTopUpAmountError(null),
        WalletTopUpValidationError.invalidAmount,
      );
      expect(
        walletTopUpAmountError(''),
        WalletTopUpValidationError.invalidAmount,
      );
      expect(
        walletTopUpAmountError('0'),
        WalletTopUpValidationError.invalidAmount,
      );
      expect(
        walletTopUpAmountError('-100'),
        WalletTopUpValidationError.invalidAmount,
      );
      expect(
        walletTopUpAmountError('abc'),
        WalletTopUpValidationError.invalidAmount,
      );
    });
  });

  group('walletTopUpReferenceError', () {
    test('allows non-empty references after trimming', () {
      expect(walletTopUpReferenceError('TXN-12345'), isNull);
      expect(walletTopUpReferenceError('  JazzCash 12345  '), isNull);
    });

    test('requires a transaction reference', () {
      expect(
        walletTopUpReferenceError(null),
        WalletTopUpValidationError.missingReference,
      );
      expect(
        walletTopUpReferenceError(''),
        WalletTopUpValidationError.missingReference,
      );
      expect(
        walletTopUpReferenceError('   '),
        WalletTopUpValidationError.missingReference,
      );
    });
  });

  group('walletTopUpMethodError', () {
    test('allows JazzCash and EasyPaisa after normalization', () {
      expect(walletTopUpMethodError('JazzCash'), isNull);
      expect(walletTopUpMethodError(' jazz cash '), isNull);
      expect(walletTopUpMethodError('EASYPAISA'), isNull);
      expect(normalizedWalletTopUpMethod(' easy paisa '), 'EasyPaisa');
    });

    test('rejects missing and unsupported top-up methods', () {
      expect(
        walletTopUpMethodError(null),
        WalletTopUpValidationError.missingMethod,
      );
      expect(
        walletTopUpMethodError(''),
        WalletTopUpValidationError.missingMethod,
      );
      expect(
        walletTopUpMethodError('bank transfer'),
        WalletTopUpValidationError.unsupportedMethod,
      );
      expect(
        normalizedWalletTopUpMethod('cash'),
        isNull,
      );
    });

    test('requestTopUp blocks invalid methods before demo or Supabase path',
        () {
      expect(
        () => WalletRepository().requestTopUp(
          amountPkr: 1000,
          method: 'cash',
          reference: 'TXN-12345',
        ),
        throwsArgumentError,
      );
    });
  });

  group('walletTopUpScreenshotExtensionError', () {
    test('allows jpg, jpeg, and png extensions after normalization', () {
      expect(walletTopUpScreenshotExtensionError('jpg'), isNull);
      expect(walletTopUpScreenshotExtensionError('.JPEG'), isNull);
      expect(walletTopUpScreenshotExtensionError(' png '), isNull);
      expect(normalizedWalletTopUpScreenshotExtension('.JPEG'), 'jpeg');
    });

    test('rejects missing and unsupported image extensions', () {
      expect(
        walletTopUpScreenshotExtensionError(null),
        WalletTopUpScreenshotExtensionError.unsupported,
      );
      expect(
        walletTopUpScreenshotExtensionError(''),
        WalletTopUpScreenshotExtensionError.unsupported,
      );
      expect(
        walletTopUpScreenshotExtensionError('gif'),
        WalletTopUpScreenshotExtensionError.unsupported,
      );
      expect(
        walletTopUpScreenshotExtensionError('pdf'),
        WalletTopUpScreenshotExtensionError.unsupported,
      );
    });
  });
}
