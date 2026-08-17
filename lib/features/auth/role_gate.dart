import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/status_enums.dart';
import '../../data/supabase_client.dart';
import '../../providers/auth_providers.dart';

import '../admin/dashboard/admin_dashboard_screen.dart';
import '../customer/home/customer_home_screen.dart';
import '../mover/my_jobs/mover_home_screen.dart';

import 'login_screen.dart';

class RoleGate extends ConsumerWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateProvider);

    final supabase = ref.watch(supabaseClientProvider);

    if (supabase.auth.currentSession == null) {
      return const LoginScreen();
    }

    final userAsync = ref.watch(currentAppUserProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),

      error: (error, stack) => Scaffold(
        body: Center(
          child: Text(
            'Unable to load user profile.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),

      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        switch (user.role) {
          case UserRole.customer:
            return const CustomerHomeScreen();

          case UserRole.admin:
            return const AdminDashboardScreen();

          case UserRole.mover:
            return const MoverHomeScreen();
        }
      },
    );
  }
}
