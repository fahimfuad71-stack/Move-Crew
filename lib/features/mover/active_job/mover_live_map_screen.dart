import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../providers/live_location_provider.dart';

class MoverLiveMapScreen extends ConsumerWidget {
  const MoverLiveMapScreen({super.key, required this.assignmentId});

  final String assignmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(liveLocationProvider(assignmentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Live Tracking')),
      body: locationAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to live tracking...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Unable to load map: $error',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (location) {
          if (location == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_searching, size: 48, color: Colors.blue),
                  SizedBox(height: 16),
                  Text('Waiting for mover to start tracking...'),
                  Text(
                    'No location data received yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final position = LatLng(location.latitude, location.longitude);

          return GoogleMap(
            initialCameraPosition: CameraPosition(target: position, zoom: 15),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: {
              Marker(
                markerId: const MarkerId('mover'),
                position: position,
                infoWindow: const InfoWindow(title: 'Mover Location'),
              ),
            },
          );
        },
      ),
    );
  }
}
