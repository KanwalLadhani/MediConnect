class ServiceOrder {
  const ServiceOrder({
    required this.id,
    required this.patientId,
    required this.workerId,
    required this.patientUserId,
    required this.workerUserId,
    required this.patientName,
    required this.workerName,
    required this.categoryName,
    required this.description,
    required this.address,
    required this.city,
    required this.status,
    required this.quotedPricePkr,
    required this.createdAt,
    this.patientPhone,
    this.workerPhone,
    this.finalPricePkr,
    this.medicalRecordNotes,
  });

  final String id;
  final String patientId;
  final String workerId;
  final String patientUserId;
  final String workerUserId;
  final String patientName;
  final String workerName;
  final String categoryName;
  final String description;
  final String address;
  final String city;
  final String status;
  final int quotedPricePkr;
  final DateTime createdAt;
  final String? patientPhone;
  final String? workerPhone;
  final int? finalPricePkr;
  final String? medicalRecordNotes;
}
