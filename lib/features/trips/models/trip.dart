import 'package:equatable/equatable.dart';

import '../../roster/models/trip_member.dart';

enum TripPhase {
  active,
  finished,
  settled;

  static TripPhase fromString(String value) {
    return TripPhase.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TripPhase.active,
    );
  }
}

class Trip extends Equatable {
  final String id;
  final String name;
  final String baseCurrency;
  final TripPhase phase;
  final bool isLocked;
  final String? inviteCode;
  final TripRole defaultJoinRole;
  final String createdBy;
  final DateTime createdAt;
  final bool allowSelfExclusion;

  const Trip({
    required this.id,
    required this.name,
    required this.baseCurrency,
    required this.phase,
    required this.isLocked,
    this.inviteCode,
    this.defaultJoinRole = TripRole.contributor,
    required this.createdBy,
    required this.createdAt,
    this.allowSelfExclusion = true,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      name: json['name'] as String,
      baseCurrency: json['base_currency'] as String,
      phase: TripPhase.fromString(json['phase'] as String),
      isLocked: json['is_locked'] as bool,
      inviteCode: json['invite_code'] as String?,
      defaultJoinRole: TripRole.fromString(
        json['default_join_role'] as String? ?? 'contributor',
      ),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      allowSelfExclusion: json['allow_self_exclusion'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    baseCurrency,
    phase,
    isLocked,
    inviteCode,
    defaultJoinRole,
    createdBy,
    createdAt,
  ];
}
