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

final moverProfileProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, moverId) async {
  final client = ref.watch(supabaseClientProvider);
  final user = await client.from('users').select().eq('id', moverId).single();
  final mover = await client.from('movers').select().eq('id', moverId).single();
  final rating = await client.from('mover_ratings').select().eq('mover_id', moverId).maybeSingle();
  
  return {
    'full_name': user['full_name'],
    'employee_code': mover['employee_code'],
    'avg_rating': rating?['avg_rating'] ?? 0.0,
    'total_reviews': rating?['total_reviews'] ?? 0,
  };
});

final moverTotalHoursProvider = FutureProvider.autoDispose<double>((ref) async {
  final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
  if (userId == null) return 0.0;
  
  final logs = await ref.watch(moverAssignmentRepositoryProvider).getMoverTimeLogs(userId);
  
  double total = 0;
  for (var log in logs) {
    if (log['clock_in_at'] != null && log['clock_out_at'] != null) {
      final inAt = DateTime.parse(log['clock_in_at']);
      final outAt = DateTime.parse(log['clock_out_at']);
      total += outAt.difference(inAt).inMinutes / 60.0;
    }
  }
  return total;
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
