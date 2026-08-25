import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/sort_button.dart';
import '../../../data/models/review.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/mover_assignment_providers.dart';
import '../../../providers/review_providers.dart';
import '../../../providers/theme_provider.dart';

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
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ratings & Reviews', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggle();
            },
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(moverReviewsProvider(user.id)),
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(moverReviewsProvider(user.id));
          await ref.read(moverReviewsProvider(user.id).future);
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                Text('MY FEEDBACK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Theme.of(context).hintColor, letterSpacing: 1)),
                  SortButton(
                    currentOrder: _sortOrder,
                    onChanged: (order) => setState(() => _sortOrder = order),
                  ),
                ],
              ),
            ),
            Expanded(
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

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    itemCount: sorted.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return _RatingSummary(averageRating: averageRating, totalReviews: reviews.length);
                      return _ReviewCard(review: sorted[index - 1]);
                    },
                  );
                },
              ),
            ),
          ],
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
    return PremiumCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          Text(
            averageRating.toStringAsFixed(1),
            style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                index < averageRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.orange,
                size: 32,
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            'Based on $totalReviews client reviews',
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
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

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.orange,
                    size: 20,
                  );
                }),
              ),
              jobAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (job) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.tealPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(job.jobCode, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.tealPrimary)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            Text(
              review.comment!,
              style: const TextStyle(fontSize: 15, height: 1.4, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
