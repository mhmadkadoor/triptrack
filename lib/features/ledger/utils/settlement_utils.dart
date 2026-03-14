// ignore_for_file: depend_on_referenced_packages

import '../models/settlement.dart';

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
