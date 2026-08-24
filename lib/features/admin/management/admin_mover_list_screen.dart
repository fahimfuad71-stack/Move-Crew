import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/admin_assignment_providers.dart';
import 'admin_mover_detail_screen.dart';

class AdminMoverListScreen extends ConsumerWidget {
  const AdminMoverListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moversAsync = ref.watch(availableMoversProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Mover Management'),
      ),
      body: moversAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (movers) {
          if (movers.isEmpty) {
            return const Center(child: Text('No movers found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: movers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final mover = movers[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E5EA)),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFD7E6F7),
                    child: Icon(Icons.engineering_outlined, color: Color(0xFF1E56A0)),
                  ),
                  title: Text(mover.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Code: ${mover.employeeCode}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AdminMoverDetailScreen(mover: mover)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
