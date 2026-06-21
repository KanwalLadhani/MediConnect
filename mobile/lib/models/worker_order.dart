import 'service_order.dart';

class WorkerOrder {
  const WorkerOrder({
    required this.id,
    required this.patientId,
    required this.workerId,
    required this.patientName,
    required this.categoryName,
    required this.description,
    required this.address,
    required this.city,
    required this.status,
    required this.quotedPricePkr,
    required this.createdAt,
    this.finalPricePkr,
  });

  final String id;
  final String patientId;
  final String workerId;
  final String patientName;
  final String categoryName;
  final String description;
  final String address;
  final String city;
  final String status;
  final int quotedPricePkr;
  final DateTime createdAt;
  final int? finalPricePkr;

  ServiceOrder toServiceOrder() {
    return ServiceOrder(
      id: id,
      patientId: patientId,
      workerId: workerId,
      patientUserId: '',
      workerUserId: '',
      patientName: patientName,
      workerName: 'You',
      categoryName: categoryName,
      description: description,
      address: address,
      city: city,
      status: status,
      quotedPricePkr: quotedPricePkr,
      finalPricePkr: finalPricePkr,
      createdAt: createdAt,
    );
  }
}
