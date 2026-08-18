import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/assignment.dart';
import '../data/models/job.dart';
import '../data/models/mover_profile.dart';
import '../data/repositories/admin_assignment_repository.dart';
import '../data/supabase_client.dart';

final adminAssignmentRepositoryProvider = Provider<AdminAssignmentRepository>((
  ref,
) {
  return AdminAssignmentRepository(ref.watch(supabaseClientProvider));
});

final approvedJobsProvider = FutureProvider.autoDispose<List<Job>>((ref) {
  return ref.watch(adminAssignmentRepositoryProvider).getApprovedJobs();
});

final availableMoversProvider = FutureProvider.autoDispose<List<MoverProfile>>((
  ref,
) {
  return ref.watch(adminAssignmentRepositoryProvider).getMovers();
});

final jobAssignmentsProvider = FutureProvider.autoDispose
    .family<List<Assignment>, String>((ref, jobId) {
      return ref
          .watch(adminAssignmentRepositoryProvider)
          .getAssignmentsForJob(jobId);
    });
