import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job.dart';
import '../models/assignment.dart';

class ActiveMonitoringInfo {
  final Job job;
  final Assignment assignment;
  final Map<String, dynamic>? latestLocation;
  final String moverName;
  final String employeeCode;

  ActiveMonitoringInfo({
    required this.job,
    required this.assignment,
    this.latestLocation,
    required this.moverName,
    required this.employeeCode,
  });
}

class AdminMonitoringRepository {
  final SupabaseClient _client;

  AdminMonitoringRepository(this._client);

  Future<List<ActiveMonitoringInfo>> getActiveMoves() async {
    // Fetch all accepted assignments for jobs that are IN_PROGRESS
    final response = await _client
        .from('assignments')
        .select('*, jobs!inner(*), movers!inner(employee_code, users!inner(full_name))')
        .eq('jobs.status', 'IN_PROGRESS')
        .eq('status', 'ACCEPTED');

    List<ActiveMonitoringInfo> activeMoves = [];

    for (var row in response) {
      final assignment = Assignment.fromMap(row);
      final job = assignment.job;
      
      if (job == null) continue;

      final moverMap = row['movers'] as Map<String, dynamic>?;
      final moverName = moverMap?['users']?['full_name'] as String? ?? 'Unknown Mover';
      final employeeCode = moverMap?['employee_code'] as String? ?? '';

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
        moverName: moverName,
        employeeCode: employeeCode,
      ));
    }

    return activeMoves;
  }
}
