import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/mover_location.dart';
import 'location_tracking_provider.dart';

final liveLocationProvider = StreamProvider.family<MoverLocation?, String>((
  ref,
  assignmentId,
) {
  final repository = ref.read(locationRepositoryProvider);

  return repository.streamLocation(assignmentId);
});
