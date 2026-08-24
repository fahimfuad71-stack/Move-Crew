import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/admin_job_providers.dart';
import 'admin_customer_detail_screen.dart';

class AdminCustomerListScreen extends ConsumerWidget {
  const AdminCustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(adminAllCustomersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Customer Management'),
      ),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (customers) {
          if (customers.isEmpty) return const Center(child: Text('No customers found.'));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: customers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final customer = customers[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E5EA))),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEBEE),
                    child: Icon(Icons.person_outline, color: Colors.redAccent),
                  ),
                  title: Text(customer.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(customer.phone ?? 'No phone'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AdminCustomerDetailScreen(customer: customer)),
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
