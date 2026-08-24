class Review {
  const Review({
    required this.id,
    required this.jobId,
    required this.customerId,
    required this.moverId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  final String id;
  final String jobId;
  final String customerId;
  final String moverId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] as String,
      jobId: map['job_id'] as String,
      customerId: map['customer_id'] as String,
      moverId: map['mover_id'] as String,
      rating: map['rating'] as int,
      comment: map['comment'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'job_id': jobId,
      'customer_id': customerId,
      'mover_id': moverId,
      'rating': rating,
      'comment': comment,
    };
  }
}
