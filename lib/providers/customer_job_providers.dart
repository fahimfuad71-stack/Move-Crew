import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/assignment.dart';
import '../data/models/job.dart';
import '../data/models/job_item.dart';
import '../data/repositories/customer_job_repository.dart';
import '../data/supabase_client.dart';

final customerJobRepositoryProvider = Provider<CustomerJobRepository>((ref) {
  return CustomerJobRepository(ref.watch(supabaseClientProvider));
});

final myJobsProvider = FutureProvider.autoDispose<List<Job>>((ref) {
  return ref.watch(customerJobRepositoryProvider).getMyJobs();
});

final jobProvider = FutureProvider.autoDispose.family<Job, String>((
  ref,
  jobId,
) {
  return ref.watch(customerJobRepositoryProvider).getJobById(jobId);
});

final jobItemsProvider = FutureProvider.autoDispose
    .family<List<JobItem>, String>((ref, jobId) {
      return ref.watch(customerJobRepositoryProvider).getJobItems(jobId);
    });

final jobAssignmentProvider = FutureProvider.autoDispose
    .family<Assignment?, String>((ref, jobId) {
      return ref.watch(customerJobRepositoryProvider).getJobAssignment(jobId);
    });
