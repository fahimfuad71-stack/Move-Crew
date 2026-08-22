import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/job_item.dart';

class JobItemRepository {
  final supabase = Supabase.instance.client;

  Future<List<JobItem>> getItems(String jobId) async {
    final response = await supabase
        .from('job_items')
        .select()
        .eq('job_id', jobId)
        .order('id');

    return (response as List).map((item) => JobItem.fromMap(item)).toList();
  }

  Future<void> updateStatus({
    required int itemId,
    required String status,
  }) async {
    await supabase.rpc(
      'mover_update_item_status',
      params: {'p_item_id': itemId, 'p_status': status},
    );
  }
}
