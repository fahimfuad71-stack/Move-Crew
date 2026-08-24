import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/assignment.dart';
import '../models/job.dart';
import '../models/job_item.dart';

class CreatedMoveRequest {
  const CreatedMoveRequest({required this.jobId, required this.jobCode});

  final String jobId;
  final String jobCode;
}

class CustomerJobRepository {
  const CustomerJobRepository(this._client);

  final SupabaseClient _client;

  // -------------------------------------------------------
  // CREATE MOVE REQUEST
  // -------------------------------------------------------

  Future<CreatedMoveRequest> createMoveRequest({
    required String pickupAddress,
    required String destinationAddress,
    required DateTime moveDate,
    required String startTime,
    String? instructions,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _client.rpc(
      'create_move_request',
      params: {
        'p_pickup_address': pickupAddress.trim(),
        'p_destination_address': destinationAddress.trim(),
        'p_move_date': _formatDate(moveDate),
        'p_start_time': startTime,
        'p_instructions': instructions?.trim() ?? '',
        'p_items': items,
      },
    );

    if (response is! List || response.isEmpty) {
      throw StateError(
        'Move request was created but no '
        'job information was returned.',
      );
    }

    final firstRow = response.first;

    if (firstRow is! Map) {
      throw StateError(
        'Invalid response from '
        'create_move_request.',
      );
    }

    final row = Map<String, dynamic>.from(firstRow);

    return CreatedMoveRequest(
      jobId: row['job_id'] as String,
      jobCode: row['job_code'] as String,
    );
  }

  // -------------------------------------------------------
  // GET CURRENT CUSTOMER JOBS
  //
  // RLS automatically limits the result to the
  // currently authenticated customer.
  // -------------------------------------------------------

  Future<List<Job>> getMyJobs() async {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      throw StateError('Authentication required.');
    }

    final response = await _client
        .from('jobs')
        .select()
        .eq('customer_id', userId)
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
  // GET ITEMS FOR ONE JOB
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
  // GET ASSIGNMENT FOR JOB
  // -------------------------------------------------------

  Future<Assignment?> getJobAssignment(String jobId) async {
    final response = await _client
        .from('assignments')
        .select()
        .eq('job_id', jobId)
        .order('responded_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    return Assignment.fromMap(response);
  }

  // -------------------------------------------------------
  // DATE FORMATTER
  //
  // PostgreSQL DATE expects:
  // YYYY-MM-DD
  // -------------------------------------------------------

  String _formatDate(DateTime date) {
    final year = date.year.toString();

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
