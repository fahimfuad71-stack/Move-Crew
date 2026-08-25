import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/status_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/job_status_chip.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/sort_button.dart';
import '../../../data/models/job.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/customer_job_providers.dart';
import '../../../providers/theme_provider.dart';
import '../request/create_request_screen.dart';
import '../request/job_details_screen.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  SortOrder _sortOrder = SortOrder.descending;
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(myJobsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MoveCrew',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: isDark ? Colors.white : AppColors.obsidianDark,
              ),
            ),
            Text(
              'Premium Moving Services',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
                letterSpacing: 0.5,
              ),
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
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _currentIndex == 0
          ? _ActiveRequestsTab(jobsAsync: jobsAsync)
          : _HistoryTab(jobsAsync: jobsAsync, sortOrder: _sortOrder, onSortChanged: (o) => setState(() => _sortOrder = o)),
      bottomNavigationBar: _PremiumBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.tealPrimary,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CreateRequestScreen(),
            ),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }
}

class _ActiveRequestsTab extends ConsumerWidget {
  const _ActiveRequestsTab({required this.jobsAsync});
  final AsyncValue<List<Job>> jobsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(myJobsProvider.future),
      child: jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(message: error.toString(), onRetry: () => ref.invalidate(myJobsProvider)),
        data: (jobs) {
          final activeJobs = jobs.where((j) => j.status != JobStatus.completed && j.status != JobStatus.rejected).toList();
          if (activeJobs.isEmpty) return const _EmptyView();
          return _JobList(jobs: activeJobs);
        },
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab({required this.jobsAsync, required this.sortOrder, required this.onSortChanged});
  final AsyncValue<List<Job>> jobsAsync;
  final SortOrder sortOrder;
  final Function(SortOrder) onSortChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(myJobsProvider.future),
      child: jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(message: error.toString(), onRetry: () => ref.invalidate(myJobsProvider)),
        data: (jobs) {
          final historyJobs = jobs.where((j) => j.status == JobStatus.completed || j.status == JobStatus.rejected).toList();
          if (historyJobs.isEmpty) return const Center(child: Text('No move history yet.'));

          final sorted = List<Job>.from(historyJobs);
          sorted.sort((a, b) => sortOrder == SortOrder.descending
              ? b.createdAt.compareTo(a.createdAt)
              : a.createdAt.compareTo(b.createdAt));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Move History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SortButton(currentOrder: sortOrder, onChanged: onSortChanged),
                  ],
                ),
              ),
              Expanded(child: _JobList(jobs: sorted)),
            ],
          );
        },
      ),
    );
  }
}

class _PremiumBottomNav extends StatelessWidget {
  const _PremiumBottomNav({required this.currentIndex, required this.onTap});
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      height: 70,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          const SizedBox(width: 40), // Space for FAB
          _NavItem(
            icon: Icons.history_rounded,
            label: 'History',
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.isActive, required this.onTap});
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.tealPrimary : Colors.grey;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class _JobList extends StatelessWidget {
  const _JobList({required this.jobs});
  final List<Job> jobs;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
      itemCount: jobs.length,
      itemBuilder: (context, index) => _JobCard(job: jobs[index]),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CustomerJobDetailsScreen(jobId: job.id))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(job.jobCode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              JobStatusChip(status: job.status),
            ],
          ),
          const SizedBox(height: 20),
          _LocationRow(icon: Icons.trip_origin_rounded, address: job.pickupAddress, label: 'PICKUP'),
          const Padding(
            padding: EdgeInsets.only(left: 11, top: 4, bottom: 4),
            child: SizedBox(height: 20, child: VerticalDivider(thickness: 2, width: 1)),
          ),
          _LocationRow(icon: Icons.location_on_rounded, address: job.destinationAddress, label: 'DESTINATION'),
          const Divider(height: 32),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 16, color: Theme.of(context).hintColor),
              const SizedBox(width: 8),
              Text(job.moveDate.toString().split(' ')[0], style: TextStyle(color: Theme.of(context).hintColor)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.tealPrimary),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.icon, required this.address, required this.label});
  final IconData icon;
  final String address;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.tealPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1)),
              Text(address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined, size: 100, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 24),
          const Text('No move requests yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Your next move starts here.', style: TextStyle(color: Colors.grey)),
        ],
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.crimsonRed),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

