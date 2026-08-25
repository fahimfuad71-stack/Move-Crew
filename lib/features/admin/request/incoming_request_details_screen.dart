import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/status_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/job_status_chip.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../data/models/job.dart';
import '../../../providers/admin_job_providers.dart';
import '../../../providers/theme_provider.dart';

class IncomingRequestDetailsScreen extends ConsumerStatefulWidget {
  const IncomingRequestDetailsScreen({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<IncomingRequestDetailsScreen> createState() => _IncomingRequestDetailsScreenState();
}

class _IncomingRequestDetailsScreenState extends ConsumerState<IncomingRequestDetailsScreen> {
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
                ? 'Approve ${job.jobCode}? The request will move to APPROVED status.'
                : 'Reject ${job.jobCode}? The request will move to REJECTED status.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: approve ? AppColors.tealPrimary : AppColors.crimsonRed,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(action),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _processing = true);

    try {
      final repository = ref.read(adminJobRepositoryProvider);
      approve ? await repository.approveRequest(job.id) : await repository.rejectRequest(job.id);

      ref.invalidate(incomingAdminRequestsProvider);
      ref.invalidate(adminRequestProvider(job.id));

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            icon: Icon(
              approve ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
              size: 48,
              color: approve ? AppColors.tealPrimary : AppColors.crimsonRed,
            ),
            title: Text(approve ? 'Request Approved' : 'Request Rejected'),
            content: Text('${job.jobCode} has been ${approve ? 'approved' : 'rejected'}.'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Done'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
    } finally {
      if (mounted) setState(() => _processing = false);
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
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Request', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: jobAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (job) {
          final customerAsync = ref.watch(adminCustomerProvider(job.customerId));
          final itemsAsync = ref.watch(adminRequestItemsProvider(job.id));

          return RefreshIndicator(
            onRefresh: () => _refresh(job),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                _HeaderCard(job: job),
                const SizedBox(height: 16),
                customerAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (user) => PremiumCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.tealPrimary.withOpacity(0.1),
                          child: const Icon(Icons.person_rounded, color: AppColors.tealPrimary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(user.phone ?? 'No phone', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('MOVE INFORMATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                PremiumCard(
                  child: Column(
                    children: [
                      _DetailRow(icon: Icons.trip_origin_rounded, label: 'PICKUP', value: job.pickupAddress),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                      _DetailRow(icon: Icons.location_on_rounded, label: 'DESTINATION', value: job.destinationAddress),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                      Row(
                        children: [
                          Expanded(child: _DetailRow(icon: Icons.calendar_today_rounded, label: 'DATE', value: job.moveDate.toString().split(' ')[0])),
                          Expanded(child: _DetailRow(icon: Icons.access_time_rounded, label: 'TIME', value: job.startTime)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('INSTRUCTIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                PremiumCard(
                  child: Text(
                    job.instructions == null || job.instructions!.trim().isEmpty ? 'No special instructions.' : job.instructions!,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('MOVING ITEMS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1.5)),
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
                const SizedBox(height: 32),
                if (job.status == JobStatus.requested)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _processing ? null : () => _review(job: job, approve: false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.crimsonRed),
                            foregroundColor: AppColors.crimsonRed,
                            minimumSize: const Size(0, 56),
                          ),
                          child: const Text('REJECT'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _processing ? null : () => _review(job: job, approve: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.tealPrimary,
                            minimumSize: const Size(0, 56),
                          ),
                          child: const Text('APPROVE'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      color: AppColors.tealPrimary.withValues(alpha: 0.1),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.tealPrimary, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.description_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.jobCode, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Status: ${job.status.value.toUpperCase()}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
              ],
            ),
          ),
          JobStatusChip(status: job.status),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});
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
              Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
