import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/status_enums.dart';
import '../../../data/models/job.dart';
import '../../../data/models/job_item.dart';
import '../../../providers/admin_job_providers.dart';

class IncomingRequestDetailsScreen extends ConsumerStatefulWidget {
  const IncomingRequestDetailsScreen({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<IncomingRequestDetailsScreen> createState() =>
      _IncomingRequestDetailsScreenState();
}

class _IncomingRequestDetailsScreenState
    extends ConsumerState<IncomingRequestDetailsScreen> {
  bool _processing = false;

  Future<void> _review({required Job job, required bool approve}) async {
    final action = approve ? 'Approve' : 'Reject';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('$action request?'),
          content: Text(
            approve
                ? 'Approve ${job.jobCode}? '
                      'The request will move to APPROVED status.'
                : 'Reject ${job.jobCode}? '
                      'The request will move to REJECTED status.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: approve
                    ? const Color(0xFF2E9E5B)
                    : const Color(0xFFD64545),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(action),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      final repository = ref.read(adminJobRepositoryProvider);

      final result = approve
          ? await repository.approveRequest(job.id)
          : await repository.rejectRequest(job.id);

      ref.invalidate(incomingAdminRequestsProvider);

      ref.invalidate(adminRequestProvider(job.id));

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            icon: Icon(
              approve
                  ? Icons.check_circle_outline_rounded
                  : Icons.cancel_outlined,
              size: 48,
              color: approve
                  ? const Color(0xFF2E9E5B)
                  : const Color(0xFFD64545),
            ),
            title: Text(approve ? 'Request Approved' : 'Request Rejected'),
            content: Text(
              '${result.jobCode} is now '
              '${result.newStatus.value}.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not review request: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  Future<void> _refresh(Job job) async {
    ref.invalidate(adminRequestProvider(job.id));

    ref.invalidate(adminRequestItemsProvider(job.id));

    ref.invalidate(adminCustomerProvider(job.customerId));

    await ref.read(adminRequestProvider(job.id).future);
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(adminRequestProvider(widget.jobId));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Incoming Request',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: jobAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorView(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(adminRequestProvider(widget.jobId));
          },
        ),
        data: (job) {
          final customerAsync = ref.watch(
            adminCustomerProvider(job.customerId),
          );

          final itemsAsync = ref.watch(adminRequestItemsProvider(job.id));

          return RefreshIndicator(
            onRefresh: () => _refresh(job),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _HeaderCard(job: job),

                const SizedBox(height: 16),

                _SectionCard(
                  title: 'Customer',
                  child: customerAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) =>
                        Text('Could not load customer: $error'),
                    data: (customer) {
                      final phone = customer.phone?.trim();

                      return Column(
                        children: [
                          _InfoRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Name',
                            value: customer.fullName,
                          ),
                          const Divider(height: 28),
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: phone == null || phone.isEmpty
                                ? 'Not provided'
                                : phone,
                          ),
                        ],
                      );
                    },
                  ),
                ),

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
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ),

                const SizedBox(height: 16),

                _SectionCard(
                  title: 'Moving Items',
                  child: itemsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) =>
                        Text('Could not load items: $error'),
                    data: (items) {
                      if (items.isEmpty) {
                        return const Text('No items found.');
                      }

                      return Column(
                        children: List.generate(items.length, (index) {
                          final item = items[index];

                          return Column(
                            children: [
                              _ItemRow(item: item),
                              if (index < items.length - 1)
                                const Divider(height: 24),
                            ],
                          );
                        }),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                if (job.status == JobStatus.requested)
                  _ReviewActions(
                    processing: _processing,
                    onApprove: () => _review(job: job, approve: true),
                    onReject: () => _review(job: job, approve: false),
                  )
                else
                  _AlreadyReviewed(status: job.status),
              ],
            ),
          );
        },
      ),
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

class _ReviewActions extends StatelessWidget {
  const _ReviewActions({
    required this.processing,
    required this.onApprove,
    required this.onReject,
  });

  final bool processing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD64545),
              minimumSize: const Size(0, 52),
            ),
            onPressed: processing ? null : onReject,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Reject'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E9E5B),
              minimumSize: const Size(0, 52),
            ),
            onPressed: processing ? null : onApprove,
            icon: processing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(processing ? 'Processing...' : 'Approve'),
          ),
        ),
      ],
    );
  }
}

class _AlreadyReviewed extends StatelessWidget {
  const _AlreadyReviewed({required this.status});

  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E5EA)),
      ),
      child: Text(
        'This request has already been reviewed. '
        'Current status: ${status.value}',
        textAlign: TextAlign.center,
      ),
    );
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
            child: Text(
              job.jobCode,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          _StatusChip(status: job.status),
        ],
      ),
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
        Icon(icon, color: const Color(0xFF1E56A0)),
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
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '× ${item.quantity}',
          style: const TextStyle(fontWeight: FontWeight.w600),
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
            const Icon(Icons.error_outline_rounded, size: 52),
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
