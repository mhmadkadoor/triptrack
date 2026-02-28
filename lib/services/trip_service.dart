import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip.dart';

class TripService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'trips';

  // Get all trips
  Future<List<Trip>> getTrips() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Trip.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load trips: $e');
    }
  }

  // Get a single trip
  Future<Trip?> getTrip(String id) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', id)
          .single();

      return Trip.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load trip: $e');
    }
  }

  // Create a new trip
  Future<Trip> createTrip(Trip trip) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .insert(trip.toJson())
          .select()
          .single();

      return Trip.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create trip: $e');
    }
  }

  // Update an existing trip
  Future<Trip> updateTrip(Trip trip) async {
    if (trip.id == null) {
      throw Exception('Trip ID is required for update');
    }

    try {
      final response = await _supabase
          .from(_tableName)
          .update(trip.toJson())
          .eq('id', trip.id!)
          .select()
          .single();

      return Trip.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update trip: $e');
    }
  }

  // Delete a trip
  Future<void> deleteTrip(String id) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete trip: $e');
    }
  }

  // Listen to real-time changes
  Stream<List<Trip>> watchTrips() {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Trip.fromJson(json)).toList());
  }
}
