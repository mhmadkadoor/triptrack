import 'package:flutter/foundation.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';

class TripProvider extends ChangeNotifier {
  final TripService _tripService = TripService();
  List<Trip> _trips = [];
  bool _isLoading = false;
  String? _error;

  List<Trip> get trips => _trips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all trips
  Future<void> loadTrips() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _trips = await _tripService.getTrips();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new trip
  Future<void> createTrip(Trip trip) async {
    try {
      final newTrip = await _tripService.createTrip(trip);
      _trips.insert(0, newTrip);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update a trip
  Future<void> updateTrip(Trip trip) async {
    try {
      final updatedTrip = await _tripService.updateTrip(trip);
      final index = _trips.indexWhere((t) => t.id == updatedTrip.id);
      if (index != -1) {
        _trips[index] = updatedTrip;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Delete a trip
  Future<void> deleteTrip(String id) async {
    try {
      await _tripService.deleteTrip(id);
      _trips.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
