import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/status_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/job_status_chip.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../data/models/job.dart';
import '../../../providers/review_providers.dart';
import '../../../providers/customer_job_providers.dart';
import '../../../data/models/review.dart';
import '../../../providers/theme_provider.dart';
import '../tracking/customer_live_map_screen.dart';

class CustomerJobDetailsScreen extends ConsumerWidget {
  const CustomerJobDetailsScreen({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobProvider(jobId));
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Move Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.obsidianDark,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggle();
            },
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppColors.obsidianDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: jobAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (job) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(jobProvider(jobId));
            ref.invalidate(jobItemsProvider(jobId));
            await Future.wait([
              ref.read(jobProvider(jobId).future),
              ref.read(jobItemsProvider(jobId).future),
            ]);
          },
          child: _JobDetailsContent(job: job),
        ),
      ),
    );
  }
}

class _JobDetailsContent extends ConsumerWidget {
  const _JobDetailsContent({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(jobItemsProvider(job.id));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        _HeaderSection(job: job),
        if (job.status == JobStatus.assigned || job.status == JobStatus.inProgress) ...[
          const SizedBox(height: 16),
          _TrackMoverAction(jobId: job.id),
        ],
        if (job.status == JobStatus.completed) ...[
          const SizedBox(height: 16),
          _RatingAction(job: job),
        ],
        const SizedBox(height: 24),
        const Text('MOVE INFORMATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.stormyLight, letterSpacing: 1)),
        const SizedBox(height: 12),
        PremiumCard(
          child: Column(
            children: [
              _ModernInfoRow(icon: Icons.trip_origin_rounded, label: 'PICKUP', value: job.pickupAddress),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
              _ModernInfoRow(icon: Icons.location_on_rounded, label: 'DESTINATION', value: job.destinationAddress),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
              Row(
                children: [
                  Expanded(child: _ModernInfoRow(icon: Icons.calendar_today_rounded, label: 'DATE', value: job.moveDate.toString().split(' ')[0])),
                  Expanded(child: _ModernInfoRow(icon: Icons.access_time_rounded, label: 'TIME', value: job.startTime)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('MOVING ITEMS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.stormyLight, letterSpacing: 1)),
        const SizedBox(height: 12),
        itemsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (items) => PremiumCard(
            child: items.isEmpty
                ? const Text('No items listed.')
                : Column(
                    children: List.generate(items.length, (i) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 16),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_rounded, size: 20, color: AppColors.tealPrimary),
                            const SizedBox(width: 12),
                            Expanded(child: Text(items[i].name, style: const TextStyle(fontWeight: FontWeight.w500))),
                            Text('x${items[i].quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }),
                  ),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      color: AppColors.tealPrimary.withOpacity(0.1),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.tealPrimary, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.jobCode, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Text('ESTIMATED MOVE', style: TextStyle(color: AppColors.tealPrimary, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
              ],
            ),
          ),
          JobStatusChip(status: job.status),
        ],
      ),
    );
  }
}

class _ModernInfoRow extends StatelessWidget {
  const _ModernInfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.tealPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Theme.of(context).hintColor)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrackMoverAction extends ConsumerWidget {
  const _TrackMoverAction({required this.jobId});
  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentAsync = ref.watch(jobAssignmentProvider(jobId));
    return assignmentAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (assignment) {
        if (assignment == null) return const SizedBox.shrink();
        return ElevatedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerLiveMapScreen(assignmentId: assignment.id))),
          icon: const Icon(Icons.location_on_rounded),
          label: const Text('TRACK LIVE LOCATION'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
        );
      },
    );
  }
}

class _RatingAction extends ConsumerWidget {
  const _RatingAction({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewAsync = ref.watch(jobReviewProvider(job.id));
    return reviewAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (review) {
        if (review != null) return PremiumCard(child: Text('Reviewed: ${review.rating} Stars'));
        return ElevatedButton.icon(
          onPressed: () => showDialog(context: context, builder: (_) => _SubmitReviewDialog(job: job)),
          icon: const Icon(Icons.star_rounded),
          label: const Text('RATE YOUR EXPERIENCE'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 56)),
        );
      },
    );
  }
}

class _SubmitReviewDialog extends ConsumerStatefulWidget {
  const _SubmitReviewDialog({required this.job});
  final Job job;
  @override
  ConsumerState<_SubmitReviewDialog> createState() => _SubmitReviewDialogState();
}

class _SubmitReviewDialogState extends ConsumerState<_SubmitReviewDialog> {
  int _rating = 5;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate Your Mover'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How was the move?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => IconButton(
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.orange,
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _comment,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Message (Optional)',
              hintText: 'Share your experience with this mover...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        FilledButton(
          onPressed: () async {
            final assignment = await ref.read(jobAssignmentProvider(widget.job.id).future);
            if (assignment == null) return;
            await ref.read(reviewRepositoryProvider).submitReview(Review(
                  id: '',
                  jobId: widget.job.id,
                  customerId: widget.job.customerId,
                  moverId: assignment.moverId,
                  rating: _rating,
                  comment: _comment.text,
                  createdAt: DateTime.now(),
                ));
            if (!context.mounted) return;
            Navigator.pop(context);
            ref.invalidate(jobReviewProvider(widget.job.id));
          },
          child: const Text('SUBMIT REVIEW'),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52),
            const SizedBox(height: 12),
            const Text(
              'Could not load request',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
