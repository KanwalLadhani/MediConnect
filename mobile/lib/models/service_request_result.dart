import 'available_worker.dart';
import 'service_category.dart';

class ServiceRequestResult {
  const ServiceRequestResult({
    required this.requestId,
    required this.patientId,
    required this.category,
    required this.description,
    required this.address,
    required this.city,
    required this.workers,
    this.imagePath,
    this.latitude,
    this.longitude,
  });

  final String requestId;
  final String patientId;
  final ServiceCategory category;
  final String description;
  final String address;
  final String city;
  final String? imagePath;
  final double? latitude;
  final double? longitude;
  final List<AvailableWorker> workers;
}
