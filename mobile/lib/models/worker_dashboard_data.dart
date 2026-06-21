import 'worker_order.dart';
import 'worker_review.dart';

class WorkerDashboardData {
  const WorkerDashboardData({
    required this.workerId,
    required this.verificationStatus,
    required this.isAvailable,
    required this.walletBalancePkr,
    required this.totalEarningsPkr,
    required this.todayEarningsPkr,
    required this.totalCompletedOrders,
    required this.rating,
    required this.totalReviews,
    required this.pendingRequestCount,
    required this.activeOrders,
    required this.recentReviews,
  });

  final String workerId;
  final String verificationStatus;
  final bool isAvailable;
  final int walletBalancePkr;
  final int totalEarningsPkr;
  final int todayEarningsPkr;
  final int totalCompletedOrders;
  final double rating;
  final int totalReviews;
  final int pendingRequestCount;
  final List<WorkerOrder> activeOrders;
  final List<WorkerReview> recentReviews;

  bool get isApproved => verificationStatus == 'approved';
}
