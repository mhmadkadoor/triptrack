import 'package:equatable/equatable.dart';

enum TripRole {
  leader,
  contributor,
  hiker;

  static TripRole fromString(String value) {
    return TripRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TripRole.hiker,
    );
  }
}

enum ExitStatus {
  none,
  pending,
  approved;

  static ExitStatus fromString(String value) {
    return ExitStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExitStatus.none,
    );
  }
}

class TripMember extends Equatable {
  final String tripId;
  final String userId;
  final TripRole role;
  final ExitStatus exitStatus;
  final DateTime joinedAt;

  const TripMember({
    required this.tripId,
    required this.userId,
    required this.role,
    required this.exitStatus,
    required this.joinedAt,
  });

  factory TripMember.fromJson(Map<String, dynamic> json) {
    return TripMember(
      tripId: json['trip_id'] as String,
      userId: json['user_id'] as String,
      role: TripRole.fromString(json['role'] as String),
      exitStatus: ExitStatus.fromString(json['exit_status'] as String),
      joinedAt: DateTime.parse(json['joined_at'] as String).toLocal(),
    );
  }

  @override
  List<Object?> get props => [tripId, userId, role, exitStatus, joinedAt];
}
