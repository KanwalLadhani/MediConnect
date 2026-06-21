import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message.dart';
import '../models/service_order.dart';
import '../models/worker_location.dart';
import 'order_status_transition.dart';
import 'supabase_status.dart';

class OrderRepository {
  static const _orderSelect =
      'id, patient_id, worker_id, status, quoted_price_pkr, final_price_pkr, created_at, patients!inner(user_id), health_workers!inner(user_id), service_requests!inner(description, service_categories!inner(name_en), locations!inner(address, city))';

  Future<List<ServiceOrder>> fetchActiveOrders() async {
    if (!SupabaseStatus.isConfigured) {
      return _demoOrders;
    }

    final client = SupabaseStatus.client;
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Please log in to view active orders.');
    }

    final profile = await client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();
    final role = profile?['role'] as String?;

    var query = client.from('orders').select(_orderSelect);

    if (role == 'patient') {
      final patient = await client
          .from('patients')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
      if (patient == null) {
        return [];
      }
      query = query.eq('patient_id', patient['id']);
    } else {
      final worker = await client
          .from('health_workers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
      if (worker == null) {
        return [];
      }
      query = query.eq('worker_id', worker['id']);
    }

    final rows = await query
        .inFilter('status', ['accepted', 'worker_on_way', 'started']).order(
      'created_at',
      ascending: false,
    );

    return _mapOrders(client, rows.cast<Map<String, dynamic>>());
  }

  Future<List<ServiceOrder>> fetchOrderHistory() async {
    if (!SupabaseStatus.isConfigured) {
      return _demoHistory;
    }

    final client = SupabaseStatus.client;
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Please log in to view order history.');
    }

    final profile = await client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();
    final role = profile?['role'] as String?;

    var query = client.from('orders').select(_orderSelect);

    if (role == 'patient') {
      final patient = await client
          .from('patients')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
      if (patient == null) {
        return [];
      }
      query = query.eq('patient_id', patient['id']);
    } else {
      final worker = await client
          .from('health_workers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
      if (worker == null) {
        return [];
      }
      query = query.eq('worker_id', worker['id']);
    }

    final rows = await query
        .inFilter('status', ['completed', 'cancelled', 'disputed']).order(
      'created_at',
      ascending: false,
    );

    return _mapOrders(client, rows.cast<Map<String, dynamic>>());
  }

  Future<ServiceOrder?> fetchOrderById(String orderId) async {
    if (!SupabaseStatus.isConfigured) {
      for (final order in [..._demoOrders, ..._demoHistory]) {
        if (order.id == orderId) {
          return order;
        }
      }
      return null;
    }

    final client = SupabaseStatus.client;
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Please log in to view this order.');
    }

