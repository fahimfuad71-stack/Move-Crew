import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review.dart';

class ReviewRepository {
  const ReviewRepository(this._client);

  final SupabaseClient _client;

  Future<void> submitReview(Review review) async {
    await _client.from('reviews').insert(review.toMap());
  }

  Future<List<Review>> getMoverReviews(String moverId) async {
    final response = await _client
        .from('reviews')
        .select()
        .eq('mover_id', moverId)
        .order('created_at', ascending: false);

    return response.map((row) => Review.fromMap(row)).toList();
  }

  Future<Review?> getReviewForJob(String jobId) async {
    final response = await _client
        .from('reviews')
        .select()
        .eq('job_id', jobId)
        .maybeSingle();

    if (response == null) return null;
    return Review.fromMap(response);
  }
}
