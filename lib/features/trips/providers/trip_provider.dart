import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/trip.dart';
import '../../roster/models/trip_member.dart';
import '../../ledger/models/expense.dart';
import 'trip_repository.dart';

part 'trip_provider.g.dart';

@riverpod
TripRepository tripRepository(Ref ref) {
  return TripRepository(Supabase.instance.client);
}

@riverpod
Stream<List<Trip>> userTrips(Ref ref) {
  final userId = ref.watch(authRepositoryProvider).currentUser?.id;
  if (userId == null) return const Stream.empty();

  // We recreate the stream when repo changes (unlikely) or user changes.
  // The repository method itself returns a stream that listens to trip_members
  // which works in real-time.
  return ref.watch(tripRepositoryProvider).watchUserTrips();
}

@riverpod
Future<void> joinTrip(Ref ref, String inviteCode) async {
  // This provider triggers the repo call and invalidates the cache
  await ref.read(tripRepositoryProvider).joinTrip(inviteCode);
  // Invalidate just in case real-time fails or is delayed
  ref.invalidate(userTripsProvider);
}

@riverpod
Future<void> createExpense(
  Ref ref, {
  required String tripId,
  required String description,
  required double amount,
  required List<String> participantUserIds,
}) async {
  await ref
      .read(tripRepositoryProvider)
      .createExpense(
        tripId: tripId,
        description: description,
        amount: amount,
        participantUserIds: participantUserIds,
      );
  // Force refresh expenses list
  // Note: expenses are usually streamed per-trip, so we'd need to invalidate THAT provider.
  // But expenses are usually watched via `watchExpenses(tripId)`.
  // Since `watchExpenses` is usually a `StreamProvider.family` or direct stream,
  // we can't easily invalidate it without the exact arguments.
  // However, `watchExpenses` uses `.stream()` on `expenses` table,
  // so it SHOULD receive the insert event automatically.
}

@riverpod
Stream<Trip> trip(Ref ref, String id) {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.watchTrip(id);
}

@riverpod
Stream<List<TripMember>> tripMembers(Ref ref, String tripId) {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.watchTripMembers(tripId);
}

@riverpod
Stream<List<Expense>> expenses(Ref ref, String tripId) {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.watchExpenses(tripId);
}
