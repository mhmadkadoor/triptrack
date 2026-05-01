import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/trip.dart';
import '../../roster/models/trip_member.dart';
import '../../ledger/models/expense.dart';
import '../../ledger/models/settlement.dart';
import '../../ledger/models/shopping_item.dart';
import '../../ledger/utils/settlement_utils.dart';

class TripRepository {
  final SupabaseClient _client;

  final _uuid = const Uuid();

  TripRepository(this._client);

  // --- Leave Trip ---
  Future<void> leaveTrip(String tripId, String userId) async {
    await _client
        .from('trip_members')
        .update({'has_left': true})
        .eq('trip_id', tripId)
        .eq('user_id', userId);
  }

  // --- Shopping List ---

  Stream<List<ShoppingItem>> watchShoppingItems(String tripId) {
    return _client
        .from('shopping_items')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .order('created_at', ascending: true)
        .map(
          (data) => data.map((json) => ShoppingItem.fromJson(json)).toList(),
        );
  }

  Future<void> addShoppingItem(String tripId, String itemName) async {
    await _client.from('shopping_items').insert({
      'trip_id': tripId,
      'item_name': itemName,
      'added_by': _client.auth.currentUser!.id,
    });
  }

  Future<void> deleteShoppingItem(String itemId) async {
    await _client.from('shopping_items').delete().eq('id', itemId);
  }

  Future<void> toggleClaimItem(
    String itemId,
    String? currentUserId,
    String? currentlyClaimedBy,
  ) async {
    if (currentUserId == null) return;

    if (currentlyClaimedBy == currentUserId) {
      // Unclaim
      await _client
          .from('shopping_items')
          .update({'claimed_by': null})
          .eq('id', itemId);
    } else if (currentlyClaimedBy == null) {
      // Claim
      await _client
          .from('shopping_items')
          .update({'claimed_by': currentUserId})
          .eq('id', itemId);
    }
  }

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
    String? linkedShoppingItemId,
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

    try {
      await _client.from('expenses').insert({
        'id': expenseId,
        'trip_id': tripId,
        'description': description,
        'amount': amount,
        'created_at': createdAt,
        'paid_by': userId,
        'currency': currency,
      });
    } on PostgrestException catch (e) {
      // 42501 is the code for insufficient_privilege (RLS violation)
      if (e.code == '42501' ||
          e.message.contains('row-level security') ||
          e.message.contains('policy')) {
        throw Exception(
          'Cannot add expense. The Leader has locked this trip for settlement.',
        );
      }
      rethrow;
    }

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

