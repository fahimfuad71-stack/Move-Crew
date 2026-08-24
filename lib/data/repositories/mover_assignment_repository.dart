import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/status_enums.dart';
import '../models/assignment.dart';
import '../models/job.dart';
import '../models/job_item.dart';

class MoverResponseResult {
  const MoverResponseResult({
    required this.assignmentId,
    required this.jobId,
    required this.newStatus,
    required this.respondedAt,
  });

  final String assignmentId;
  final String jobId;
  final AssignmentStatus newStatus;
  final DateTime respondedAt;
}

class MoverAssignmentRepository {
  const MoverAssignmentRepository(this._client);

  final SupabaseClient _client;

  // -------------------------------------------------------
  // CURRENT MOVER ASSIGNMENTS
  // -------------------------------------------------------

  Future<List<Assignment>> getMyAssignments() async {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      throw StateError('Authentication required.');
    }

    final response = await _client
        .from('assignments')
        .select('*, jobs!inner(*)')
        .eq('mover_id', userId)
        .neq('jobs.status', 'COMPLETED');

    return response.map((row) => Assignment.fromMap(row)).toList();
  }

  // -------------------------------------------------------
  // JOB DETAILS
  // -------------------------------------------------------

  Future<Job> getAssignedJob(String jobId) async {
    final response = await _client
        .from('jobs')
        .select()
        .eq('id', jobId)
        .single();

    return Job.fromMap(response);
  }

  // -------------------------------------------------------
  // JOB ITEMS
  // -------------------------------------------------------

  Future<List<JobItem>> getAssignedJobItems(String jobId) async {
    final response = await _client
        .from('job_items')
        .select()
        .eq('job_id', jobId)
        .order('id', ascending: true);

    return response.map((row) => JobItem.fromMap(row)).toList();
  }

  // -------------------------------------------------------
  // ACCEPT ASSIGNMENT
  // -------------------------------------------------------

  Future<MoverResponseResult> acceptAssignment(String assignmentId) {
    return _respond(
      assignmentId: assignmentId,
      decision: AssignmentStatus.accepted,
    );
  }

  // -------------------------------------------------------
  // REJECT ASSIGNMENT
  // -------------------------------------------------------

  Future<MoverResponseResult> rejectAssignment(String assignmentId) {
    return _respond(
      assignmentId: assignmentId,
      decision: AssignmentStatus.rejected,
    );
  }

  // -------------------------------------------------------
  // RESPONSE RPC
  // -------------------------------------------------------

  Future<MoverResponseResult> _respond({
    required String assignmentId,
    required AssignmentStatus decision,
  }) async {
    if (decision != AssignmentStatus.accepted &&
        decision != AssignmentStatus.rejected) {
      throw ArgumentError('Mover decision must be ACCEPTED or REJECTED.');
    }

    final response = await _client.rpc(
      'mover_respond_assignment',
      params: {'p_assignment_id': assignmentId, 'p_decision': decision.value},
    );

    if (response is! List || response.isEmpty) {
      throw StateError(
        'Assignment response completed but no result was returned.',
      );
    }

    final firstRow = response.first;

    if (firstRow is! Map) {
      throw StateError('Invalid response from mover_respond_assignment.');
    }

    final row = Map<String, dynamic>.from(firstRow);

    return MoverResponseResult(
      assignmentId: row['assignment_id'] as String,
      jobId: row['job_id'] as String,
      newStatus: AssignmentStatus.fromString(row['new_status'] as String),
      respondedAt: DateTime.parse(row['responded_at'] as String),
    );
  }

  // -------------------------------------------------------
  // COMPLETE JOB
  // -------------------------------------------------------

  Future<void> completeJob(String jobId) async {
    await _client.rpc('complete_job', params: {'p_job_id': jobId});
  }

  // -------------------------------------------------------
  // GET COMPLETED ASSIGNMENTS
  // -------------------------------------------------------

  Future<List<Assignment>> getWorkHistory() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Authentication required.');

    final response = await _client
        .from('assignments')
        .select('*, jobs!inner(*)')
        .eq('mover_id', userId)
        .eq('status', 'ACCEPTED')
        .eq('jobs.status', 'COMPLETED');

    return response.map((row) => Assignment.fromMap(row)).toList();
  }

  // -------------------------------------------------------
  // GET TIME LOGS FOR ASSIGNMENT
  // -------------------------------------------------------

  Future<List<Map<String, dynamic>>> getJobTimeLogs(String assignmentId) async {
    final response = await _client
        .from('time_logs')
        .select()
        .eq('assignment_id', assignmentId)
        .order('clock_in_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }
}
