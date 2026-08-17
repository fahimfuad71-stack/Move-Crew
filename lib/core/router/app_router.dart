import 'package:go_router/go_router.dart';

import '../../features/auth/role_gate.dart';
import '../../features/auth/signup_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const RoleGate()),

    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
  ],
);
