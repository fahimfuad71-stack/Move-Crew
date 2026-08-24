import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/sort_button.dart';
import '../../../data/models/review.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/mover_assignment_providers.dart';
import '../../../providers/review_providers.dart';

class MoverReviewsScreen extends ConsumerStatefulWidget {
  const MoverReviewsScreen({super.key});

  @override
  ConsumerState<MoverReviewsScreen> createState() => _MoverReviewsScreenState();
}

class _MoverReviewsScreenState extends ConsumerState<MoverReviewsScreen> {
  SortOrder _sortOrder = SortOrder.descending;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAppUserProvider).value;
    if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    final reviewsAsync = ref.watch(moverReviewsProvider(user.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('My Ratings & Reviews'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(moverReviewsProvider(user.id)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SortButton(
                  currentOrder: _sortOrder,
                  onChanged: (order) => setState(() => _sortOrder = order),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(moverReviewsProvider(user.id));
          await ref.read(moverReviewsProvider(user.id).future);
        },
        child: reviewsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
          data: (reviews) {
            if (reviews.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('No reviews yet.')),
                ],
              );
            }

            final sorted = List<Review>.from(reviews);
            if (_sortOrder == SortOrder.descending) {
              sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            } else {
              sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            }

            final averageRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

            return Column(
              children: [
                _RatingSummary(averageRating: averageRating, totalReviews: reviews.length),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: sorted.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _ReviewCard(review: sorted[index]),
                  ),
                ),
              ],
            );
          },
        ),
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

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(moverAssignedJobProvider(review.jobId));

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                jobAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (job) => Text(job.jobCode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E56A0))),
                ),
              ],
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
