import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mover_location.dart';

class LocationRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> saveLocation(MoverLocation location) async {
    try {
      await _client.from('mover_locations').insert(location.toMap());

      print("LOCATION SAVED: ${location.latitude}, ${location.longitude}");
    } catch (e) {
      print("LOCATION SAVE ERROR: $e");
    }
  }

  Future<MoverLocation?> getLatestLocation(String assignmentId) async {
    final response = await _client
        .from('mover_locations')
        .select()
        .eq('assignment_id', assignmentId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return MoverLocation.fromMap(response);
  }

  Stream<MoverLocation?> streamLocation(String assignmentId) {
    return _client
        .from('mover_locations')
        .stream(primaryKey: ['id'])
        .eq('assignment_id', assignmentId)
        .map((data) {
          if (data.isEmpty) {
            return null;
          }

          final latest = data.last;

          return MoverLocation.fromMap(latest);
        });
  }
}
