class WorkerReview {
  const WorkerReview({
    required this.id,
    required this.rating,
    required this.patientName,
    required this.createdAt,
    this.reviewText,
  });

  final String id;
  final int rating;
  final String patientName;
  final DateTime createdAt;
  final String? reviewText;
}
