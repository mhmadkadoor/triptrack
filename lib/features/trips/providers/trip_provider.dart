import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'trip_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/trip.dart';
import '../../roster/models/trip_member.dart';
import '../../ledger/models/expense.dart';
import '../../ledger/models/shopping_item.dart';
import '../../ledger/models/settlement.dart';
import '../../ledger/providers/balances_provider.dart';

part 'trip_provider.g.dart';

@riverpod
TripRepository tripRepository(Ref ref) {
  return TripRepository(Supabase.instance.client);
}

@riverpod
Stream<List<ShoppingItem>> shoppingItems(Ref ref, String tripId) {
  return ref.watch(tripRepositoryProvider).watchShoppingItems(tripId);
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
Future<void> leaveTrip(Ref ref, String tripId) async {
  final userId = ref.read(authRepositoryProvider).currentUser?.id;
  if (userId != null) {
    await ref.read(tripRepositoryProvider).leaveTrip(tripId, userId);
    ref.invalidate(userTripsProvider);
  }
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
  ref.invalidate(expensesProvider(tripId));
  ref.invalidate(netBalancesProvider(tripId));
}

@riverpod
Future<void> updateExpenseAction(
  Ref ref,
  String tripId,
  Expense expense,
) async {
  await ref.read(tripRepositoryProvider).updateExpense(expense);
  ref.invalidate(expensesProvider(tripId));
  ref.invalidate(netBalancesProvider(tripId));
}

@riverpod
Future<void> deleteExpenseAction(
  Ref ref,
  String tripId,
  String expenseId,
) async {
  await ref.read(tripRepositoryProvider).deleteExpense(expenseId);
  ref.invalidate(expensesProvider(tripId));
  ref.invalidate(netBalancesProvider(tripId));
}

@riverpod
Future<void> toggleExpenseLockAction(
  Ref ref,
  String tripId,
  bool isLocked,
) async {
  await ref.read(tripRepositoryProvider).toggleExpenseLock(tripId, isLocked);
  ref.invalidate(tripProvider(tripId));
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
