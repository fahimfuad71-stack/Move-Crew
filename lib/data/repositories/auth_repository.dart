import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  User? get currentAuthUser {
    return _client.auth.currentUser;
  }

  Session? get currentSession {
    return _client.auth.currentSession;
  }

  Stream<AuthState> get authStateChanges {
    return _client.auth.onAuthStateChange;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    return await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim(), 'phone': phone?.trim()},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<AppUser?> getCurrentAppUser() async {
    final authUser = _client.auth.currentUser;

    if (authUser == null) {
      return null;
    }

    final data = await _client
        .from('users')
        .select()
        .eq('id', authUser.id)
        .single();

    return AppUser.fromJson(data);
  }
}
