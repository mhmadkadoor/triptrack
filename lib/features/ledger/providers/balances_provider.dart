import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../trips/providers/trip_provider.dart';

part 'balances_provider.g.dart';

@riverpod
Map<String, double> netBalances(Ref ref, String tripId) {
  final membersAsync = ref.watch(tripMembersProvider(tripId));
  final expensesAsync = ref.watch(expensesProvider(tripId));

  // If either stream is loading or has error, return empty map or handle gracefully
  // Here we just return empty map until data is ready
  if (!membersAsync.hasValue || !expensesAsync.hasValue) {
    return {};
  }

  final members = membersAsync.value!;
  final expenses = expensesAsync.value!;

  // Initialize balances for all members
  final balances = <String, double>{};
  for (final member in members) {
    balances[member.userId] = 0.0;
  }

  // Calculate balances
  for (final expense in expenses) {
    // Credit the payer
    final payerId = expense.paidBy;
    // Ensure payer is in the map (might have left trip, but expense remains)
    if (!balances.containsKey(payerId)) {
      balances[payerId] = 0.0;
    }
    balances[payerId] = (balances[payerId] ?? 0.0) + expense.amount;

    // Debit the participants
    final participants = expense.participantUserIds;
    if (participants.isNotEmpty) {
      final splitAmount = expense.amount / participants.length;
      for (final participantId in participants) {
        if (!balances.containsKey(participantId)) {
          balances[participantId] = 0.0;
        }
        balances[participantId] =
            (balances[participantId] ?? 0.0) - splitAmount;
      }
    }
  }

  return balances;
}
