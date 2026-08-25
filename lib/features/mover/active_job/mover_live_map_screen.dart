import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/live_location_provider.dart';

class MoverLiveMapScreen extends ConsumerStatefulWidget {
  const MoverLiveMapScreen({super.key, required this.assignmentId});

  final String assignmentId;

  @override
  ConsumerState<MoverLiveMapScreen> createState() => _MoverLiveMapScreenState();
}

class _MoverLiveMapScreenState extends ConsumerState<MoverLiveMapScreen> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(liveLocationProvider(widget.assignmentId));
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    // Reactively update map style when theme changes
    ref.listen(themeModeProvider, (previous, next) {
      if (_mapController != null) {
        if (next == ThemeMode.dark) {
          _mapController!.setMapStyle(AppTheme.darkMapStyle);
        } else {
          _mapController!.setMapStyle(null);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        actions: [
          IconButton(
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          const SizedBox(width: 8),
        ],
      ),
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
            onMapCreated: (controller) {
              _mapController = controller;
              if (isDark) {
                _mapController!.setMapStyle(AppTheme.darkMapStyle);
              }
            },
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
