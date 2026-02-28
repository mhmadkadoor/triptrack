import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/trip.dart';

class TripRepository {
  final SupabaseClient _client;
  final _uuid = const Uuid();

  TripRepository(this._client);

  /// Streams the list of trips the user is a member of.
  /// (Row Level Security automatically filters this to only trips the user has joined).
  Stream<List<Trip>> watchUserTrips() {
    return _client
        .from('trips')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Trip.fromJson(json)).toList());
  }

  /// Creates a new trip and simultaneously attaches the creator as the "Leader".
  Future<void> createTrip({
    required String name,
    required String currency,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null)
      throw Exception('User must be logged in to create a trip');

    // Generate a UUID locally. RLS makes it tricky to immediately returned the inserted row
    // when using .select() because the `trip_members` entry isn't there yet.
    final tripId = _uuid.v4();

    // 1. Insert the Trip
    await _client.from('trips').insert({
      'id': tripId,
      'name': name,
      'base_currency': currency,
      'created_by': userId,
      'phase': 'active', // Enum converted gracefully by Supabase
      'is_locked': false,
    });

    // 2. Insert the Member (The Creator becomes the Leader)
    await _client.from('trip_members').insert({
      'trip_id': tripId,
      'user_id': userId,
      'role': 'leader',
      'exit_status': 'none',
    });
  }
}
