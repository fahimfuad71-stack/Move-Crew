import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/job.dart';
import '../data/models/job_item.dart';
import '../data/models/user.dart';
import '../data/repositories/admin_job_repository.dart';
import '../data/supabase_client.dart';

final adminJobRepositoryProvider = Provider<AdminJobRepository>((ref) {
  return AdminJobRepository(ref.watch(supabaseClientProvider));
});

final incomingAdminRequestsProvider = FutureProvider.autoDispose<List<Job>>((
  ref,
) {
  return ref.watch(adminJobRepositoryProvider).getIncomingRequests();
});

final adminRequestProvider = FutureProvider.autoDispose.family<Job, String>((
  ref,
  jobId,
) {
  return ref.watch(adminJobRepositoryProvider).getJobById(jobId);
});

final adminRequestItemsProvider = FutureProvider.autoDispose
    .family<List<JobItem>, String>((ref, jobId) {
      return ref.watch(adminJobRepositoryProvider).getJobItems(jobId);
    });

final adminCustomerProvider = FutureProvider.autoDispose
    .family<AppUser, String>((ref, customerId) {
      return ref.watch(adminJobRepositoryProvider).getCustomerById(customerId);
    });
