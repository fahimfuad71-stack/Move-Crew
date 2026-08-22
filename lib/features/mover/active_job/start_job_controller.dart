import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../providers/location_tracking_provider.dart';

final startJobControllerProvider = Provider<StartJobController>((ref) {
  return StartJobController(ref);
});

class StartJobController {
  StartJobController(this.ref);

  final Ref ref;
  final supabase = Supabase.instance.client;

  Future<bool> isActive(String assignmentId) async {
    final row = await supabase
        .from('time_logs')
        .select('id')
        .eq('assignment_id', assignmentId)
        .eq('status', 'ACTIVE')
        .limit(1)
        .maybeSingle();

    return row != null;
  }

  Future<void> start({
    required String assignmentId,
    required String moverId,
  }) async {
    final alreadyActive = await isActive(assignmentId);

    if (!alreadyActive) {
      await supabase.rpc(
        'mover_start_job',
        params: {'p_assignment_id': assignmentId},
      );
    }

    await ref
        .read(locationTrackingProvider.notifier)
        .startTracking(assignmentId: assignmentId, moverId: moverId);
  }

  Future<void> stop({required String assignmentId}) async {
    await supabase.rpc(
      'mover_stop_job',
      params: {'p_assignment_id': assignmentId},
    );

    await ref.read(locationTrackingProvider.notifier).stopTracking();
  }
}
