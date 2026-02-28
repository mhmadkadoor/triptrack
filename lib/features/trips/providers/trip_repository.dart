import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/trip.dart';
import '../../roster/models/trip_member.dart'; // Add this

class TripRepository {
  final SupabaseClient _client;
  final _uuid = const Uuid();

  TripRepository(this._client);

  /// Streams the list of trips the user is a member of.
  Stream<List<Trip>> watchUserTrips() {
    return _client
        .from('trips')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Trip.fromJson(json)).toList());
  }

  /// Watch a specific trip by ID.
  Stream<Trip> watchTrip(String id) {
    return _client
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) => Trip.fromJson(data.first));
  }

  /// Streams the members of a given trip, joined with their profile data.
  Stream<List<TripMember>> watchTripMembers(String tripId) {
    return _client
        .from('trip_members')
        .stream(primaryKey: ['trip_id', 'user_id'])
        .eq('trip_id', tripId)
        .asyncMap((data) async {
          // Since stream() doesn't support deep joins easily (it returns the raw table data),
          // updates to Profiles won't trigger this stream, but updates to Members will.
          // We need to fetch profiles for these members.
          // Optimization: If the roster is huge, this is N+1, but for a trip it is small.
          // Better approach might be real-time listeners on both, but simpler is:
          // Just fetch profiles once or listen to them.

          // Actually, .stream() in supabase-flutter is a bit limited for joins.
          // Let's rely on standard current state fetch OR a refreshing stream.
          // Alternatively, we can just use a simple future or separate streams.

          // However, to keep it simple and reactive:
          // We'll map the members, and for each member, we might need to fetch profile?
          // No, that's too heavy.
          // A better pattern for "Members List" is:
          // stream('trip_members').eq('trip_id', id)
          // AND separate stream('profiles').inFilter('id', memberIds)

          // FOR NOW: Let's just fetch the profiles once per update.
          if (data.isEmpty) return [];

          final userIds = data.map((e) => e['user_id'] as String).toList();
          final profiles = await _client
              .from('profiles')
              .select()
              .inFilter('id', userIds);

          final profileMap = {for (var p in profiles) p['id'] as String: p};

          return data.map((json) {
            // merge profile into json for model parsing
            final userId = json['user_id'] as String;
            final profileJson = profileMap[userId];
            if (profileJson != null) {
              json['profiles'] = profileJson;
            }
            return TripMember.fromJson(json);
          }).toList();
        });
  }

  /// Creates a new trip and simultaneously attaches the creator as the "Leader".
  Future<void> createTrip({
    required String name,
    required String currency,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be logged in to create a trip');
    }

    // Generate a UUID locally. RLS makes it tricky to immediately returned the inserted row
    // when using .select() because the `trip_members` entry isn't there yet.
    final tripId = _uuid.v4();
    final inviteCode = _generateInviteCode();

    // 1. Insert the Trip
    await _client.from('trips').insert({
      'id': tripId,
      'name': name,
      'base_currency': currency,
      'created_by': userId,
      'phase': 'active', // Enum converted gracefully by Supabase
      'is_locked': false,
      'invite_code': inviteCode, // Include the invite code
    });

    // 2. Insert the Member (The Creator becomes the Leader)
    await _client.from('trip_members').insert({
      'trip_id': tripId,
      'user_id': userId,
      'role': 'leader',
      'exit_status': 'none',
    });
  }

  /// Start the "Join Trip" flow.
  /// 
  /// 1. Validate the code exists.
  /// 2. Check if user is already a member.
  /// 3. Add user to trip_members with 'contributor' role.
  Future<void> joinTrip(String inviteCode) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Must be logged in to join a trip.');

    // 1. Find the trip by invite code
    final tripData = await _client
        .from('trips')
        .select('id') 
        .eq('invite_code', inviteCode)
        .maybeSingle();

    if (tripData == null) {
      throw Exception('Invalid invite code. Please check and try again.');
    }

    final tripId = tripData['id'] as String;

    // 2. Check strict membership? 
    // Usually Supabase will throw a unique constraint error if (trip_id, user_id) already exists.
    // But let's check manually for a nicer error message.
    final existingMember = await _client
        .from('trip_members')
        .select('role')
        .eq('trip_id', tripId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existingMember != null) {
      throw Exception('You are already a member of this trip.');
    }

    // 3. Insert new member
    await _client.from('trip_members').insert({
      'trip_id': tripId,
      'user_id': userId,
      'role': 'contributor', // Default role
      'exit_status': 'none',
    });
  }

  String _generateInviteCode() { // Make it static or instance method
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      6,
      (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ));
  }
}
