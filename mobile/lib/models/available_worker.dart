class AvailableWorker {
  const AvailableWorker({
    required this.id,
    required this.name,
    required this.workerType,
    required this.city,
    required this.pricePkr,
    required this.rating,
    required this.totalReviews,
    this.serviceArea,
    this.phone,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.etaMinutes,
  });

  final String id;
  final String name;
  final String workerType;
  final String city;
  final int pricePkr;
  final double rating;
  final int totalReviews;
  final String? serviceArea;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final int? etaMinutes;
}
