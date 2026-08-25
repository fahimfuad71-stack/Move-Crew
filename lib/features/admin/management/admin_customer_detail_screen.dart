import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/status_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/job_status_chip.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../data/models/job.dart';
import '../../../data/models/user.dart';
import '../../../providers/admin_job_providers.dart';
import '../../../providers/theme_provider.dart';
import '../request/incoming_request_details_screen.dart';

class AdminCustomerDetailScreen extends ConsumerWidget {
  const AdminCustomerDetailScreen({super.key, required this.customer});
  final AppUser customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(adminCustomerHistoryProvider(customer.id));
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: PremiumCard(
                color: AppColors.crimsonRed,
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person_rounded, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(customer.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(customer.phone ?? 'No phone number', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text('CLIENT ID: ${customer.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('REQUEST HISTORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1.5)),
              ),
            ),
            historyAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
              error: (e, s) => Center(child: Text('Error: $e')),
              data: (jobs) {
                if (jobs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No requests yet.')));

                final active = jobs.where((j) => [JobStatus.approved, JobStatus.assigned, JobStatus.inProgress].contains(j.status)).toList();
                final requested = jobs.where((j) => j.status == JobStatus.requested).toList();
                final completed = jobs.where((j) => j.status == JobStatus.completed).toList();
                final rejected = jobs.where((j) => [JobStatus.rejected, JobStatus.cancelled].contains(j.status)).toList();

                return ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    if (active.isNotEmpty) ...[
                      _buildSectionHeader('Active Moves'),
                      ...active.map((j) => _CustomerJobCard(job: j)),
                      const SizedBox(height: 16),
                    ],
                    if (requested.isNotEmpty) ...[
                      _buildSectionHeader('Pending Requests'),
                      ...requested.map((j) => _CustomerJobCard(job: j)),
                      const SizedBox(height: 16),
                    ],
                    if (completed.isNotEmpty) ...[
                      _buildSectionHeader('Completed'),
                      ...completed.map((j) => _CustomerJobCard(job: j)),
                      const SizedBox(height: 16),
                    ],
                    if (rejected.isNotEmpty) ...[
                      _buildSectionHeader('Rejected / Cancelled'),
                      ...rejected.map((j) => _CustomerJobCard(job: j)),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _CustomerJobCard extends StatelessWidget {
  const _CustomerJobCard({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => IncomingRequestDetailsScreen(jobId: job.id)));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(job.jobCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              JobStatusChip(status: job.status),
            ],
          ),
          const SizedBox(height: 16),
          _RouteItem(icon: Icons.trip_origin_rounded, address: job.pickupAddress, label: 'FROM'),
          const SizedBox(height: 8),
          _RouteItem(icon: Icons.location_on_rounded, address: job.destinationAddress, label: 'TO'),
          const Divider(height: 32),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text('${job.createdAt.day}/${job.createdAt.month}/${job.createdAt.year}', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteItem extends StatelessWidget {
  const _RouteItem({required this.icon, required this.address, required this.label});
  final IconData icon;
  final String address;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.tealPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
