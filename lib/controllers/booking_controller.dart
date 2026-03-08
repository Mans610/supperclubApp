import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/api_service.dart';

class BookingController extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Booking> bookings = [];
  bool isLoading = false;

  Future<void> loadMyBookings(String role) async {
    isLoading = true;
    notifyListeners();

    try {
      final data = await _api.getMyBookings(role);
      bookings = data.map((b) => Booking.fromJson(b)).toList();

      // Sort by date (most recent first)
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('Error loading bookings: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> createBooking(int eventId, int seats) async {
    final success = await _api.createBooking(eventId, seats);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  Future<bool> approveBooking(int bookingId, String role) async {
    final success = await _api.approveBooking(bookingId);
    if (success) {
      await loadMyBookings(role);
    }
    return success;
  }

  Future<bool> cancelBooking(int bookingId, String role) async {
    final success = await _api.cancelBooking(bookingId);
    if (success) {
      await loadMyBookings(role);
    }
    return success;
  }

  List<Booking> get pendingBookings =>
      bookings.where((b) => b.isPending).toList();

  List<Booking> get approvedBookings =>
      bookings.where((b) => b.isApproved).toList();

  List<Booking> get cancelledBookings =>
      bookings.where((b) => b.isCancelled).toList();
}