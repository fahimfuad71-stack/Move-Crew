import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/location_service.dart';
import '../data/models/mover_location.dart';
import '../data/repositories/location_repository.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository();
});

final locationTrackingProvider =
    NotifierProvider<LocationTrackingNotifier, bool>(
      LocationTrackingNotifier.new,
    );

class LocationTrackingNotifier extends Notifier<bool> {
  StreamSubscription? _subscription;

  @override
  bool build() {
    ref.onDispose(() {
      _subscription?.cancel();
    });

    return false;
  }

  Future<void> startTracking({
    required String assignmentId,
    required String moverId,
  }) async {
    if (state) return;

    final service = ref.read(locationServiceProvider);
    final repository = ref.read(locationRepositoryProvider);

    state = true;

    _subscription = service.trackLocation().listen((position) async {
      print("GPS UPDATE: ${position.latitude}, ${position.longitude}");

      final location = MoverLocation(
        id: null,
        assignmentId: assignmentId,
        moverId: moverId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        recordedAt: DateTime.now(),
      );

      await repository.saveLocation(location);
    });
  }

  Future<void> stopTracking() async {
    await _subscription?.cancel();

    _subscription = null;

    state = false;
  }
}
