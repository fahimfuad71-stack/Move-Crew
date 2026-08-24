import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/review_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../data/models/review.dart';

class MoverReviewsScreen extends ConsumerWidget {
  const MoverReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider).value;
    if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    final reviewsAsync = ref.watch(moverReviewsProvider(user.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('My Ratings & Reviews'),
      ),
      body: reviewsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (reviews) {
          if (reviews.isEmpty) {
            return const Center(child: Text('No reviews yet.'));
          }

          final averageRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

          return Column(
            children: [
              _RatingSummary(averageRating: averageRating, totalReviews: reviews.length),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _ReviewCard(review: reviews[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.averageRating, required this.totalReviews});

  final double averageRating;
  final int totalReviews;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            averageRating.toStringAsFixed(1),
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                index < averageRating.floor() ? Icons.star : Icons.star_border,
                color: Colors.orange,
                size: 28,
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on $totalReviews reviews',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E5EA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  color: Colors.orange,
                  size: 16,
                );
              }),
            ),
            const SizedBox(height: 8),
            if (review.comment != null && review.comment!.isNotEmpty)
              Text(
                review.comment!,
                style: const TextStyle(fontSize: 15),
              ),
            const SizedBox(height: 8),
            Text(
              '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
