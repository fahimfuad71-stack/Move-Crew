import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/live_location_provider.dart';
import '../../../providers/customer_job_providers.dart';

class CustomerLiveMapScreen extends ConsumerStatefulWidget {
  const CustomerLiveMapScreen({super.key, required this.assignmentId});

  final String assignmentId;

  @override
  ConsumerState<CustomerLiveMapScreen> createState() => _CustomerLiveMapScreenState();
}

class _CustomerLiveMapScreenState extends ConsumerState<CustomerLiveMapScreen> {
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
        title: const Text('Track My Mover'),
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
              Text('Connecting to mover GPS...'),
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
                  'Unable to track mover: $error',
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
                  Icon(Icons.local_shipping_outlined, size: 48, color: Colors.blue),
                  SizedBox(height: 16),
                  Text('Mover is preparing for your job.'),
                  Text(
                    'Tracking will start once the move begins.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final position = LatLng(location.latitude, location.longitude);

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: position, zoom: 15),
                myLocationEnabled: true,
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
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                    infoWindow: const InfoWindow(title: 'Your Mover'),
                  ),
                },
              ),
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Consumer(
                  builder: (context, ref, child) {
                    final assignmentAsync = ref.watch(jobAssignmentProvider(widget.assignmentId));
                    return assignmentAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (e, s) => const SizedBox.shrink(),
                      data: (assignment) {
                        if (assignment == null) return const SizedBox.shrink();
                        final jobAsync = ref.watch(jobProvider(assignment.jobId));
                        return jobAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (e, s) => const SizedBox.shrink(),
                          data: (job) {
                            return Card(
                              color: AppColors.tealPrimary,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Job Status: ${job.status.value}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Card(
                  elevation: 4,
                  color: Theme.of(context).cardTheme.color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.tealPrimary.withOpacity(0.1),
                          child: const Icon(Icons.local_shipping, color: AppColors.tealPrimary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Mover is on the way',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                'Last updated: ${location.recordedAt != null ? _formatTime(location.recordedAt!) : 'Just now'}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: AppColors.tealPrimary),
                          onPressed: () => ref.refresh(liveLocationProvider(widget.assignmentId)),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    // Use UTC comparison to avoid local clock drift issues
    final diff = DateTime.now().toUtc().difference(time.toUtc());
    if (diff.isNegative) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return 'more than 1h ago';
  }
}
