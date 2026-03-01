enum SettlementStatus {
  pending,
  sent,
  confirmed;

  static SettlementStatus fromString(String value) {
    return SettlementStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SettlementStatus.pending,
    );
  }
}

class Settlement {
  final String? id;
  final String tripId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final SettlementStatus status;

  const Settlement({
    this.id,
    required this.tripId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    this.status = SettlementStatus.pending,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'trip_id': tripId,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'amount': amount,
      'status': status.name,
    };
  }

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      id: json['id'] as String?,
      tripId: json['trip_id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: SettlementStatus.fromString(json['status'] as String),
    );
  }

  @override
  String toString() =>
      'Settlement(from: $fromUserId, to: $toUserId, amount: ${amount.toStringAsFixed(2)}, status: $status)';
}
