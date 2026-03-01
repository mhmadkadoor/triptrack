import 'package:equatable/equatable.dart';

import '../../auth/models/profile.dart';

class Expense extends Equatable {
  final String id;
  final String tripId;
  final String description;
  final double amount;
  final String currency;
  final String paidBy;
  final DateTime createdAt;
  final Profile? paidByProfile;
  // We might want to include the list of participants here if needed for UI details
  // final List<String> participantIds;

  const Expense({
    required this.id,
    required this.tripId,
    required this.description,
    required this.amount,
    required this.currency,
    required this.paidBy,
    required this.createdAt,
    this.paidByProfile,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    Profile? profile;
    if (json['profiles'] != null) {
      profile = Profile.fromJson(json['profiles']);
    }

    return Expense(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      paidBy: json['paid_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      paidByProfile: profile,
    );
  }

  @override
  List<Object?> get props => [
    id,
    tripId,
    description,
    amount,
    currency,
    paidBy,
    createdAt,
    paidByProfile,
  ];
}
