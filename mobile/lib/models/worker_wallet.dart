import 'wallet_transaction.dart';

class WorkerWallet {
  const WorkerWallet({
    required this.walletId,
    required this.balancePkr,
    required this.status,
    required this.transactions,
  });

  final String walletId;
  final int balancePkr;
  final String status;
  final List<WalletTransaction> transactions;
}
