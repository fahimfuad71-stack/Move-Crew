import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/status_enums.dart';
import '../../../core/widgets/job_status_chip.dart';
import '../../../data/models/job.dart';
import '../../../data/models/user.dart';
import '../../../providers/admin_job_providers.dart';
import '../request/incoming_request_details_screen.dart';

class AdminCustomerDetailScreen extends ConsumerWidget {
  const AdminCustomerDetailScreen({super.key, required this.customer});
  final AppUser customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(adminCustomerHistoryProvider(customer.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(customer.fullName),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              width: double.infinity,
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFFFFEBEE),
                    child: Icon(Icons.person, size: 50, color: Colors.redAccent),
                  ),
                  const SizedBox(height: 16),
                  Text(customer.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(customer.phone ?? 'No phone number', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('Customer ID: ${customer.id.substring(0, 8)}...', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Request History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            historyAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
              error: (e, s) => Center(child: Text('Error: $e')),
              data: (jobs) {
                if (jobs.isEmpty) return const Center(child: Text('No requests yet.'));

                final active = jobs.where((j) => [JobStatus.approved, JobStatus.assigned, JobStatus.inProgress].contains(j.status)).toList();
                final requested = jobs.where((j) => j.status == JobStatus.requested).toList();
                final completed = jobs.where((j) => j.status == JobStatus.completed).toList();
                final rejected = jobs.where((j) => [JobStatus.rejected, JobStatus.cancelled].contains(j.status)).toList();

                return ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (active.isNotEmpty) ...[
                      _buildSectionHeader('Active Moves'),
                      ...active.map((j) => _CustomerJobCard(job: j)),
                      const SizedBox(height: 24),
                    ],
                    if (requested.isNotEmpty) ...[
                      _buildSectionHeader('Pending Requests'),
                      ...requested.map((j) => _CustomerJobCard(job: j)),
                      const SizedBox(height: 24),
                    ],
                    if (completed.isNotEmpty) ...[
                      _buildSectionHeader('Completed History'),
                      ...completed.map((j) => _CustomerJobCard(job: j)),
                      const SizedBox(height: 24),
                    ],
                    if (rejected.isNotEmpty) ...[
                      _buildSectionHeader('Rejected / Cancelled'),
                      ...rejected.map((j) => _CustomerJobCard(job: j)),
                    ],
                  ],
                );
              },
            ),
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
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5C6470)),
      ),
    );
  }
}

class _CustomerJobCard extends StatelessWidget {
  const _CustomerJobCard({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E5EA))),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => IncomingRequestDetailsScreen(jobId: job.id)));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(job.jobCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  JobStatusChip(status: job.status),
                ],
              ),
              const SizedBox(height: 8),
              Text('Pickup: ${job.pickupAddress}', style: const TextStyle(fontSize: 13)),
              Text('Destination: ${job.destinationAddress}', style: const TextStyle(fontSize: 13)),
              const Divider(),
              Text('Requested on: ${job.createdAt.day}/${job.createdAt.month}/${job.createdAt.year}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
