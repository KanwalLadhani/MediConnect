import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/wallet_transaction.dart';
import '../models/worker_wallet.dart';
import 'supabase_status.dart';

class WalletRepository {
  Future<WorkerWallet> fetchWallet() async {
    if (!SupabaseStatus.isConfigured) {
      return _demoWallet;
    }

    final client = SupabaseStatus.client;
    final worker = await _currentWorker(client);
    final wallet = await _walletForWorker(client, worker['id'] as String);
    final rows = await client
        .from('wallet_transactions')
        .select(
          'id, type, amount_pkr, direction, status, reference, screenshot_path, created_at',
        )
        .eq('wallet_id', wallet['id'])
        .order('created_at', ascending: false);

    return WorkerWallet(
      walletId: wallet['id'] as String,
      balancePkr: wallet['balance_pkr'] as int? ?? 0,
      status: wallet['status'] as String? ?? 'active',
      transactions: rows
          .cast<Map<String, dynamic>>()
          .map(
            (row) => WalletTransaction(
              id: row['id'] as String,
              type: row['type'] as String,
              amountPkr: row['amount_pkr'] as int? ?? 0,
              direction: row['direction'] as String,
              status: row['status'] as String,
              reference: row['reference'] as String?,
              screenshotPath: row['screenshot_path'] as String?,
              createdAt: DateTime.parse(row['created_at'] as String),
            ),
          )
          .toList(),
    );
  }

  Future<void> requestTopUp({
    required int amountPkr,
    required String method,
    required String reference,
    Uint8List? screenshotBytes,
    String? screenshotExtension,
  }) async {
    final normalizedMethod = normalizedWalletTopUpMethod(method);
    if (walletTopUpAmountError(amountPkr.toString()) != null) {
      throw ArgumentError('Enter a valid amount');
    }
    if (normalizedMethod == null) {
      throw ArgumentError('Choose JazzCash or EasyPaisa');
    }
    if (walletTopUpReferenceError(reference) != null) {
      throw ArgumentError('Enter the transaction reference');
    }

    if (!SupabaseStatus.isConfigured) {
      return;
    }

    final client = SupabaseStatus.client;
    final normalizedReference = reference.trim();
    final worker = await _currentWorker(client);
    final wallet = await _walletForWorker(client, worker['id'] as String);
    final screenshotPath = screenshotBytes == null
        ? null
        : await _uploadScreenshot(
            client: client,
            bytes: screenshotBytes,
            extension: screenshotExtension ?? 'jpg',
          );

    await client.from('wallet_transactions').insert({
      'wallet_id': wallet['id'],
      'type': 'top_up',
      'amount_pkr': amountPkr,
      'direction': 'credit',
      'status': 'pending',
      'reference': '$normalizedMethod: $normalizedReference',
      'screenshot_path': screenshotPath,
    });
  }

  Future<Map<String, dynamic>> _currentWorker(SupabaseClient client) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Please log in as a health worker.');
    }

    final worker = await client
        .from('health_workers')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (worker == null) {
      throw StateError('Complete worker onboarding before wallet top-up.');
    }

    return worker;
  }

  Future<Map<String, dynamic>> _walletForWorker(
    SupabaseClient client,
    String workerId,
  ) async {
    final existing = await client
        .from('wallets')
        .select('id, balance_pkr, status')
        .eq('worker_id', workerId)
        .maybeSingle();

    if (existing != null) {
      return existing;
    }

    return client
        .from('wallets')
        .insert({'worker_id': workerId})
        .select('id, balance_pkr, status')
        .single();
  }

  Future<String> _uploadScreenshot({
    required SupabaseClient client,
    required Uint8List bytes,
    required String extension,
  }) {
    final userId = client.auth.currentUser!.id;
    final normalizedExtension = normalizedWalletTopUpScreenshotExtension(
      extension,
    );
    if (walletTopUpScreenshotExtensionError(normalizedExtension) != null) {
      throw ArgumentError('Unsupported image type.');
    }

    final path =
        '$userId/${DateTime.now().millisecondsSinceEpoch}.$normalizedExtension';

    return client.storage.from('wallet-topups').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType:
                normalizedExtension == 'png' ? 'image/png' : 'image/jpeg',
          ),
        );
  }
}

int? parseWalletTopUpAmount(String? value) {
  return int.tryParse(value?.trim() ?? '');
}

WalletTopUpValidationError? walletTopUpAmountError(String? value) {
  final amount = parseWalletTopUpAmount(value);
  if (amount == null || amount <= 0) {
    return WalletTopUpValidationError.invalidAmount;
  }

  return null;
}

WalletTopUpValidationError? walletTopUpReferenceError(String? value) {
  if (value == null || value.trim().isEmpty) {
    return WalletTopUpValidationError.missingReference;
  }

  return null;
}

String? normalizedWalletTopUpMethod(String? value) {
  final normalized = (value ?? '').replaceAll(' ', '').trim().toLowerCase();
  return switch (normalized) {
    'jazzcash' => 'JazzCash',
    'easypaisa' => 'EasyPaisa',
    _ => null,
  };
}

WalletTopUpValidationError? walletTopUpMethodError(String? value) {
  if (value == null || value.trim().isEmpty) {
    return WalletTopUpValidationError.missingMethod;
  }
  if (normalizedWalletTopUpMethod(value) == null) {
    return WalletTopUpValidationError.unsupportedMethod;
  }

  return null;
}

enum WalletTopUpValidationError {
  invalidAmount,
  missingMethod,
  unsupportedMethod,
  missingReference,
}

String normalizedWalletTopUpScreenshotExtension(String? extension) {
  return (extension ?? '').replaceAll('.', '').trim().toLowerCase();
}

WalletTopUpScreenshotExtensionError? walletTopUpScreenshotExtensionError(
  String? extension,
) {
  final normalizedExtension = normalizedWalletTopUpScreenshotExtension(
    extension,
  );
  if (!{'jpg', 'jpeg', 'png'}.contains(normalizedExtension)) {
    return WalletTopUpScreenshotExtensionError.unsupported;
  }

  return null;
}

enum WalletTopUpScreenshotExtensionError {
  unsupported,
}

final _demoWallet = WorkerWallet(
  walletId: 'demo-wallet',
  balancePkr: 3200,
  status: 'active',
  transactions: [
    WalletTransaction(
      id: 'demo-wallet-tx-1',
      type: 'top_up',
      amountPkr: 5000,
      direction: 'credit',
      status: 'approved',
      reference: 'JazzCash: 123456',
      createdAt: DateTime(2026, 6, 12, 12),
    ),
    WalletTransaction(
      id: 'demo-wallet-tx-2',
      type: 'commission_deduction',
      amountPkr: 180,
      direction: 'debit',
      status: 'completed',
      reference: '10% platform commission',
      createdAt: DateTime(2026, 6, 13, 18),
    ),
  ],
);
