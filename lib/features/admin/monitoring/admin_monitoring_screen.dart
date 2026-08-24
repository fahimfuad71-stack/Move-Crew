import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../providers/admin_job_providers.dart';

class AdminMonitoringScreen extends ConsumerWidget {
  const AdminMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMovesAsync = ref.watch(activeMovesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Job Monitoring'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(activeMovesProvider),
          ),
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
                    snippet: 'Mover: ${move.assignment.moverId}',
                  ),
                ),
              );
            }
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: markers.isNotEmpty ? markers.first.position : const LatLng(0, 0),
                  zoom: 12,
                ),
                markers: markers,
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: moves.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final move = moves[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.local_shipping)),
                        title: Text(move.job.jobCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Status: ${move.job.status.value}'),
                        trailing: move.latestLocation != null 
                          ? const Icon(Icons.location_on, color: Colors.green)
                          : const Icon(Icons.location_off, color: Colors.red),
                      );
                    },
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
