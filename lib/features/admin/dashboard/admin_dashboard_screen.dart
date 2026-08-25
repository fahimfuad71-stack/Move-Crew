import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/status_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/sort_button.dart';
import '../../../core/widgets/job_status_chip.dart';
import '../../../data/models/job.dart';
import '../../../providers/admin_job_providers.dart';
import '../../../providers/admin_assignment_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/theme_provider.dart';
import '../request/incoming_request_details_screen.dart';
import '../assignment/assign_movers_screen.dart';
import '../monitoring/admin_monitoring_screen.dart';
import 'admin_job_list_screen.dart';
import '../management/admin_mover_list_screen.dart';
import '../management/admin_customer_list_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  SortOrder _sortOrder = SortOrder.descending;

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(incomingAdminRequestsProvider);
    final statsAsync = ref.watch(adminJobStatsProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MoveCrew Admin',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: isDark ? Colors.white : AppColors.obsidianDark,
              ),
            ),
            const Text(
              'Operations Overview',
              style: TextStyle(fontSize: 12, color: AppColors.stormyLight, letterSpacing: 1),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggle();
            },
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            tooltip: 'Live Monitoring',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminMonitoringScreen())),
            icon: const Icon(Icons.monitor_heart_rounded, color: AppColors.tealPrimary),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: const _AdminDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(incomingAdminRequestsProvider);
          ref.invalidate(adminJobStatsProvider);
          ref.invalidate(adminAssignedDashboardJobsProvider);
          ref.invalidate(adminRejectedJobsCountProvider);
          await Future.wait([
            ref.read(incomingAdminRequestsProvider.future),
            ref.read(adminJobStatsProvider.future),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: statsAsync.when(
                loading: () => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e')),
                data: (stats) => _StatsSection(stats: stats),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Incoming Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SortButton(currentOrder: _sortOrder, onChanged: (o) => setState(() => _sortOrder = o)),
                  ],
                ),
              ),
            ),
            requestsAsync.when(
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (error, _) => SliverFillRemaining(child: Center(child: Text(error.toString()))),
              data: (requests) {
                if (requests.isEmpty) {
                  return const SliverFillRemaining(child: _EmptyView());
                }

                final sorted = List<Job>.from(requests);
                sorted.sort((a, b) => _sortOrder == SortOrder.descending
                    ? b.createdAt.compareTo(a.createdAt)
                    : a.createdAt.compareTo(b.createdAt));

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _AdminRequestCard(job: sorted[index]),
                      childCount: sorted.length,
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Are you sure you want to sign out of MoveCrew Admin?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Sign Out')),
        ],
      ),
    );
    if (shouldLogout == true) await ref.read(authRepositoryProvider).signOut();
  }
}

class _StatsSection extends ConsumerWidget {
  const _StatsSection({required this.stats});
  final Map<String, int> stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rejectedCount = ref.watch(adminRejectedJobsCountProvider).value ?? 0;
    final totalAssigned = (stats['assigned'] ?? 0) + (stats['inProgress'] ?? 0);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              _ModernStatCard(
                label: 'REQUESTS',
                count: Text(
                  (stats['requested'] ?? 0).toString(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                color: AppColors.stormyLight,
                icon: Icons.inbox_rounded,
                onTap: () => _showJobsPopup(context, JobStatus.requested),
              ),
              const SizedBox(width: 12),
              _ModernStatCard(
                label: 'APPROVED',
                count: Text(
                  (stats['approved'] ?? 0).toString(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                color: AppColors.tealPrimary,
                icon: Icons.verified_rounded,
                onTap: () => _showJobsPopup(context, JobStatus.approved),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ModernStatCard(
                label: 'ASSIGNED',
                count: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    children: [
                      TextSpan(text: totalAssigned.toString()),
                      if (rejectedCount > 0)
                        TextSpan(
                          text: ' ($rejectedCount)',
                          style: const TextStyle(color: AppColors.crimsonRed),
                        ),
                    ],
                  ),
                ),
                color: AppColors.skyBlue,
                icon: Icons.local_shipping_rounded,
                onTap: () => _showJobsPopup(context, JobStatus.assigned),
              ),
              const SizedBox(width: 12),
              _ModernStatCard(
                label: 'COMPLETED',
                count: Text(
                  (stats['completed'] ?? 0).toString(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                color: AppColors.mintAccent,
                icon: Icons.check_circle_rounded,
                onTap: () => _showJobsPopup(context, JobStatus.completed),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignMoversScreen())),
            icon: const Icon(Icons.assignment_ind_rounded),
            label: const Text('MANAGE ASSIGNMENTS'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
          ),
        ],
      ),
    );
  }

