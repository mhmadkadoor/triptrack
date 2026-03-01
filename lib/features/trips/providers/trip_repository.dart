import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/trip.dart';
import '../../roster/models/trip_member.dart';
import '../../ledger/models/expense.dart';

class TripRepository {
  final SupabaseClient _client;
  final _uuid = const Uuid();

  TripRepository(this._client);

  /// Streams expenses for a trip, joined with the profile of the payer.
  Stream<List<Expense>> watchExpenses(String tripId) {
    return _client
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .order('created_at', ascending: false)
        .asyncMap((data) async {
          if (data.isEmpty) return <Expense>[];

          final expenseIds = data.map((e) => e['id'] as String).toList();
          final userIds = data
              .map((e) => e['paid_by'] as String)
              .toSet()
              .toList();

          // Fetch profiles
          final profiles = await _client
              .from('profiles')
              .select()
              .inFilter('id', userIds);
          final profileMap = {for (var p in profiles) p['id'] as String: p};

          // Fetch participants
          final participantsData = await _client
              .from('expense_participants')
              .select('expense_id, user_id')
              .inFilter('expense_id', expenseIds);

          // Group participants by expense
          final participantsMap = <String, List<Map<String, dynamic>>>{};
          for (var p in participantsData) {
            final eId = p['expense_id'] as String;
            if (!participantsMap.containsKey(eId)) {
              participantsMap[eId] = [];
            }
            participantsMap[eId]!.add(p);
          }

          return data.map((json) {
            final eId = json['id'] as String;
            final payerId = json['paid_by'] as String;

            // Attach profile
            final profileJson = profileMap[payerId];
            if (profileJson != null) {
              json['profiles'] = profileJson;
            }

            // Attach participants
            if (participantsMap.containsKey(eId)) {
              json['participants'] = participantsMap[eId];
            } else {
              json['participants'] = <Map<String, dynamic>>[];
            }

            return Expense.fromJson(json);
          }).toList();
        });
  }

