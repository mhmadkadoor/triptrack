import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/trip.dart';
import '../../roster/models/trip_member.dart';
import 'trip_repository.dart';

part 'trip_provider.g.dart';

@riverpod
TripRepository tripRepository(Ref ref) {
  return TripRepository(Supabase.instance.client);
}

@riverpod
Stream<List<Trip>> userTrips(Ref ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.watchUserTrips();
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
