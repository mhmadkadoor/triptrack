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
  final List<String> participantUserIds;

  const Expense({
    required this.id,
    required this.tripId,
    required this.description,
    required this.amount,
    required this.currency,
    required this.paidBy,
    required this.createdAt,
    this.paidByProfile,
    this.participantUserIds = const [],
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    Profile? profile;
    if (json['profiles'] != null) {
      profile = Profile.fromJson(json['profiles']);
    }

    List<String> participants = [];
    if (json['participants'] != null) {
      // Assuming we join an array of participants or fetch them separately
      participants = (json['participants'] as List<dynamic>)
          .map((p) => p['user_id'] as String)
          .toList();
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
      participantUserIds: participants,
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
    participantUserIds,
  ];
}
