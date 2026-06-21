import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/incoming_service_request.dart';
import '../models/worker_dashboard_data.dart';
import '../models/worker_order.dart';
import '../models/worker_review.dart';
import 'order_status_transition.dart';
import 'supabase_status.dart';

class WorkerRepository {
  Future<WorkerDashboardData> fetchDashboard() async {
    if (!SupabaseStatus.isConfigured) {
      return _demoDashboard;
    }

    final client = SupabaseStatus.client;
    final worker = await _currentWorker(client);
    final workerId = worker['id'] as String;

    final wallet = await client
        .from('wallets')
        .select('balance_pkr')
        .eq('worker_id', workerId)
        .maybeSingle();

    final offers = await client
        .from('service_request_offers')
        .select('id')
        .eq('worker_id', workerId)
        .eq('status', 'pending');

    final activeOrders = await fetchActiveOrders();
    final earnings = await _fetchEarnings(client, workerId);
    final recentReviews = await _fetchRecentReviews(client, workerId);

    return WorkerDashboardData(
      workerId: workerId,
      verificationStatus: worker['verification_status'] as String,
      isAvailable: worker['is_available'] as bool? ?? false,
      walletBalancePkr: wallet?['balance_pkr'] as int? ?? 0,
      totalEarningsPkr: earnings.total,
      todayEarningsPkr: earnings.today,
      totalCompletedOrders: worker['total_completed_orders'] as int? ?? 0,
      rating: (worker['average_rating'] as num? ?? 0).toDouble(),
      totalReviews: worker['total_reviews'] as int? ?? 0,
      pendingRequestCount: offers.length,
      activeOrders: activeOrders,
      recentReviews: recentReviews,
    );
  }

  Future<void> updateAvailability({
    required String workerId,
    required bool isAvailable,
  }) async {
    if (!SupabaseStatus.isConfigured) {
      return;
    }

    final client = SupabaseStatus.client;
    final worker = await _currentWorker(client);
    if (worker['id'] != workerId) {
      throw StateError('You can only update your own availability.');
    }
    _ensureWorkerApproved(worker);

    if (!isAvailable) {
      await SupabaseStatus.client
          .from('health_workers')
          .update({'is_available': false}).eq('id', workerId);
      return;
    }

    final position = await _currentPosition(
      permissionDeniedMessage:
          'Location permission is required to become available.',
      serviceDisabledMessage:
          'Turn on location services before becoming available.',
    );

    await SupabaseStatus.client.from('health_workers').update({
      'is_available': true,
      'current_latitude': position.latitude,
      'current_longitude': position.longitude,
      'current_location_updated_at': DateTime.now().toIso8601String(),
    }).eq('id', workerId);
  }

  Future<_EarningsSummary> _fetchEarnings(
    SupabaseClient client,
    String workerId,
  ) async {
    final rows = await client
        .from('orders')
        .select('final_price_pkr, quoted_price_pkr, completed_at, created_at')
        .eq('worker_id', workerId)
        .eq('status', 'completed');

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    var total = 0;
    var today = 0;

    for (final row in rows.cast<Map<String, dynamic>>()) {
      final amount = row['final_price_pkr'] as int? ??
          row['quoted_price_pkr'] as int? ??
          0;
      total += amount;

      final timestamp =
          row['completed_at'] as String? ?? row['created_at'] as String?;
      if (timestamp != null &&
          DateTime.parse(timestamp).toLocal().isAfter(todayStart)) {
        today += amount;
      }
    }

    return _EarningsSummary(total: total, today: today);
  }