  void _showJobsPopup(BuildContext context, JobStatus status) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _JobsListPopup(status: status),
    );
  }
}

class _JobsListPopup extends ConsumerWidget {
  const _JobsListPopup({required this.status});
  final JobStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If status is ASSIGNED, we show combined list of assigned and inProgress
    final jobsAsync = status == JobStatus.assigned 
        ? ref.watch(adminAssignedDashboardJobsProvider)
        : ref.watch(adminFilteredJobsProvider(status));
        
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${status == JobStatus.assigned ? 'ASSIGNED' : status.value.toUpperCase()} JOBS', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
              ),
              Expanded(
                child: jobsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (jobs) {
                    if (jobs.isEmpty) return const Center(child: Text('No jobs found.'));
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        final job = jobs[index];
                        return _PopupJobCard(job: job);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PopupJobCard extends ConsumerWidget {
  const _PopupJobCard({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(jobAssignmentsProvider(job.id));

    return PremiumCard(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => IncomingRequestDetailsScreen(jobId: job.id)));
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.jobCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(job.pickupAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          assignmentsAsync.when(
            data: (assignments) {
              final hasRejected = assignments.any((a) => a.status == AssignmentStatus.rejected);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasRejected)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: AssignmentStatusChip(status: AssignmentStatus.rejected),
                    ),
                  JobStatusChip(status: job.status),
                ],
              );
            },
            loading: () => JobStatusChip(status: job.status),
            error: (_, __) => JobStatusChip(status: job.status),
          ),
        ],
      ),
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  const _ModernStatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    this.onTap,
  });
  final String label;
  final Widget count;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PremiumCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            count,
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Theme.of(context).hintColor, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

class _AdminRequestCard extends StatelessWidget {
  const _AdminRequestCard({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => IncomingRequestDetailsScreen(jobId: job.id))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(job.jobCode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: const Text('NEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AdminInfoLine(icon: Icons.trip_origin_rounded, address: job.pickupAddress, label: 'FROM'),
          const SizedBox(height: 12),
          _AdminInfoLine(icon: Icons.location_on_rounded, address: job.destinationAddress, label: 'TO'),
          const Divider(height: 32),
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 16, color: Theme.of(context).hintColor),
              const SizedBox(width: 8),
              Text(job.moveDate.toString().split(' ')[0], style: TextStyle(color: Theme.of(context).hintColor)),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, color: AppColors.tealPrimary),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminInfoLine extends StatelessWidget {
  const _AdminInfoLine({required this.icon, required this.address, required this.label});
  final IconData icon;
  final String address;
  final String label;

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
              Text(address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminDrawer extends ConsumerWidget {
  const _AdminDrawer();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppColors.tealPrimary.withValues(alpha: 0.1)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: AppColors.tealPrimary,
                    child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.fullName ?? 'Admin', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const Text('System Administrator', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
          _DrawerItem(icon: Icons.dashboard_rounded, label: 'Dashboard', onTap: () => Navigator.pop(context)),
          _DrawerItem(icon: Icons.engineering_rounded, label: 'Manage Movers', onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMoverListScreen()));
          }),
          _DrawerItem(icon: Icons.people_alt_rounded, label: 'Manage Customers', onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCustomerListScreen()));
          }),
          const Divider(indent: 20, endIndent: 20),
          _DrawerItem(icon: Icons.archive_rounded, label: 'Job Archive', onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminJobListScreen()));
          }),
          const Spacer(),
          _DrawerItem(icon: Icons.logout_rounded, label: 'Logout', color: AppColors.crimsonRed, onTap: () {
            Navigator.pop(context);
            ref.read(authRepositoryProvider).signOut();
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({required this.icon, required this.label, required this.onTap, this.color});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.tealPrimary),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No new requests.'));
  }
}
