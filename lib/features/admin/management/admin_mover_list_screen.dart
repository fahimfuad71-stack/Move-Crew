import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../providers/admin_assignment_providers.dart';
import '../../../providers/theme_provider.dart';
import 'admin_mover_detail_screen.dart';

class AdminMoverListScreen extends ConsumerWidget {
  const AdminMoverListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moversAsync = ref.watch(availableMoversProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mover Management', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggle();
            },
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: moversAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (movers) {
          if (movers.isEmpty) {
            return const Center(child: Text('No movers found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: movers.length,
            itemBuilder: (context, index) {
              final mover = movers[index];
              return PremiumCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminMoverDetailScreen(mover: mover)),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: AppColors.tealPrimary.withValues(alpha: 0.1),
                      child: const Icon(Icons.engineering_rounded, color: AppColors.tealPrimary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(mover.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Code: ${mover.employeeCode}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
