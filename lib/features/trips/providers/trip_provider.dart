import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/trip.dart';
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
