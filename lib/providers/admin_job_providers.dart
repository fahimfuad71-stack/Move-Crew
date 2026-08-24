import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/job.dart';
import '../data/models/job_item.dart';
import '../data/models/user.dart';
import '../data/models/assignment.dart';
import '../data/repositories/admin_job_repository.dart';
import '../data/repositories/admin_monitoring_repository.dart';
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

final adminJobStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) {
  return ref.watch(adminJobRepositoryProvider).getJobStats();
});

final adminMonitoringRepositoryProvider = Provider<AdminMonitoringRepository>((ref) {
  return AdminMonitoringRepository(ref.watch(supabaseClientProvider));
});

final activeMovesProvider = FutureProvider.autoDispose<List<ActiveMonitoringInfo>>((ref) {
  return ref.watch(adminMonitoringRepositoryProvider).getActiveMoves();
});

final adminAllCustomersProvider = FutureProvider.autoDispose<List<AppUser>>((ref) {
  return ref.watch(adminJobRepositoryProvider).getAllCustomers();
});

final adminMoverHistoryProvider = FutureProvider.autoDispose.family<List<Assignment>, String>((ref, moverId) {
  return ref.watch(adminJobRepositoryProvider).getMoverWorkHistory(moverId);
});

final adminMoverTimeLogsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, moverId) {
  return ref.watch(adminJobRepositoryProvider).getMoverTimeLogs(moverId);
});

final adminCustomerHistoryProvider = FutureProvider.autoDispose.family<List<Job>, String>((ref, customerId) {
  return ref.watch(adminJobRepositoryProvider).getCustomerJobHistory(customerId);
});
