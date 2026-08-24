import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/status_enums.dart';
import '../../../core/widgets/job_status_chip.dart';
import '../../../core/widgets/sort_button.dart';
import '../../../data/models/job.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/customer_job_providers.dart';
import '../request/create_request_screen.dart';
import '../request/job_details_screen.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  SortOrder _sortOrder = SortOrder.descending;

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(myJobsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text(
            'MoveCrew Customer',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active Requests'),
              Tab(text: 'Move History'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Logout',
              onPressed: () => _confirmLogout(context, ref),
              icon: const Icon(Icons.logout_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(myJobsProvider);
                await ref.read(myJobsProvider.future);
              },
              child: jobsAsync.when(
                loading: () => const _LoadingView(),
                error: (error, stackTrace) => _ErrorView(
                  message: error.toString(),
                  onRetry: () {
                    ref.invalidate(myJobsProvider);
                  },
                ),
                data: (jobs) {
                  final activeJobs = jobs.where((j) => j.status != JobStatus.completed && j.status != JobStatus.rejected).toList();
                  if (activeJobs.isEmpty) {
                    return const _EmptyView();
                  }
                  return _JobList(jobs: activeJobs);
                },
              ),
            ),
            RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(myJobsProvider);
                await ref.read(myJobsProvider.future);
              },
              child: jobsAsync.when(
                loading: () => const _LoadingView(),
                error: (error, stackTrace) => _ErrorView(
                  message: error.toString(),
                  onRetry: () {
                    ref.invalidate(myJobsProvider);
                  },
                ),
                data: (jobs) {
                  final historyJobs = jobs.where((j) => j.status == JobStatus.completed || j.status == JobStatus.rejected).toList();
                  if (historyJobs.isEmpty) {
                    return const Center(child: Text('No move history yet.'));
                  }

                  final sorted = List<Job>.from(historyJobs);
                  if (_sortOrder == SortOrder.descending) {
                    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  } else {
                    sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                      Expanded(child: _JobList(jobs: sorted)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF1E56A0),
          foregroundColor: Colors.white,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CreateRequestScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Request'),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text('Are you sure you want to sign out of MoveCrew?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await ref.read(authRepositoryProvider).signOut();
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.error_outline_rounded, size: 56),
        const SizedBox(height: 16),
        const Text(
          'Could not load requests',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF5C6470)),
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: const [
        SizedBox(height: 170),
        Icon(Icons.local_shipping_outlined, size: 72, color: Color(0xFF9AA5B1)),
        SizedBox(height: 20),
        Text(
          'No move requests yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1E23),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Create your first moving request using the New Request button.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF5C6470)),
        ),
      ],
    );
  }
}

class _JobList extends StatelessWidget {
  const _JobList({required this.jobs});

  final List<Job> jobs;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _JobCard(job: jobs[index]);
      },
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E5EA)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CustomerJobDetailsScreen(jobId: job.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.jobCode,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1E23),
                      ),
                    ),
                  ),
                  JobStatusChip(status: job.status),
                ],
              ),
              const SizedBox(height: 16),
              _AddressRow(
                icon: Icons.trip_origin_rounded,
                label: 'Pickup',
                address: job.pickupAddress,
              ),
              const SizedBox(height: 12),
              _AddressRow(
                icon: Icons.location_on_outlined,
                label: 'Destination',
                address: job.destinationAddress,
              ),
              const Divider(height: 28),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Color(0xFF5C6470),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(job.moveDate),
                    style: const TextStyle(color: Color(0xFF5C6470)),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: Color(0xFF5C6470),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(job.startTime),
                    style: const TextStyle(color: Color(0xFF5C6470)),
                  ),
                ],
              ),
            ],
          ),
        ),
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

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.icon,
    required this.label,
    required this.address,
  });

  final IconData icon;
  final String label;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1E56A0)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF5C6470)),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1E23),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

