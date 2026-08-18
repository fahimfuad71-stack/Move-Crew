import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/admin_mover_assignment.dart';
import '../data/repositories/admin_assignment_status_repository.dart';
import '../data/supabase_client.dart';

final adminAssignmentStatusRepositoryProvider =
    Provider<AdminAssignmentStatusRepository>((ref) {
      return AdminAssignmentStatusRepository(ref.watch(supabaseClientProvider));
    });

final adminMoverAssignmentsProvider = FutureProvider.autoDispose
    .family<List<AdminMoverAssignment>, String>((ref, jobId) {
      return ref
          .watch(adminAssignmentStatusRepositoryProvider)
          .getMoverAssignmentsForJob(jobId);
    });