  /// Creates a new expense and assigns participants.
  Future<void> createExpense({
    required String tripId,
    required String description,
    required double amount,
    required List<String> participantUserIds,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Must be logged in.');

    if (participantUserIds.isEmpty) {
      throw Exception('At least one participant is required.');
    }
    if (amount <= 0) {
      throw Exception('Amount must be positive.');
    }

    // 1. Fetch trip currency for consistency
    final trip = await _client
        .from('trips')
        .select('base_currency')
        .eq('id', tripId)
        .single();
    final currency = trip['base_currency'] as String;

    // 2. Insert Expense
    // We generate ID locally for simpler insertion logic
    final expenseId = _uuid.v4();
    final createdAt = DateTime.now().toUtc().toIso8601String();

    await _client.from('expenses').insert({
      'id': expenseId,
      'trip_id': tripId,
      'description': description,
      'amount': amount,
      'created_at': createdAt,
      'paid_by': userId,
      'currency': currency,
    });

    // 3. Insert Participants (Simulate split)
    // Assuming even split for now, or just recording involvement
    final amountPerPerson = amount / participantUserIds.length;

    final participantsData = participantUserIds
        .map(
          (pId) => {
            'expense_id': expenseId,
            'user_id': pId,
            'amount_owed': amountPerPerson, // Use calculated split
            'is_paid': false,
          },
        )
        .toList();

    await _client.from('expense_participants').insert(participantsData);
  }

  /// Only leaders can update member role.
  Future<void> updateMemberRole({
    required String tripId,
    required String memberId,
    required TripRole newRole,
  }) async {
    // Only the 'leader' is allowed to perform this.
    // Ensure we don't accidentally check the current user's role against memberId.
    // Usually RLS handles permission checks.

    // CRITICAL: If downgrading to 'hiker', we must delete all expenses paid by them.
    // Hikers cannot be 'paid_by' on any expense.
    if (newRole == TripRole.hiker) {
      try {
        // Supabase cascade will handle expense_participants,
        // but we must delete the expenses rows where they are the payer.
        // We verify the deletion by selecting the returned rows.
        await _client.from('expenses').delete().match({
          'trip_id': tripId,
          'paid_by': memberId,
        }).select();
      } catch (e) {
        // This usually happens if RLS policies prevent deletion
        // or if foreign key constraints fail without CASCADE.
        throw Exception(
          'Failed to delete expenses. Database blocked the action. Ensure you are a valid Leader and policies are set.',
        );
      }
    }

    // We update the trip_members table directly.
    final result = await _client
        .from('trip_members')
        .update({'role': newRole.name})
        .match({'trip_id': tripId, 'user_id': memberId})
        .select();

    if (result.isEmpty) {
      throw Exception('Failed to update role. You may not have permission.');
    }
  }

  /// Streams the list of trips the user is a member of.
  ///
  /// Note: Listening to `trips` directly might not catch updates when a user *joins* a trip
  /// because the `trips` row itself doesn't change.
  ///
  /// A more robust implementation listens to `trip_members` for the current user,
  /// then fetches the actual trip details.
  Stream<List<Trip>> watchUserTrips() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    // Listen to the junction table (trip_members) to know when we join/leave trips
    return _client
        .from('trip_members')
        .stream(primaryKey: ['trip_id', 'user_id'])
        .eq('user_id', userId)
        .asyncMap((membersData) async {
          if (membersData.isEmpty) return <Trip>[];

          final tripIds = membersData
              .map((m) => m['trip_id'] as String)
              .toList();

          if (tripIds.isEmpty) return <Trip>[];

          // Fetch the actual trips
          final tripsData = await _client
              .from('trips')
              .select()
              .inFilter('id', tripIds)
              .order('created_at', ascending: false);

          return tripsData.map((json) => Trip.fromJson(json)).toList();
        });
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
    required TripRole defaultJoinRole,
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
      'default_join_role': defaultJoinRole.name,
    });

    // 2. Insert the Member (The Creator becomes the Leader)
    await _client.from('trip_members').insert({
      'trip_id': tripId,
      'user_id': userId,
      'role': 'leader',
      'exit_status': 'none',
    });
  }

  /// Finishes the trip by updating the phase to 'finished'.
  Future<void> finishTrip(String tripId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Must be logged in.');

    final result = await _client
        .from('trips')
        .update({'phase': 'finished'})
        .match({'id': tripId})
        .select();

    if (result.isEmpty) {
      throw Exception(
        'Failed to lock trip. You may not be a leader or the database blocked it.',
      );
    }
  }

  /// Start the "Join Trip" flow.
  ///
  /// Queries the trips table to validate the invite_code and fetch default_join_role.
  /// Then inserts the new member with that specific role.
  ///
  /// Note: RLS must allow SELECT on trips (or at least invite_code/default_join_role)
  /// and INSERT on trip_members.
  Future<void> joinTrip(String inviteCode) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Must be logged in to join a trip.');

    // 1. Query trip by invite code to get ID and Default Role
    final tripData = await _client
        .from('trips')
        .select('id, default_join_role')
        .eq('invite_code', inviteCode)
        .maybeSingle();

    if (tripData == null) {
      throw Exception('Invalid invite code. Trip not found.');
    }

    final tripId = tripData['id'] as String;
    final defaultRole =
        tripData['default_join_role'] as String? ?? 'contributor';

    // 2. Check if already a member?
    // The duplicate key violation will handle this, but friendly check helps.
    // However, for speed/race-conditions, letting DB error is safer.

    try {
      // 3. Insert into trip_members
      await _client.from('trip_members').insert({
        'trip_id': tripId,
        'user_id': userId,
        'role': defaultRole,
        'exit_status': 'none',
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Unique violation
        throw Exception('You are already a member of this trip.');
      }
      rethrow;
    }
  }

  String _generateInviteCode() {
    // Make it static or instance method
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }
}
