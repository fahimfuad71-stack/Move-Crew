import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/admin_job_providers.dart';

class AdminMonitoringScreen extends ConsumerStatefulWidget {
  const AdminMonitoringScreen({super.key});

  @override
  ConsumerState<AdminMonitoringScreen> createState() => _AdminMonitoringScreenState();
}

class _AdminMonitoringScreenState extends ConsumerState<AdminMonitoringScreen> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  LatLngBounds _getBounds(Set<Marker> markers) {
    double? minLat, maxLat, minLng, maxLng;
    for (final m in markers) {
      if (minLat == null || m.position.latitude < minLat) minLat = m.position.latitude;
      if (maxLat == null || m.position.latitude > maxLat) maxLat = m.position.latitude;
      if (minLng == null || m.position.longitude < minLng) minLng = m.position.longitude;
      if (maxLng == null || m.position.longitude > maxLng) maxLng = m.position.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeMovesAsync = ref.watch(activeMovesProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

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
        title: const Text('Live Job Monitoring'),
        actions: [
          IconButton(
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(activeMovesProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: activeMovesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (moves) {
          if (moves.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monitor_heart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No active moves currently in progress.'),
                ],
              ),
            );
          }

          final markers = <Marker>{};
          for (var move in moves) {
            if (move.latestLocation != null) {
              final pos = LatLng(
                move.latestLocation!['latitude'],
                move.latestLocation!['longitude'],
              );
              markers.add(
                Marker(
                  markerId: MarkerId(move.assignment.id),
                  position: pos,
                  infoWindow: InfoWindow(
                    title: 'Job: ${move.job.jobCode}',
                    snippet: 'Mover: ${move.moverName} (${move.employeeCode})',
                  ),
                ),
              );
            }
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: markers.isNotEmpty ? markers.first.position : const LatLng(23.8103, 90.4125),
                  zoom: 12,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (isDark) {
                    _mapController!.setMapStyle(AppTheme.darkMapStyle);
                  }
                  
                  // Fit all markers in view once map is created
                  if (markers.isNotEmpty) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      final bounds = _getBounds(markers);
                      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
                    });
                  }
                },
                markers: markers,
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: const [BoxShadow(blurRadius: 15, color: Colors.black26)],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: moves.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final move = moves[index];
                            final hasLocation = move.latestLocation != null;
                            
                            return ListTile(
                              onTap: hasLocation ? () {
                                final pos = LatLng(
                                  move.latestLocation!['latitude'],
                                  move.latestLocation!['longitude'],
                                );
                                _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
                              } : null,
                              leading: const CircleAvatar(
                                backgroundColor: Colors.teal,
                                child: Icon(Icons.local_shipping, color: Colors.white),
                              ),
                              title: Text(move.job.jobCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(move.moverName, style: const TextStyle(fontSize: 12)),
                                  Text('Emp Code: ${move.employeeCode}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                              trailing: hasLocation 
                                ? const Icon(Icons.location_on, color: Colors.green)
                                : const Icon(Icons.location_off, color: Colors.red),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