    // 4. Delete linked shopping item if provided
    if (linkedShoppingItemId != null) {
      await _client
          .from('shopping_items')
          .delete()
          .eq('id', linkedShoppingItemId);
    }
  }

  /// Records a settlement payment between two users.
  Future<void> settleDebt({
    required String tripId,
    required String fromUserId,
    required String toUserId,
    required double amount,
  }) async {
    // 1. Fetch trip currency
    final trip = await _client
        .from('trips')
        .select('base_currency')
        .eq('id', tripId)
        .single();
    final currency = trip['base_currency'] as String? ?? 'USD';

    // Generate expense ID locally
    final expenseId = _uuid.v4();
    final createdAt = DateTime.now().toUtc().toIso8601String();

    try {
      // Insert expense representing the payment
      await _client.from('expenses').insert({
        'id': expenseId,
        'trip_id': tripId,
        'description': 'Payment',
        'amount': amount,
        'currency': currency,
        'paid_by': fromUserId,
        'created_at': createdAt,
        'is_settlement': true,
      });

      // Insert participant (only the receiver)
      await _client.from('expense_participants').insert({
        'expense_id': expenseId,
        'user_id': toUserId,
        'amount_owed': amount,
        'is_paid': false,
      });
    } on PostgrestException catch (e) {
      if (e.code == '42501' ||
          e.message.contains('row-level security') ||
          e.message.contains('policy')) {
        throw Exception(
          'Cannot add payment. The Leader has locked this trip for settlement.',
        );
      }
      rethrow;
    }
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

    // Bug 2 Fix: Prevent downgrading the last leader
    if (newRole != TripRole.leader) {
      final leaders = await _client.from('trip_members').select().match({
        'trip_id': tripId,
        'role': 'leader',
      });

      // If there is only 1 leader, and that leader is the one being modified
      if (leaders.length == 1 &&
          (leaders.first['user_id'] as String) == memberId) {
        throw Exception(
          'Cannot downgrade the last leader. Promote someone else to Leader first.',
        );
      }
    }

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

  /// Finds all trips where the user is the ONLY leader.
  /// These trips are at risk of being deleted if the user deletes their account.
  Future<List<Trip>> getSoleLeaderTrips(String userId) async {
    // 1. Get all trips where user is a leader
    // We use .select() instead of .get() or other supabase v1 methods
    final myLeaderTrips = await _client
        .from('trip_members')
        .select('trip_id')
        .eq('user_id', userId)
        .eq('role', 'leader');

    if (myLeaderTrips.isEmpty) return [];

    // Cast the list safely
    final tripIds = (myLeaderTrips as List)
        .map((t) => t['trip_id'] as String)
        .toList();

    // 2. For these trips, find if there are OTHER leaders
    final otherLeaders = await _client
        .from('trip_members')
        .select('trip_id')
        .inFilter('trip_id', tripIds)
        .eq('role', 'leader')
        .neq('user_id', userId);

    final tripsWithOtherLeaders = (otherLeaders as List)
        .map((t) => t['trip_id'] as String)
        .toSet();

    // 3. Filter down to only trips where user is the ONLY leader
    final soleLeaderTripIds = tripIds
        .where((id) => !tripsWithOtherLeaders.contains(id))
        .toList();

    if (soleLeaderTripIds.isEmpty) return [];

    // 4. Fetch full trip details for display
    final tripsData = await _client
        .from('trips')
        .select()
        .inFilter('id', soleLeaderTripIds);

    return (tripsData as List).map((json) => Trip.fromJson(json)).toList();
  }

  /// Streams the list of trips the user is a member of.
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
              .where((m) => m['has_left'] != true) // Exclude left trips
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

  /// Finishes the trip by calculating settlements and updating the phase to 'finished' and locking it.
  Future<void> finishTrip(String tripId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Must be logged in.');

    // 1. Fetch Expenses & Participants to Calculate Balances
    final expensesData = await _client
        .from('expenses')
        .select('id, amount, paid_by')
        .eq('trip_id', tripId);

    if (expensesData.isEmpty) {
      // Just lock it if no expenses
      await _client
          .from('trips')
          .update({'phase': 'finished', 'is_locked': true})
          .match({'id': tripId});
      return;
    }

    final expenseIds = expensesData.map((e) => e['id'] as String).toList();
    final participantsData = await _client
        .from('expense_participants')
        .select('expense_id, user_id')
        .inFilter('expense_id', expenseIds);

    // Group participants by expense
    final participantsMap = <String, List<String>>{};
    for (final p in participantsData) {
      final eId = p['expense_id'] as String;
      final uId = p['user_id'] as String;
      if (!participantsMap.containsKey(eId)) {
        participantsMap[eId] = [];
      }
      participantsMap[eId]!.add(uId);
    }

    // Calculate Balances
    final balances = <String, double>{};
    for (final expense in expensesData) {
      final eId = expense['id'] as String;
      final payerId = expense['paid_by'] as String;
      final amount = (expense['amount'] as num).toDouble();

      // Credit payer
      balances[payerId] = (balances[payerId] ?? 0.0) + amount;

      // Debit participants
      final participants = participantsMap[eId] ?? [];
      if (participants.isNotEmpty) {
        final splitAmount = amount / participants.length;
        for (final pId in participants) {
          balances[pId] = (balances[pId] ?? 0.0) - splitAmount;
        }
      }
    }

    // 2. Calculate Settlements
    final settlements = calculateSettlements(balances, tripId);

    // 3. Insert Settlements
    if (settlements.isNotEmpty) {
      final settlementsJson = settlements.map((s) => s.toJson()).toList();
      await _client.from('settlements').insert(settlementsJson);
    }

    // 4. Update Trip Phase & Lock
    final result = await _client
        .from('trips')
        .update({'phase': 'finished', 'is_locked': true})
        .match({'id': tripId})
        .select();

    if (result.isEmpty) {
      throw Exception(
        'Failed to lock trip. You may not be a leader or the database blocked it.',
      );
    }
  }

  /// Updates a settlement status to 'sent'.
  Future<void> markSettlementSent(String settlementId) async {
    await _client
        .from('settlements')
        .update({'status': SettlementStatus.sent.name})
        .match({'id': settlementId});
  }

  /// Updates a settlement status to 'confirmed'.
  Future<void> confirmSettlementReceived(String settlementId) async {
    await _client
        .from('settlements')
        .update({'status': SettlementStatus.confirmed.name})
        .match({'id': settlementId});
  }

  /// Streams settlements for a trip.
  Stream<List<Settlement>> watchSettlements(String tripId) {
    return _client
        .from('settlements')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .order('created_at')
        .map((data) => data.map((json) => Settlement.fromJson(json)).toList());
  }

  /// Start the "Join Trip" flow.
  Future<void> joinTrip(String inviteCode) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Must be logged in to join a trip.');

    // 1. Sanitize the invite code
    final sanitizedCode = inviteCode.trim().toUpperCase();

    // 2. Query trip by invite code to get ID and Default Role
    final tripData = await _client
        .from('trips')
        .select('id, default_join_role, is_locked')
        .eq('invite_code', sanitizedCode)
        .maybeSingle();

    if (tripData == null) {
      throw Exception('Invalid invite code. Trip not found.');
    }

    if (tripData['is_locked'] == true) {
      throw Exception(
        'This trip is locked by the leader and is not accepting new members.',
      );
    }

    final tripId = tripData['id'] as String;
    final defaultRole =
        tripData['default_join_role'] as String? ?? 'contributor';

    try {
      // 3. Insert into trip_members
      await _client.from('trip_members').insert({
        'trip_id': tripId,
        'user_id': userId,
        'role': defaultRole,
        'exit_status': 'none',
      });

      // 4. Retroactive Expense Sharing
      // Fetch all existing expenses for this trip
      final expenses = await _client
          .from('expenses')
          .select('id, amount, paid_by')
          .eq('trip_id', tripId);

      if (expenses.isNotEmpty) {
        final newParticipantsData = expenses.map((e) {
          return {
            'expense_id': e['id'],
            'user_id': userId,
            'amount_owed': 0, // Recalculated by provider
            'is_paid': false,
          };
        }).toList();

        await _client.from('expense_participants').insert(newParticipantsData);
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Unique violation
        throw Exception('You are already a member of this trip.');
      }
      rethrow;
    }
  }

  /// Settles the trip by updating the phase to 'settled'.
  Future<void> settleTrip(String tripId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Must be logged in.');

    final result = await _client
        .from('trips')
        .update({'phase': 'settled'})
        .match({'id': tripId})
        .select();

    if (result.isEmpty) {
      throw Exception(
        'Failed to settle trip. You may not be a leader or the database blocked it.',
      );
    }
  }

  /// Toggles whether members can exclude themselves from expenses.
  Future<void> toggleSelfExclusion(String tripId, bool value) async {
    await _client.from('trips').update({'allow_self_exclusion': value}).match({
      'id': tripId,
    });
  }

  /// Toggles the lock status of the trip (preventing new members).
  Future<void> toggleTripLock(String tripId, bool isLocked) async {
    await _client.from('trips').update({'is_locked': isLocked}).match({
      'id': tripId,
    });
  }

  /// Updates the participants for an expense using a Diff approach.
  Future<void> updateExpenseParticipants(
    String expenseId,
    List<String> newParticipantIds,
    List<String> oldParticipantIds,
  ) async {
    final toAdd = newParticipantIds
        .where((id) => !oldParticipantIds.contains(id))
        .toList();
    final toRemove = oldParticipantIds
        .where((id) => !newParticipantIds.contains(id))
        .toList();

    // 1. Remove users who are no longer participants
    if (toRemove.isNotEmpty) {
      await _client
          .from('expense_participants')
          .delete()
          .match({'expense_id': expenseId})
          .inFilter('user_id', toRemove)
          .select();
    }

    // 2. Add new participants
    if (toAdd.isNotEmpty) {
      final participantsData = toAdd.map((uid) {
        return {
          'expense_id': expenseId,
          'user_id': uid,
          'amount_owed': 0, // Recalculated by provider logic
          'is_paid': false,
        };
      }).toList();

      await _client.from('expense_participants').insert(participantsData);
    }
  }

  /// Removes a member from the trip, cleaning up all their data.
  Future<void> removeMember(String tripId, String userId) async {
    // 0. Safety Check: Last Leader
    final member = await _client.from('trip_members').select().match({
      'trip_id': tripId,
      'user_id': userId,
    }).single();

    final role = member['role'] as String;

    if (role == 'leader') {
      final leaders = await _client.from('trip_members').select().match({
        'trip_id': tripId,
        'role': 'leader',
      });

      if (leaders.length == 1) {
        throw Exception(
          'Cannot remove the last leader. Promote someone else first.',
        );
      }
    }

    try {
      // 1. Cleanup Splits (expense_participants)
      await _client
          .from('expense_participants')
          .delete()
          .match({'user_id': userId})
          .inFilter(
            'expense_id',
            (await _client.from('expenses').select('id').eq('trip_id', tripId))
                .map((e) => e['id'])
                .toList(),
          );

      // 2. Cleanup Expenses Paid (expenses)
      await _client.from('expenses').delete().match({
        'trip_id': tripId,
        'paid_by': userId,
      });

      // 3. Remove Member (trip_members)
      final result = await _client.from('trip_members').delete().match({
        'trip_id': tripId,
        'user_id': userId,
      }).select();

      if (result.isEmpty) {
        throw Exception(
          'Failed to remove member. The database blocked the action.',
        );
      }
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Database Error: ${e.message}');
      }
      rethrow;
    }
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }
}
