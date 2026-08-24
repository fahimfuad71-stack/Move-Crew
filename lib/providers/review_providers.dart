import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/review_repository.dart';
import '../data/supabase_client.dart';
import '../data/models/review.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(supabaseClientProvider));
});

final moverReviewsProvider = FutureProvider.family<List<Review>, String>((ref, moverId) {
  return ref.watch(reviewRepositoryProvider).getMoverReviews(moverId);
});

final jobReviewProvider = FutureProvider.family<Review?, String>((ref, jobId) {
  return ref.watch(reviewRepositoryProvider).getReviewForJob(jobId);
});
