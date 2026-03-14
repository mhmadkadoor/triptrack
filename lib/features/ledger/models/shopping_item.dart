import 'package:equatable/equatable.dart';

class ShoppingItem extends Equatable {
  final String id;
  final String tripId;
  final String itemName;
  final String addedBy; // trip_members.added_by
  final String? claimedBy; // trip_members.claimed_by (nullable)
  final DateTime createdAt;

  const ShoppingItem({
    required this.id,
    required this.tripId,
    required this.itemName,
    required this.addedBy,
    this.claimedBy,
    required this.createdAt,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      itemName: json['item_name'] as String,
      addedBy: json['added_by'] as String,
      claimedBy: json['claimed_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'item_name': itemName,
      'added_by': addedBy,
      'claimed_by': claimedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ShoppingItem copyWith({
    String? id,
    String? tripId,
    String? itemName,
    String? addedBy,
    String? claimedBy,
    DateTime? createdAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      itemName: itemName ?? this.itemName,
      addedBy: addedBy ?? this.addedBy,
      claimedBy: claimedBy ?? this.claimedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    tripId,
    itemName,
    addedBy,
    claimedBy,
    createdAt,
  ];
}
