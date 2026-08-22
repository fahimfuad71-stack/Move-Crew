import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/job_item.dart';
import '../data/repositories/job_item_repository.dart';

final jobItemRepositoryProvider = Provider<JobItemRepository>((ref) {
  return JobItemRepository();
});

final jobItemsProvider = FutureProvider.family<List<JobItem>, String>((
  ref,
  jobId,
) async {
  final repository = ref.read(jobItemRepositoryProvider);

  return repository.getItems(jobId);
});