  Future<List<IncomingServiceRequest>> fetchIncomingRequests() async {
    if (!SupabaseStatus.isConfigured) {
      return _demoRequests;
    }

    final client = SupabaseStatus.client;
    final worker = await _currentWorker(client);
    final rows = await client
        .from('service_request_offers')
        .select(
          'id, patient_id, quoted_price_pkr, created_at, service_requests!inner(id, description, image_path, created_at, patients!inner(user_id), service_categories!inner(name_en), locations!inner(address, city))',
        )
        .eq('worker_id', worker['id'])
        .eq('status', 'pending')
        .order('created_at');

    final mappedRows = rows.cast<Map<String, dynamic>>();
    final userIds = mappedRows
        .map((row) => row['service_requests'] as Map<String, dynamic>)
        .map((request) => request['patients'] as Map<String, dynamic>)
        .map((patient) => patient['user_id'] as String)
        .toSet()
        .toList();
    final profiles = await _profilesById(client, userIds);

    return mappedRows.map((row) {
      final request = row['service_requests'] as Map<String, dynamic>;
      final patient = request['patients'] as Map<String, dynamic>;
      final category = request['service_categories'] as Map<String, dynamic>;
      final location = request['locations'] as Map<String, dynamic>;
      final profile = profiles[patient['user_id']];

      return IncomingServiceRequest(
        offerId: row['id'] as String,
        requestId: request['id'] as String,
        patientId: row['patient_id'] as String,
        patientName: profile?['full_name'] as String? ?? 'Patient',
        categoryName: category['name_en'] as String? ?? 'Service',
        description: request['description'] as String? ?? '',
        imagePath: request['image_path'] as String?,
        address: location['address'] as String? ?? '',
        city: location['city'] as String? ?? '',
        quotedPricePkr: row['quoted_price_pkr'] as int? ?? 0,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    }).toList();
  }

  Future<List<WorkerReview>> _fetchRecentReviews(
    SupabaseClient client,
    String workerId,
  ) async {
    final rows = await client
        .from('reviews')
        .select('id, rating, review_text, created_at, patients!inner(user_id)')
        .eq('worker_id', workerId)
        .order('created_at', ascending: false)
        .limit(3);

    final mappedRows = rows.cast<Map<String, dynamic>>();
    final userIds = mappedRows
        .map((row) => row['patients'] as Map<String, dynamic>)
        .map((patient) => patient['user_id'] as String)
        .toSet()
        .toList();
    final profiles = await _profilesById(client, userIds);

    return mappedRows.map((row) {
      final patient = row['patients'] as Map<String, dynamic>;
      final profile = profiles[patient['user_id']];

      return WorkerReview(
        id: row['id'] as String,
        rating: row['rating'] as int? ?? 0,
        reviewText: row['review_text'] as String?,
        patientName: profile?['full_name'] as String? ?? 'Patient',
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    }).toList();
  }

  Future<List<WorkerOrder>> fetchActiveOrders() async {
    if (!SupabaseStatus.isConfigured) {
      return _demoDashboard.activeOrders;
    }

    final client = SupabaseStatus.client;
    final worker = await _currentWorker(client);
    final rows = await client
        .from('orders')
        .select(
          'id, patient_id, worker_id, status, quoted_price_pkr, final_price_pkr, created_at, service_requests!inner(description, patients!inner(user_id), service_categories!inner(name_en), locations!inner(address, city))',
        )
        .eq('worker_id', worker['id'])
        .inFilter('status', ['accepted', 'worker_on_way', 'started']).order(
      'created_at',
      ascending: false,
    );

    return _mapOrders(client, rows.cast<Map<String, dynamic>>());
  }

  Future<String> acceptRequest(IncomingServiceRequest request) async {
    if (!SupabaseStatus.isConfigured) {
      return 'demo-order';
    }

    final client = SupabaseStatus.client;
    final worker = await _currentWorker(client);
    _ensureWorkerApproved(worker);
    await _ensureWalletCanAcceptRequests(client, worker['id'] as String);
    final now = DateTime.now().toIso8601String();

    await client
        .from('service_request_offers')
        .update({'status': 'accepted', 'responded_at': now}).eq(
      'id',
      request.offerId,
    );

    final order = await client
        .from('orders')
        .insert({
          'service_request_id': request.requestId,
          'patient_id': request.patientId,
          'worker_id': worker['id'],
          'service_category_id': await _categoryIdForRequest(
            client,
            request.requestId,
          ),
          'quoted_price_pkr': request.quotedPricePkr,
          'status': 'accepted',
          'accepted_at': now,
        })
        .select('id')
        .single();

    await client.from('order_events').insert({
      'order_id': order['id'],
      'actor_user_id': client.auth.currentUser?.id,
      'event_type': 'accepted',
      'metadata': {'offer_id': request.offerId},
    });

    final patient = await client
        .from('patients')
        .select('user_id')
        .eq('id', request.patientId)
        .single();

    await client.from('chats').insert({
      'order_id': order['id'],
      'patient_user_id': patient['user_id'],
      'worker_user_id': client.auth.currentUser?.id,
    });

    return order['id'] as String;
  }

  Future<void> declineRequest(String offerId) async {
    if (!SupabaseStatus.isConfigured) {
      return;
    }

    await SupabaseStatus.client.from('service_request_offers').update({
      'status': 'declined',
      'responded_at': DateTime.now().toIso8601String(),
    }).eq('id', offerId);
  }

  Future<void> updateOrderStatus({
    required WorkerOrder order,
    required String status,
    int? finalPricePkr,
    String? completionNotes,
  }) async {
    if (!SupabaseStatus.isConfigured) {
      return;
    }

    final client = SupabaseStatus.client;
    if (status == 'completed') {
      final resolvedFinalPrice = finalPricePkr ?? order.quotedPricePkr;
      final priceError = workerCompletionPriceError(resolvedFinalPrice);
      if (priceError != null) {
        throw StateError('Enter a valid amount');
      }

      await client.rpc(
        'complete_order_with_commission',
        params: {
          'target_order_id': order.id,
          'final_price': resolvedFinalPrice,
        },
      );
      final notes = completionNotes?.trim();
      if (notes != null && notes.isNotEmpty) {
        await client.from('medical_records').insert({
          'patient_id': order.patientId,
          'worker_id': order.workerId,
          'order_id': order.id,
          'notes': notes,
        });
      }
      return;
    }

    final transition = buildNonCompletionOrderStatusTransition(
      currentStatus: order.status,
      targetStatus: status,
      eventSource: workerOrderStatusEventSource,
    );

    await client.rpc(
      'update_order_status_with_event',
      params: {
        'target_order_id': order.id,
        'target_status': transition.targetStatus,
        'event_metadata': transition.metadata,
      },
    );
  }

  Future<void> shareCurrentLocation(WorkerOrder order) async {
    if (!SupabaseStatus.isConfigured) {
      return;
    }

    final client = SupabaseStatus.client;
    final worker = await _currentWorker(client);
    final position = await _currentPosition(
      permissionDeniedMessage:
          'Location permission is required to share location.',
      serviceDisabledMessage:
          'Turn on location services before sharing location.',
    );

    await client.from('worker_locations').insert({
      'worker_id': worker['id'],
      'order_id': order.id,
      'latitude': position.latitude,
      'longitude': position.longitude,
    });

    await client.from('order_events').insert({
      'order_id': order.id,
      'actor_user_id': client.auth.currentUser?.id,
      'event_type': 'location_shared',
      'metadata': {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
    });

    await client.from('health_workers').update({
      'current_latitude': position.latitude,
      'current_longitude': position.longitude,
      'current_location_updated_at': DateTime.now().toIso8601String(),
    }).eq('id', worker['id']);
  }

  Future<Position> _currentPosition({
    required String permissionDeniedMessage,
    required String serviceDisabledMessage,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError(serviceDisabledMessage);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError(permissionDeniedMessage);
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<Map<String, dynamic>> _currentWorker(SupabaseClient client) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Please log in as a health worker.');
    }

    final worker = await client
        .from('health_workers')
        .select(
          'id, verification_status, is_available, average_rating, total_reviews, total_completed_orders',
        )
        .eq('user_id', user.id)
        .maybeSingle();

    if (worker == null) {
      throw StateError('Complete worker onboarding before accepting requests.');
    }

    return worker;
  }

  void _ensureWorkerApproved(Map<String, dynamic> worker) {
    final status = worker['verification_status'] as String? ?? 'pending';
    if (status != 'approved') {
      throw StateError(
        'Your worker profile must be approved before accepting requests.',
      );
    }
  }

  Future<void> _ensureWalletCanAcceptRequests(
    SupabaseClient client,
    String workerId,
  ) async {
    final wallet = await client
        .from('wallets')
        .select('balance_pkr, status')
        .eq('worker_id', workerId)
        .maybeSingle();

    if (wallet == null) {
      return;
    }

    final status = wallet['status'] as String? ?? 'active';
    final balance = wallet['balance_pkr'] as int? ?? 0;
    final blocker = workerWalletAcceptanceBlocker(
      status: status,
      balancePkr: balance,
    );

    if (blocker != null) {
      throw StateError(blocker);
    }
  }

  Future<String> _categoryIdForRequest(
    SupabaseClient client,
    String requestId,
  ) async {
    final request = await client
        .from('service_requests')
        .select('service_category_id')
        .eq('id', requestId)
        .single();

    return request['service_category_id'] as String;
  }

  Future<List<WorkerOrder>> _mapOrders(
    SupabaseClient client,
    List<Map<String, dynamic>> rows,
  ) async {
    final userIds = rows
        .map((row) => row['service_requests'] as Map<String, dynamic>)
        .map((request) => request['patients'] as Map<String, dynamic>)
        .map((patient) => patient['user_id'] as String)
        .toSet()
        .toList();
    final profiles = await _profilesById(client, userIds);

    return rows.map((row) {
      final request = row['service_requests'] as Map<String, dynamic>;
      final patient = request['patients'] as Map<String, dynamic>;
      final category = request['service_categories'] as Map<String, dynamic>;
      final location = request['locations'] as Map<String, dynamic>;
      final profile = profiles[patient['user_id']];

      return WorkerOrder(
        id: row['id'] as String,
        patientId: row['patient_id'] as String,
        workerId: row['worker_id'] as String,
        patientName: profile?['full_name'] as String? ?? 'Patient',
        categoryName: category['name_en'] as String? ?? 'Service',
        description: request['description'] as String? ?? '',
        address: location['address'] as String? ?? '',
        city: location['city'] as String? ?? '',
        status: row['status'] as String? ?? 'accepted',
        quotedPricePkr: row['quoted_price_pkr'] as int? ?? 0,
        finalPricePkr: row['final_price_pkr'] as int?,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    }).toList();
  }

  Future<Map<String, Map<String, dynamic>>> _profilesById(
    SupabaseClient client,
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) {
      return {};
    }

    final rows = await client
        .from('profiles')
        .select('id, full_name, phone')
        .inFilter('id', userIds);

    return {
      for (final row in rows.cast<Map<String, dynamic>>())
        row['id'] as String: row,
    };
  }
}

final _demoDashboard = WorkerDashboardData(
  workerId: 'demo-worker-1',
  verificationStatus: 'approved',
  isAvailable: true,
  walletBalancePkr: 3200,
  totalEarningsPkr: 18400,
  todayEarningsPkr: 2100,
  totalCompletedOrders: 18,
  rating: 4.8,
  totalReviews: 42,
  pendingRequestCount: _demoRequests.length,
  recentReviews: [
    WorkerReview(
      id: 'demo-review-1',
      rating: 5,
      patientName: 'Sara Ali',
      reviewText: 'Arrived on time and explained the care clearly.',
      createdAt: DateTime(2026, 6, 12, 18),
    ),
    WorkerReview(
      id: 'demo-review-2',
      rating: 4,
      patientName: 'Hamza Noor',
      reviewText: 'Good service and professional communication.',
      createdAt: DateTime(2026, 6, 11, 15),
    ),
  ],
  activeOrders: [
    WorkerOrder(
      id: 'demo-order-1',
      patientId: 'demo-patient-id',
      workerId: 'demo-worker-id',
      patientName: 'Sara Ali',
      categoryName: 'Injection',
      description: 'Injection needed at home this evening.',
      address: 'House 12, Block 7',
      city: 'Karachi',
      status: 'accepted',
      quotedPricePkr: 1200,
      createdAt: DateTime(2026, 6, 13, 18),
    ),
  ],
);

final _demoRequests = [
  IncomingServiceRequest(
    offerId: 'demo-offer-1',
    requestId: 'demo-request-1',
    patientId: 'demo-patient-1',
    patientName: 'Hamza Noor',
    categoryName: 'Bandage',
    description: 'Fresh wound dressing needed after a minor cut.',
    address: 'Main Road, Gulshan-e-Iqbal',
    city: 'Karachi',
    quotedPricePkr: 950,
    createdAt: DateTime(2026, 6, 13, 19),
  ),
];

@visibleForTesting
String? workerWalletAcceptanceBlocker({
  required String status,
  required int balancePkr,
}) {
  if (status != 'active') {
    return 'Wallet is frozen. Contact admin before accepting jobs.';
  }

  if (balancePkr < 0) {
    return 'Top up wallet before accepting new jobs.';
  }

  return null;
}

WorkerCompletionPriceError? workerCompletionPriceError(int? finalPricePkr) {
  if (finalPricePkr == null || finalPricePkr <= 0) {
    return WorkerCompletionPriceError.invalidFinalPrice;
  }

  return null;
}

@visibleForTesting
int estimatedPlatformCommissionPkr(int finalPricePkr) {
  if (workerCompletionPriceError(finalPricePkr) != null) {
    throw ArgumentError.value(
      finalPricePkr,
      'finalPricePkr',
      'Must be greater than zero',
    );
  }

  return (finalPricePkr * 0.10).ceil();
}

enum WorkerCompletionPriceError {
  invalidFinalPrice,
}

class _EarningsSummary {
  const _EarningsSummary({
    required this.total,
    required this.today,
  });

  final int total;
  final int today;
}
