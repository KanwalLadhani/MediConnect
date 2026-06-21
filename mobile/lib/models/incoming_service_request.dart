class IncomingServiceRequest {
  const IncomingServiceRequest({
    required this.offerId,
    required this.requestId,
    required this.patientId,
    required this.patientName,
    required this.categoryName,
    required this.description,
    required this.address,
    required this.city,
    required this.quotedPricePkr,
    required this.createdAt,
    this.imagePath,
  });

  final String offerId;
  final String requestId;
  final String patientId;
  final String patientName;
  final String categoryName;
  final String description;
  final String address;
  final String city;
  final int quotedPricePkr;
  final DateTime createdAt;
  final String? imagePath;
}
