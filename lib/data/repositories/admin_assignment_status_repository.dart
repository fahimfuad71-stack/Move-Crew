import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/status_enums.dart';
import '../models/admin_mover_assignment.dart';

class AdminAssignmentStatusRepository {
  const AdminAssignmentStatusRepository(this._client);

  final SupabaseClient _client;

  Future<List<AdminMoverAssignment>> getMoverAssignmentsForJob(
    String jobId,
  ) async {
    final assignmentRows = await _client
        .from('assignments')
        .select()
        .eq('job_id', jobId);

    if (assignmentRows.isEmpty) {
      return [];
    }

    final moverIds = assignmentRows
        .map((row) => row['mover_id'] as String)
        .toSet()
        .toList();

    final moverRows = await _client
        .from('movers')
        .select()
        .inFilter('id', moverIds);

    final userRows = await _client
        .from('users')
        .select()
        .inFilter('id', moverIds);

    final moversById = <String, Map<String, dynamic>>{};

    for (final row in moverRows) {
      final map = Map<String, dynamic>.from(row);

      moversById[map['id'] as String] = map;
    }

    final usersById = <String, Map<String, dynamic>>{};

    for (final row in userRows) {
      final map = Map<String, dynamic>.from(row);

      usersById[map['id'] as String] = map;
    }

    final result = <AdminMoverAssignment>[];

    for (final assignmentRow in assignmentRows) {
      final assignment = Map<String, dynamic>.from(assignmentRow);

      final moverId = assignment['mover_id'] as String;

      final mover = moversById[moverId];

      final user = usersById[moverId];

      if (mover == null || user == null) {
        continue;
      }

      final respondedAtValue = assignment['responded_at'];

      result.add(
        AdminMoverAssignment(
          assignmentId: assignment['id'] as String,
          moverId: moverId,
          employeeCode: mover['employee_code'] as String,
          fullName: user['full_name'] as String,
          phone: user['phone'] as String?,
          status: AssignmentStatus.fromString(assignment['status'] as String),
          respondedAt: respondedAtValue == null
              ? null
              : DateTime.parse(respondedAtValue as String),
        ),
      );
    }

    result.sort((a, b) => a.employeeCode.compareTo(b.employeeCode));

    return result;
  }
}
