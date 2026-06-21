class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amountPkr,
    required this.direction,
    required this.status,
    required this.createdAt,
    this.reference,
    this.screenshotPath,
  });

  final String id;
  final String type;
  final int amountPkr;
  final String direction;
  final String status;
  final DateTime createdAt;
  final String? reference;
  final String? screenshotPath;
}
