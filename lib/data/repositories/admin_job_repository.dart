import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/status_enums.dart';
import '../models/job.dart';
import '../models/job_item.dart';
import '../models/user.dart';

class AdminReviewResult {
  const AdminReviewResult({
    required this.jobId,
    required this.jobCode,
    required this.newStatus,
  });

  final String jobId;
  final String jobCode;
  final JobStatus newStatus;
}

class AdminJobRepository {
  const AdminJobRepository(this._client);

  final SupabaseClient _client;

  // -------------------------------------------------------
  // GET ALL INCOMING REQUESTS
  // -------------------------------------------------------

  Future<List<Job>> getIncomingRequests() async {
    final response = await _client
        .from('jobs')
        .select()
        .eq('status', 'REQUESTED')
        .order('created_at', ascending: false);

    return response.map((row) => Job.fromMap(row)).toList();
  }

  // -------------------------------------------------------
  // GET ONE JOB
  // -------------------------------------------------------

  Future<Job> getJobById(String jobId) async {
    final response = await _client
        .from('jobs')
        .select()
        .eq('id', jobId)
        .single();

    return Job.fromMap(response);
  }

  // -------------------------------------------------------
  // GET JOB ITEMS
  // -------------------------------------------------------

  Future<List<JobItem>> getJobItems(String jobId) async {
    final response = await _client
        .from('job_items')
        .select()
        .eq('job_id', jobId)
        .order('id', ascending: true);

    return response.map((row) => JobItem.fromMap(row)).toList();
  }

  // -------------------------------------------------------
  // GET CUSTOMER PROFILE
  // -------------------------------------------------------

  Future<AppUser> getCustomerById(String customerId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', customerId)
        .single();

    return AppUser.fromJson(response);
  }

  // -------------------------------------------------------
  // APPROVE
  // -------------------------------------------------------

  Future<AdminReviewResult> approveRequest(String jobId) {
    return _reviewRequest(jobId: jobId, decision: JobStatus.approved);
  }

  // -------------------------------------------------------
  // REJECT
  // -------------------------------------------------------

  Future<AdminReviewResult> rejectRequest(String jobId) {
    return _reviewRequest(jobId: jobId, decision: JobStatus.rejected);
  }

  // -------------------------------------------------------
  // ADMIN REVIEW RPC
  // -------------------------------------------------------

  Future<AdminReviewResult> _reviewRequest({
    required String jobId,
    required JobStatus decision,
  }) async {
    if (decision != JobStatus.approved && decision != JobStatus.rejected) {
      throw ArgumentError('Admin decision must be APPROVED or REJECTED.');
    }

    final response = await _client.rpc(
      'admin_review_request',
      params: {'p_job_id': jobId, 'p_decision': decision.value},
    );

    if (response is! List || response.isEmpty) {
      throw StateError('Admin review completed but no result was returned.');
    }

    final firstRow = response.first;

    if (firstRow is! Map) {
      throw StateError('Invalid response from admin_review_request.');
    }

    final row = Map<String, dynamic>.from(firstRow);

    return AdminReviewResult(
      jobId: row['job_id'] as String,
      jobCode: row['job_code'] as String,
      newStatus: JobStatus.fromString(row['new_status'] as String),
    );
  }
}
