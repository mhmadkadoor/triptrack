import 'package:equatable/equatable.dart';

import '../../auth/models/profile.dart'; // Add profile import

class ExpenseParticipant extends Equatable {
  final String expenseId;
  final String userId;
  final double amountOwed; // If splits are unequal later
  final bool isPaid;

  const ExpenseParticipant({
    required this.expenseId,
    required this.userId,
    required this.amountOwed,
    required this.isPaid,
  });

  factory ExpenseParticipant.fromJson(Map<String, dynamic> json) {
    return ExpenseParticipant(
      expenseId: json['expense_id'] as String,
      userId: json['user_id'] as String,
      amountOwed: (json['amount_owed'] as num).toDouble(),
      isPaid: json['is_paid'] as bool,
    );
  }

  @override
  List<Object?> get props => [expenseId, userId, amountOwed, isPaid];
}

/*
Schema Assumption:
expense_participants table:
  - expense_id (REF expenses.id)
  - user_id (REF auth.users.id)
  - amount_owed (double)
  - is_paid (bool, defaults to false)
*/
