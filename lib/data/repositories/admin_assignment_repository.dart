import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/status_enums.dart';
import '../models/assignment.dart';
import '../models/job.dart';
import '../models/mover_profile.dart';

class AdminAssignResult {
  const AdminAssignResult({
    required this.jobId,
    required this.jobCode,
    required this.assignedCount,
    required this.newStatus,
  });

  final String jobId;
  final String jobCode;
  final int assignedCount;
  final JobStatus newStatus;
}

class AdminAssignmentRepository {
  const AdminAssignmentRepository(this._client);

  final SupabaseClient _client;

  // -------------------------------------------------------
  // APPROVED JOBS WAITING FOR ASSIGNMENT
  // -------------------------------------------------------

  Future<List<Job>> getApprovedJobs() async {
    final response = await _client
        .from('jobs')
        .select()
        .inFilter('status', ['APPROVED', 'ASSIGNED'])
        .order('created_at', ascending: false);

    return response.map((row) => Job.fromMap(row)).toList();
  }

  // -------------------------------------------------------
  // LOAD ALL MOVERS
  // -------------------------------------------------------

  Future<List<MoverProfile>> getMovers() async {
    final moverRows = await _client
        .from('movers')
        .select()
        .order('employee_code', ascending: true);

    if (moverRows.isEmpty) {
      return [];
    }

    final moverIds = moverRows.map((row) => row['id'] as String).toList();

    final userRows = await _client
        .from('users')
        .select()
        .inFilter('id', moverIds);

    final usersById = <String, Map<String, dynamic>>{};

    for (final row in userRows) {
      usersById[row['id'] as String] = Map<String, dynamic>.from(row);
    }

    final movers = <MoverProfile>[];

    for (final moverRow in moverRows) {
      final mover = Map<String, dynamic>.from(moverRow);

      final id = mover['id'] as String;

      final user = usersById[id];

      if (user == null) {
        continue;
      }

      movers.add(MoverProfile.fromMaps(mover: mover, user: user));
    }

    return movers;
  }

  // -------------------------------------------------------
  // ASSIGN MOVERS
  // -------------------------------------------------------

  Future<AdminAssignResult> assignMovers({
    required String jobId,
    required List<String> moverIds,
  }) async {
    if (moverIds.isEmpty) {
      throw ArgumentError('Select at least one mover.');
    }

    final response = await _client.rpc(
      'admin_assign_movers',
      params: {'p_job_id': jobId, 'p_mover_ids': moverIds},
    );

    if (response is! List || response.isEmpty) {
      throw StateError('Assignment completed but no result was returned.');
    }

    final firstRow = response.first;

    if (firstRow is! Map) {
      throw StateError('Invalid response from admin_assign_movers.');
    }

    final row = Map<String, dynamic>.from(firstRow);

    return AdminAssignResult(
      jobId: row['job_id'] as String,
      jobCode: row['job_code'] as String,
      assignedCount: (row['assigned_count'] as num).toInt(),
      newStatus: JobStatus.fromString(row['new_status'] as String),
    );
  }

  // -------------------------------------------------------
  // ASSIGNMENTS FOR ONE JOB
  // -------------------------------------------------------

  Future<List<Assignment>> getAssignmentsForJob(String jobId) async {
    final response = await _client
        .from('assignments')
        .select()
        .eq('job_id', jobId);

    return response.map((row) => Assignment.fromMap(row)).toList();
  }
}
