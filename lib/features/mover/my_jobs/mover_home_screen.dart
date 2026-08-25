import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/status_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/job_status_chip.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../data/models/assignment.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/mover_assignment_providers.dart';
import '../../../providers/theme_provider.dart';
import 'assignment_details_screen.dart';
import '../reviews/mover_reviews_screen.dart';
import '../history/mover_history_screen.dart';

class MoverHomeScreen extends ConsumerStatefulWidget {
  const MoverHomeScreen({super.key});

  @override
  ConsumerState<MoverHomeScreen> createState() => _MoverHomeScreenState();
}

class _MoverHomeScreenState extends ConsumerState<MoverHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(myMoverAssignmentsProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MoveCrew Mover',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: isDark ? Colors.white : AppColors.obsidianDark,
              ),
            ),
            const Text(
              'Job Dashboard',
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
            tooltip: 'My Reviews',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MoverReviewsScreen())),
            icon: const Icon(Icons.star_rounded, color: AppColors.tealPrimary),
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
      body: _currentIndex == 0 ? _TasksTab(assignmentsAsync: assignmentsAsync) : const MoverHistoryScreen(),
      bottomNavigationBar: _MoverBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Are you sure you want to sign out of MoveCrew Mover?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Sign Out')),
        ],
      ),
    );

    if (shouldLogout == true) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }
}

class _TasksTab extends ConsumerWidget {
  const _TasksTab({required this.assignmentsAsync});
  final AsyncValue<List<Assignment>> assignmentsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(myMoverAssignmentsProvider.future),
      child: assignmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(message: error.toString(), onRetry: () => ref.invalidate(myMoverAssignmentsProvider)),
        data: (assignments) {
          final activeAssignments = assignments.where((a) => a.status != AssignmentStatus.rejected).toList();
          if (activeAssignments.isEmpty) return const _EmptyView();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            itemCount: activeAssignments.length,
            itemBuilder: (context, index) => _AssignmentCard(assignment: activeAssignments[index]),
          );
        },
      ),
    );
  }
}

class _AssignmentCard extends ConsumerWidget {
  const _AssignmentCard({required this.assignment});
  final Assignment assignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(moverAssignedJobProvider(assignment.jobId));

    return jobAsync.when(
      loading: () => const PremiumCard(child: Center(child: CircularProgressIndicator())),
      error: (error, _) => PremiumCard(child: Text('Error: $error')),
      data: (job) => PremiumCard(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MoverAssignmentDetailsScreen(assignment: assignment))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(job.jobCode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                _StatusBadge(assignmentStatus: assignment.status, jobStatus: job.status),
              ],
            ),
            const SizedBox(height: 20),
            _AddressItem(icon: Icons.trip_origin_rounded, address: job.pickupAddress, label: 'PICKUP'),
            const Padding(
              padding: EdgeInsets.only(left: 11, top: 4, bottom: 4),
              child: SizedBox(height: 20, child: VerticalDivider(thickness: 2, width: 1)),
            ),
            _AddressItem(icon: Icons.location_on_rounded, address: job.destinationAddress, label: 'DESTINATION'),
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
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.assignmentStatus, required this.jobStatus});
  final AssignmentStatus assignmentStatus;
  final JobStatus jobStatus;

  @override
  Widget build(BuildContext context) {
    if (assignmentStatus == AssignmentStatus.pending) {
      return const AssignmentStatusChip(status: AssignmentStatus.pending);
    }
    return JobStatusChip(status: jobStatus);
  }
}

class _AddressItem extends StatelessWidget {
  const _AddressItem({required this.icon, required this.address, required this.label});
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
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Theme.of(context).hintColor, letterSpacing: 1)),
              Text(address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoverBottomNav extends StatelessWidget {
  const _MoverBottomNav({required this.currentIndex, required this.onTap});
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(30, 0, 30, 25),
      height: 65,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _MoverNavItem(icon: Icons.work_rounded, label: 'Jobs', isActive: currentIndex == 0, onTap: () => onTap(0)),
          _MoverNavItem(icon: Icons.history_rounded, label: 'History', isActive: currentIndex == 1, onTap: () => onTap(1)),
        ],
      ),
    );
  }
}

class _MoverNavItem extends StatelessWidget {
  const _MoverNavItem({required this.icon, required this.label, required this.isActive, required this.onTap});
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
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
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
          Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('All clear!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('New jobs will appear here.', style: TextStyle(color: Colors.grey)),
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
            const Icon(Icons.error_outline_rounded, size: 50, color: AppColors.crimsonRed),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
