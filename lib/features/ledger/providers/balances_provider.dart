import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../trips/providers/trip_provider.dart';
import '../models/settlement.dart';

part 'balances_provider.g.dart';

@riverpod
Stream<List<Settlement>> savedSettlements(Ref ref, String tripId) {
  return ref.read(tripRepositoryProvider).watchSettlements(tripId);
}

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

List<Settlement> calculateSettlements(
  Map<String, double> balances,
  String tripId,
) {
  // 1. Separate creditors and debtors
  // Use a min-heap or just a simple list that we sort
  final creditors = <_MemberBalance>[];
  final debtors = <_MemberBalance>[];

  balances.forEach((userId, amount) {
    if (amount > 0.005) {
      creditors.add(_MemberBalance(userId, amount));
    } else if (amount < -0.005) {
      debtors.add(_MemberBalance(userId, amount));
    }
  });

  // 2. Sort both lists by amount magnitude (largest first)
  // Greedy approach: Match biggest debtor to biggest creditor
  creditors.sort((a, b) => b.amount.compareTo(a.amount));
  debtors.sort(
    (a, b) => a.amount.compareTo(b.amount),
  ); // Ascending (most negative first)

  final settlements = <Settlement>[];

  int i = 0; // creditor index
  int j = 0; // debtor index

  while (i < creditors.length && j < debtors.length) {
    final creditor = creditors[i];
    final debtor = debtors[j];

    // debt is negative, so we use abs() or just negate
    final debtAmount = -debtor.amount;
    final creditAmount = creditor.amount;

    final settledAmount = (debtAmount < creditAmount)
        ? debtAmount
        : creditAmount;

    settlements.add(
      Settlement(
        tripId: tripId,
        fromUserId: debtor.userId,
        toUserId: creditor.userId,
        amount: settledAmount,
      ),
    );

    // Update remaining amounts
    creditor.amount -= settledAmount;
    debtor.amount += settledAmount;

    // If fully settled, move to next
    if (creditor.amount < 0.005) i++;
    if (debtor.amount > -0.005) j++;
  }

  return settlements;
}

class _MemberBalance {
  final String userId;
  double amount;
  _MemberBalance(this.userId, this.amount);
}
