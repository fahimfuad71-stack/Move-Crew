import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/status_enums.dart';
import '../../../data/models/job.dart';
import '../../../data/models/job_item.dart';
import '../../../providers/review_providers.dart';
import '../../../providers/customer_job_providers.dart';
import '../../../data/models/review.dart';
import '../tracking/customer_live_map_screen.dart';

class CustomerJobDetailsScreen extends ConsumerWidget {
  const CustomerJobDetailsScreen({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobProvider(jobId));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Request Details',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: jobAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorView(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(jobProvider(jobId));
          },
        ),
        data: (job) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(jobProvider(jobId));

              ref.invalidate(jobItemsProvider(jobId));

              await Future.wait([
                ref.read(jobProvider(jobId).future),
                ref.read(jobItemsProvider(jobId).future),
              ]);
            },
            child: _JobDetailsContent(job: job),
          );
        },
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _HeaderCard(job: job),
        if (job.status == JobStatus.assigned || job.status == JobStatus.inProgress) ...[
          const SizedBox(height: 16),
          _TrackMoverButton(jobId: job.id),
        ],
        if (job.status == JobStatus.completed) ...[
          const SizedBox(height: 16),
          _RatingSection(job: job),
        ],
        const SizedBox(height: 16),

        _SectionCard(
          title: 'Move Information',
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.trip_origin_rounded,
                label: 'Pickup',
                value: job.pickupAddress,
              ),
              const Divider(height: 28),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Destination',
                value: job.destinationAddress,
              ),
              const Divider(height: 28),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Move Date',
                value: _formatDate(job.moveDate),
              ),
              const Divider(height: 28),
              _InfoRow(
                icon: Icons.access_time_rounded,
                label: 'Start Time',
                value: _formatTime(job.startTime),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        _SectionCard(
          title: 'Instructions',
          child: Text(
            job.instructions == null || job.instructions!.trim().isEmpty
                ? 'No special instructions provided.'
                : job.instructions!,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF1A1E23),
            ),
          ),
        ),

        const SizedBox(height: 16),

        _SectionCard(
          title: 'Moving Items',
          child: itemsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => Column(
              children: [
                const Icon(Icons.error_outline, size: 36),
                const SizedBox(height: 8),
                Text(
                  'Could not load items.\n$error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.invalidate(jobItemsProvider(job.id));
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Text('No items found for this request.');
              }

              return Column(
                children: List.generate(items.length, (index) {
                  final item = items[index];

                  return Column(
                    children: [
                      _ItemRow(item: item),
                      if (index < items.length - 1) const Divider(height: 24),
                    ],
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  static String _formatTime(String time) {
    final parts = time.split(':');

    if (parts.length < 2) {
      return time;
    }

    final hour = int.tryParse(parts[0]);

    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return time;
    }

    final suffix = hour >= 12 ? 'PM' : 'AM';

    final displayHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;

    return '$displayHour:'
        '${minute.toString().padLeft(2, '0')} '
        '$suffix';
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E5EA)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFD7E6F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: Color(0xFF1E56A0),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.jobCode,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Created ${_formatCreatedDate(job.createdAt)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5C6470),
                  ),
                ),
              ],
            ),
          ),
          _StatusChip(status: job.status),
        ],
      ),
    );
  }

  static String _formatCreatedDate(DateTime date) {
    return '${date.day}/'
        '${date.month}/'
        '${date.year}';
  }
}

class _TrackMoverButton extends ConsumerWidget {
  const _TrackMoverButton({required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentAsync = ref.watch(jobAssignmentProvider(jobId));

    return assignmentAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
      data: (assignment) {
        if (assignment == null) return const SizedBox.shrink();

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerLiveMapScreen(
                    assignmentId: assignment.id,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.map_outlined),
            label: const Text('Track Mover Live'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E56A0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RatingSection extends ConsumerWidget {
  const _RatingSection({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewAsync = ref.watch(jobReviewProvider(job.id));

    return reviewAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
      data: (review) {
        if (review != null) {
          return _SectionCard(
            title: 'Your Review',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                    );
                  }),
                ),
                if (review.comment != null && review.comment!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    review.comment!,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE7F3FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E56A0)),
          ),
          child: Column(
            children: [
              const Text(
                'How was your move?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E56A0),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Share your feedback and rate your mover.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _showReviewDialog(context, ref),
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Rate Mover'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReviewDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _SubmitReviewDialog(job: job),
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
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    try {
      final assignmentAsync = await ref.read(jobAssignmentProvider(widget.job.id).future);
      if (assignmentAsync == null) throw Exception('Mover not found');

      final review = Review(
        id: '',
        jobId: widget.job.id,
        customerId: widget.job.customerId,
        moverId: assignmentAsync.moverId,
        rating: _rating,
        comment: _commentController.text,
        createdAt: DateTime.now(),
      );

      await ref.read(reviewRepositoryProvider).submitReview(review);

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(jobReviewProvider(widget.job.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate Mover'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _rating = index + 1),
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                    size: 32,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: const Color(0xFF1E56A0)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF5C6470)),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final JobItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.inventory_2_outlined, color: Color(0xFF1E56A0)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '× ${item.quantity}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 12),
        _ItemStatusChip(status: item.status),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: config.$2.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        config.$1,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: config.$2,
        ),
      ),
    );
  }

  (String, Color) _statusConfig(JobStatus status) {
    switch (status) {
      case JobStatus.requested:
        return ('Requested', const Color(0xFF9AA5B1));
      case JobStatus.approved:
        return ('Approved', const Color(0xFF2E9E5B));
      case JobStatus.assigned:
        return ('Assigned', const Color(0xFF1E7FCB));
      case JobStatus.inProgress:
        return ('In Progress', const Color(0xFF1E7FCB));
      case JobStatus.completed:
        return ('Completed', const Color(0xFF0F9D58));
      case JobStatus.rejected:
        return ('Rejected', const Color(0xFFD64545));
    }
  }
}

class _ItemStatusChip extends StatelessWidget {
  const _ItemStatusChip({required this.status});

  final JobItemStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      JobItemStatus.pending => 'Pending',
      JobItemStatus.collected => 'Collected',
      JobItemStatus.delivered => 'Delivered',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF9AA5B1).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF5C6470)),
      ),
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
