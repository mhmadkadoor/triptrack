import 'package:collection/collection.dart';
import '../../trips/models/trip.dart';
import '../../ledger/models/settlement.dart';
import '../../roster/models/trip_member.dart';

class ShareUtils {
  static String generateSettlementSummary(
    Trip trip,
    List<Settlement> settlements,
    List<TripMember> members,
  ) {
    if (settlements.isEmpty) {
      if (trip.phase == TripPhase.finished) {
        return '✈️ TripTrack Summary: ${trip.name}\n------------------------------\nAll settled! No debts remaining. 🎉';
      }
      return '✈️ TripTrack Summary: ${trip.name}\nNo settlements calculated yet.';
    }

    final buffer = StringBuffer();
    buffer.writeln('✈️ TripTrack Summary: ${trip.name}');
    buffer.writeln('------------------------------');

    for (final settlement in settlements) {
      final fromMember = members.firstWhereOrNull(
        (m) => m.userId == settlement.fromUserId,
      );
      final toMember = members.firstWhereOrNull(
        (m) => m.userId == settlement.toUserId,
      );

      final fromName = fromMember?.profile?.displayName ?? 'User';
      final toName = toMember?.profile?.displayName ?? 'User';
      final amount = settlement.amount.toStringAsFixed(2);
      final currency = trip.baseCurrency;

      buffer.writeln('💰 $fromName owes $toName: $amount $currency');
    }

    buffer.writeln('------------------------------');
    buffer.writeln('All debts are calculated! Settle up soon. 🚀');

    return buffer.toString();
  }
}
