import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job.dart';
import '../models/assignment.dart';

class ActiveMonitoringInfo {
  final Job job;
  final Assignment assignment;
  final Map<String, dynamic>? latestLocation;

  ActiveMonitoringInfo({
    required this.job,
    required this.assignment,
    this.latestLocation,
  });
}

class AdminMonitoringRepository {
  final SupabaseClient _client;

  AdminMonitoringRepository(this._client);

  Future<List<ActiveMonitoringInfo>> getActiveMoves() async {
    // Fetch jobs that are IN_PROGRESS
    final response = await _client
        .from('jobs')
        .select('*, assignments!inner(*)')
        .eq('status', 'IN_PROGRESS')
        .eq('assignments.status', 'ACCEPTED');

    List<ActiveMonitoringInfo> activeMoves = [];

    for (var row in response) {
      final job = Job.fromMap(row);
      final assignmentMap = (row['assignments'] as List).first;
      final assignment = Assignment.fromMap(assignmentMap);

      // Get latest location for this assignment
      final locationResponse = await _client
          .from('mover_locations')
          .select()
          .eq('assignment_id', assignment.id)
          .order('recorded_at', ascending: false)
          .limit(1)
          .maybeSingle();

      activeMoves.add(ActiveMonitoringInfo(
        job: job,
        assignment: assignment,
        latestLocation: locationResponse,
      ));
    }

    return activeMoves;
  }
}
