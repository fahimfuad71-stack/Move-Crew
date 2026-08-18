import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/assignment.dart';
import '../data/models/job.dart';
import '../data/models/job_item.dart';
import '../data/repositories/mover_assignment_repository.dart';
import '../data/supabase_client.dart';

final moverAssignmentRepositoryProvider = Provider<MoverAssignmentRepository>((
  ref,
) {
  return MoverAssignmentRepository(ref.watch(supabaseClientProvider));
});

final myMoverAssignmentsProvider = FutureProvider.autoDispose<List<Assignment>>(
  (ref) {
    return ref.watch(moverAssignmentRepositoryProvider).getMyAssignments();
  },
);

final moverAssignedJobProvider = FutureProvider.autoDispose.family<Job, String>(
  (ref, jobId) {
    return ref.watch(moverAssignmentRepositoryProvider).getAssignedJob(jobId);
  },
);

final moverAssignedJobItemsProvider = FutureProvider.autoDispose
    .family<List<JobItem>, String>((ref, jobId) {
      return ref
          .watch(moverAssignmentRepositoryProvider)
          .getAssignedJobItems(jobId);
    });
