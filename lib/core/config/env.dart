class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static void validate() {
    if (supabaseUrl.trim().isEmpty) {
      throw StateError('SUPABASE_URL is missing.');
    }

    if (supabasePublishableKey.trim().isEmpty) {
      throw StateError('SUPABASE_PUBLISHABLE_KEY is missing.');
    }

    final uri = Uri.tryParse(supabaseUrl);

    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw StateError('Invalid Supabase URL: $supabaseUrl');
    }
  }
}
