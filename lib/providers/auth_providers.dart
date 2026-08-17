import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/user.dart';
import '../data/repositories/auth_repository.dart';
import '../data/supabase_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);

  return AuthRepository(client);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);

  return repository.authStateChanges;
});

final currentAppUserProvider = FutureProvider<AppUser?>((ref) async {
  ref.watch(authStateProvider);

  final repository = ref.watch(authRepositoryProvider);

  return repository.getCurrentAppUser();
});