    final row = await client
        .from('orders')
        .select(_orderSelect)
        .eq('id', orderId)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    final orders = await _mapOrders(client, [row]);
    return orders.isEmpty ? null : orders.first;
  }

  Future<String> ensureChat(String orderId) async {
    if (!SupabaseStatus.isConfigured) {
      return 'demo-chat';
    }

    final client = SupabaseStatus.client;
    final existing = await client
        .from('chats')
        .select('id')
        .eq('order_id', orderId)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    final order = await client
        .from('orders')
        .select('id, patients!inner(user_id), health_workers!inner(user_id)')
        .eq('id', orderId)
        .single();
    final patient = order['patients'] as Map<String, dynamic>;
    final worker = order['health_workers'] as Map<String, dynamic>;

    final chat = await client
        .from('chats')
        .insert({
          'order_id': orderId,
          'patient_user_id': patient['user_id'],
          'worker_user_id': worker['user_id'],
        })
        .select('id')
        .single();

    return chat['id'] as String;
  }

  Future<WorkerLocation?> fetchLatestWorkerLocation(String orderId) async {
    if (!SupabaseStatus.isConfigured) {
      return WorkerLocation(
        latitude: 24.8607,
        longitude: 67.0011,
        createdAt: DateTime(2026, 6, 13, 18, 20),
      );
    }

    final row = await SupabaseStatus.client
        .from('worker_locations')
        .select('latitude, longitude, created_at')
        .eq('order_id', orderId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return WorkerLocation(
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Future<List<ChatMessage>> fetchMessages(String chatId) async {
    if (!SupabaseStatus.isConfigured) {
      return _demoMessages;
    }

    final rows = await SupabaseStatus.client
        .from('messages')
        .select('id, sender_user_id, message_type, body, file_path, created_at')
        .eq('chat_id', chatId)
        .order('created_at');

    return Future.wait(
      rows.cast<Map<String, dynamic>>().map(
        (row) async {
          final filePath = row['file_path'] as String?;
          return ChatMessage(
            id: row['id'] as String,
            senderUserId: row['sender_user_id'] as String,
            messageType: row['message_type'] as String,
            body: row['body'] as String?,
            filePath: filePath,
            fileUrl:
                filePath == null ? null : await _signedChatImageUrl(filePath),
            createdAt: DateTime.parse(row['created_at'] as String),
          );
        },
      ),
    );
  }

  Future<void> sendTextMessage({
    required String chatId,
    required String body,
  }) async {
    final normalizedBody = body.trim();
    if (chatMessageBodyError(normalizedBody) != null) {
      throw ArgumentError('Message cannot be empty.');
    }

    if (!SupabaseStatus.isConfigured) {
      return;
    }

    final user = SupabaseStatus.client.auth.currentUser;
    if (user == null) {
      throw StateError('Please log in to send messages.');
    }

    await SupabaseStatus.client.from('messages').insert({
      'chat_id': chatId,
      'sender_user_id': user.id,
      'message_type': 'text',
      'body': normalizedBody,
    });
  }

  Future<void> submitReview({
    required ServiceOrder order,
    required int rating,
    String? reviewText,
  }) async {
    if (reviewRatingError(rating) != null) {
      throw ArgumentError('Rating must be between 1 and 5.');
    }

    if (!SupabaseStatus.isConfigured) {
      return;
    }

    await SupabaseStatus.client.rpc(
      'submit_order_review',
      params: {
        'target_order_id': order.id,
        'review_rating': rating,
        'review_body': reviewText,
      },
    );
  }

  Future<void> reportDispute({
    required ServiceOrder order,
    required String reason,
    String? details,
  }) async {
    if (!SupabaseStatus.isConfigured) {
      return;
    }

    final user = SupabaseStatus.client.auth.currentUser;
    if (user == null) {
      throw StateError('Please log in to report an issue.');
    }

    await SupabaseStatus.client.from('disputes').insert({
      'order_id': order.id,
      'reported_by': user.id,
      'reason': reason,
      'details': details,
      'status': 'open',
    });
  }

  Future<void> cancelOrder(ServiceOrder order) async {
    if (!SupabaseStatus.isConfigured) {
      return;
    }

    final client = SupabaseStatus.client;
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Please log in to cancel an order.');
    }

    final transition = buildNonCompletionOrderStatusTransition(
      currentStatus: order.status,
      targetStatus: 'cancelled',
      eventSource: patientActiveOrderEventSource,
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

  Future<void> sendImageMessage({
    required String chatId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final normalizedExtension = normalizedChatImageExtension(extension);
    if (chatImageExtensionError(normalizedExtension) != null) {
      throw ArgumentError('Unsupported image type.');
    }

    if (!SupabaseStatus.isConfigured) {
      return;
    }

    final client = SupabaseStatus.client;
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Please log in to send images.');
    }

    final path =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$normalizedExtension';
    final filePath = await client.storage.from('chat-images').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType:
                normalizedExtension == 'png' ? 'image/png' : 'image/jpeg',
          ),
        );

    await client.from('messages').insert({
      'chat_id': chatId,
      'sender_user_id': user.id,
      'message_type': 'image',
      'file_path': filePath,
    });
  }

  Future<String?> _signedChatImageUrl(String filePath) async {
    if (!SupabaseStatus.isConfigured || filePath.trim().isEmpty) {
      return null;
    }

    final result = await SupabaseStatus.client.storage
        .from('chat-images')
        .createSignedUrl(filePath, 10 * 60);

    return result;
  }

  String? currentUserId() {
    if (!SupabaseStatus.isConfigured) {
      return 'demo-patient';
    }

    return SupabaseStatus.client.auth.currentUser?.id;
  }

  Future<List<ServiceOrder>> _mapOrders(
    SupabaseClient client,
    List<Map<String, dynamic>> rows,
  ) async {
    final orderIds = rows.map((row) => row['id'] as String).toList();
    final profileIds = <String>{};
    for (final row in rows) {
      final patient = row['patients'] as Map<String, dynamic>;
      final worker = row['health_workers'] as Map<String, dynamic>;
      profileIds.add(patient['user_id'] as String);
      profileIds.add(worker['user_id'] as String);
    }
    final profiles = await _profilesById(client, profileIds.toList());
    final recordNotes = await _medicalRecordNotesByOrderId(client, orderIds);

    return rows.map((row) {
      final patient = row['patients'] as Map<String, dynamic>;
      final worker = row['health_workers'] as Map<String, dynamic>;
      final request = row['service_requests'] as Map<String, dynamic>;
      final category = request['service_categories'] as Map<String, dynamic>;
      final location = request['locations'] as Map<String, dynamic>;
      final patientProfile = profiles[patient['user_id']];
      final workerProfile = profiles[worker['user_id']];

      return ServiceOrder(
        id: row['id'] as String,
        patientId: row['patient_id'] as String,
        workerId: row['worker_id'] as String,
        patientUserId: patient['user_id'] as String,
        workerUserId: worker['user_id'] as String,
        patientName: patientProfile?['full_name'] as String? ?? 'Patient',
        workerName: workerProfile?['full_name'] as String? ?? 'Worker',
        patientPhone: patientProfile?['phone'] as String?,
        workerPhone: workerProfile?['phone'] as String?,
        categoryName: category['name_en'] as String? ?? 'Service',
        description: request['description'] as String? ?? '',
        address: location['address'] as String? ?? '',
        city: location['city'] as String? ?? '',
        status: row['status'] as String? ?? 'accepted',
        quotedPricePkr: row['quoted_price_pkr'] as int? ?? 0,
        finalPricePkr: row['final_price_pkr'] as int?,
        medicalRecordNotes: recordNotes[row['id']],
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    }).toList();
  }

  Future<Map<String, String>> _medicalRecordNotesByOrderId(
    SupabaseClient client,
    List<String> orderIds,
  ) async {
    if (orderIds.isEmpty) {
      return {};
    }

    final rows = await client
        .from('medical_records')
        .select('order_id, notes, created_at')
        .inFilter('order_id', orderIds)
        .order('created_at', ascending: false);

    final notes = <String, String>{};
    for (final row in rows.cast<Map<String, dynamic>>()) {
      final orderId = row['order_id'] as String?;
      final note = row['notes'] as String?;
      if (orderId == null || note == null || notes.containsKey(orderId)) {
        continue;
      }
      notes[orderId] = note;
    }
    return notes;
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

DisputeReasonError? disputeReasonError(String? reason) {
  if (reason == null || reason.trim().isEmpty) {
    return DisputeReasonError.required;
  }

  return null;
}

enum DisputeReasonError {
  required,
}

ReviewRatingError? reviewRatingError(int rating) {
  if (rating < 1 || rating > 5) {
    return ReviewRatingError.outOfRange;
  }

  return null;
}

enum ReviewRatingError {
  outOfRange,
}

ChatMessageBodyError? chatMessageBodyError(String? body) {
  if (body == null || body.trim().isEmpty) {
    return ChatMessageBodyError.required;
  }

  return null;
}

enum ChatMessageBodyError {
  required,
}

String normalizedChatImageExtension(String? extension) {
  return (extension ?? '').replaceAll('.', '').trim().toLowerCase();
}

ChatImageExtensionError? chatImageExtensionError(String? extension) {
  final normalizedExtension = normalizedChatImageExtension(extension);
  if (!{'jpg', 'jpeg', 'png'}.contains(normalizedExtension)) {
    return ChatImageExtensionError.unsupported;
  }

  return null;
}

enum ChatImageExtensionError {
  unsupported,
}

final _demoOrders = [
  ServiceOrder(
    id: 'demo-order-1',
    patientId: 'demo-patient-id',
    workerId: 'demo-worker-id',
    patientUserId: 'demo-patient',
    workerUserId: 'demo-worker',
    patientName: 'Sara Ali',
    workerName: 'Ayesha Khan',
    patientPhone: '+92 300 1111111',
    workerPhone: '+92 300 0000000',
    categoryName: 'Injection',
    description: 'Injection needed at home this evening.',
    address: 'House 12, Block 7',
    city: 'Karachi',
    status: 'accepted',
    quotedPricePkr: 1200,
    createdAt: DateTime(2026, 6, 13, 18),
  ),
];

final _demoMessages = [
  ChatMessage(
    id: 'demo-message-1',
    senderUserId: 'demo-patient',
    messageType: 'text',
    body: 'Please call when you are near the house.',
    createdAt: DateTime(2026, 6, 13, 18, 5),
  ),
  ChatMessage(
    id: 'demo-message-2',
    senderUserId: 'demo-worker',
    messageType: 'text',
    body: 'Sure, I am preparing now.',
    createdAt: DateTime(2026, 6, 13, 18, 8),
  ),
];

final _demoHistory = [
  ServiceOrder(
    id: 'demo-order-history-1',
    patientId: 'demo-patient-id',
    workerId: 'demo-worker-id',
    patientUserId: 'demo-patient',
    workerUserId: 'demo-worker',
    patientName: 'Sara Ali',
    workerName: 'Ayesha Khan',
    patientPhone: '+92 300 1111111',
    workerPhone: '+92 300 0000000',
    categoryName: 'Bandage',
    description: 'Completed wound dressing support.',
    address: 'House 12, Block 7',
    city: 'Karachi',
    status: 'completed',
    quotedPricePkr: 900,
    finalPricePkr: 900,
    medicalRecordNotes: 'Dressing completed. Keep the wound clean and dry.',
    createdAt: DateTime(2026, 6, 12, 16),
  ),
];
